import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import AccessToken
from .models import Room, Message

User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):

    async def connect(self):

        self.other_user_id = self.scope['url_route']['kwargs']['user_id']

        # Authenticate via JWT token in query string
        token = self.scope['query_string'].decode().split('token=')[-1]
        self.user = await self.get_user_from_token(token)

        if not self.user:
            await self.close()
            return

        # Get or create the room
        self.room = await self.get_or_create_room(self.user.id, int(self.other_user_id))

        if not self.room:
            await self.close()
            return

        self.room_group_name = f'chat_{self.room.id}'

        # Join the channel group
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

        # Send last 50 messages as chat history on connect
        history = await self.get_message_history()
        await self.send(text_data=json.dumps({
            "type": "history",
            "messages": history
        }))
        # Mark all messages from other user as read
        await self.mark_messages_read()

    async def disconnect(self, close_code):
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        content = data.get('message', '').strip()

        if not content:
            return

        # Save to DB
        message = await self.save_message(content)

        # Broadcast to both users in the room
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "message": content,
                "sender": self.user.username,
                "sender_id": self.user.id,
                "timestamp": message.timestamp.isoformat(),
                "message_id": message.id,
            }
        )

    async def chat_message(self, event):
        """Receive message from channel group and forward to WebSocket."""
        await self.send(text_data=json.dumps({
            "type": "message",
            "message": event["message"],
            "sender": event["sender"],
            "sender_id": event["sender_id"],
            "timestamp": event["timestamp"],
            "message_id": event["message_id"],
        }))

    # ── DB helpers (run sync code safely in async context) ──────────────

    @database_sync_to_async
    def get_user_from_token(self, token_str):
        try:
            token = AccessToken(token_str)
            return User.objects.get(id=token['user_id'])
        except Exception:
            return None

    @database_sync_to_async
    def get_or_create_room(self, user_id, other_id):
        try:
            user = User.objects.get(id=user_id)
            other = User.objects.get(id=other_id)

            # Ensure one is patient and other is doctor
            roles = {user.role, other.role}
            if roles != {'patient', 'doctor'}:
                return None

            patient = user if user.role == 'patient' else other
            doctor = user if user.role == 'doctor' else other

            room, _ = Room.objects.get_or_create(patient=patient, doctor=doctor)
            return room
        except User.DoesNotExist:
            return None

    @database_sync_to_async
    def save_message(self, content):
        return Message.objects.create(
            room=self.room,
            sender=self.user,
            content=content,
        )

    @database_sync_to_async
    def mark_messages_read(self):
        Message.objects.filter(
            room=self.room,
            is_read=False,
        ).exclude(
            sender=self.user
        ).update(is_read=True)

    @database_sync_to_async
    def get_message_history(self):
        messages = Message.objects.filter(
            room=self.room).order_by('-timestamp')[:50]
        result = []
        for m in reversed(list(messages)):
            msg_data = {
                "message_id": m.id,
                "sender": m.sender.username,
                "sender_id": m.sender.id,
                "message": m.content,
                "timestamp": m.timestamp.isoformat(),
                "is_read": m.is_read,
                "message_type": m.message_type,
                "file_name": m.file_name or '',
                "file_url": f"http://172.22.18.73:8000{m.file.url}" if m.file else None,
                #"file_url": f"http://192.168.101.12:8000{m.file.url}" if m.file else None,
            }
            result.append(msg_data)
        return result