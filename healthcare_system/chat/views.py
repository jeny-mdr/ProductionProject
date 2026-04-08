from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Room, Message


class MyRoomsView(APIView):
    """Returns all chat rooms for the logged-in user."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == 'patient':
            rooms = Room.objects.filter(patient=user).select_related('doctor')
        else:
            rooms = Room.objects.filter(doctor=user).select_related('patient')

        result = []
        for room in rooms:
            other = room.doctor if user.role == 'patient' else room.patient
            last_msg = room.messages.order_by('-timestamp').first()
            unread = room.messages.filter(is_read=False).exclude(sender=user).count()
            result.append({
                "room_id": room.id,
                "other_user_id": other.id,
                "other_username": other.username,
                "last_message": last_msg.content if last_msg else None,
                "last_message_time": last_msg.timestamp.isoformat() if last_msg else None,
                "unread_count": unread,
            })

        return Response(result)


class MarkReadView(APIView):
    """Mark all messages in a room as read."""
    permission_classes = [IsAuthenticated]

    def post(self, request, room_id):
        Message.objects.filter(
            room_id=room_id,
            is_read=False
        ).exclude(sender=request.user).update(is_read=True)
        return Response({"status": "marked as read"})