from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import get_user_model
from .models import Room, Message

User = get_user_model()


class MyRoomsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == 'patient':
            rooms = Room.objects.filter(
                patient=user).select_related('doctor')
        else:
            rooms = Room.objects.filter(
                doctor=user).select_related('patient')

        result = []
        for room in rooms:
            other    = room.doctor if user.role == 'patient' else room.patient
            last_msg = room.messages.order_by('-timestamp').first()
            unread   = room.messages.filter(
                is_read=False).exclude(sender=user).count()

            # Get other user's profile picture
            other_pic = None
            try:
                if other.role == 'doctor' and hasattr(other, 'doctor'):
                    if other.doctor.profile_picture:
                        other_pic = request.build_absolute_uri(
                            other.doctor.profile_picture.url)
                elif other.role == 'patient' and hasattr(other, 'patient'):
                    if other.patient.profile_picture:
                        other_pic = request.build_absolute_uri(
                            other.patient.profile_picture.url)
            except Exception:
                other_pic = None

            result.append({
                "room_id":           room.id,
                "other_user_id":     other.id,
                "other_username":    other.username,
                "last_message":      last_msg.content if last_msg else None,
                "last_message_time": last_msg.timestamp.isoformat() if last_msg else None,
                "unread_count":      unread,
                "other_pic_url":     other_pic,
                "is_doctor": other.role == 'doctor',
            })
        return Response(result)


class MarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, room_id):
        Message.objects.filter(
            room_id=room_id,
            is_read=False
        ).exclude(
            sender=request.user
        ).update(is_read=True)
        return Response({"status": "marked as read"})


class UploadFileView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes     = [MultiPartParser, FormParser]

    def post(self, request):
        other_user_id = request.data.get(
            'other_user_id')
        file          = request.FILES.get('file')

        if not file:
            return Response(
                {"error": "No file provided"},
                status=400)

        if not other_user_id:
            return Response(
                {"error": "other_user_id required"},
                status=400)

        try:
            other = User.objects.get(
                id=other_user_id)
            user  = request.user

            roles = {user.role, other.role}
            if roles != {'patient', 'doctor'}:
                return Response(
                    {"error": "Invalid users"},
                    status=400)

            patient = user  if user.role == 'patient' else other
            doctor  = user  if user.role == 'doctor'  else other

            room, _ = Room.objects.get_or_create(
                patient=patient, doctor=doctor)

            # Determine message type
            fname = file.name.lower()
            if any(fname.endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp']):
                msg_type = 'image'
            else:
                msg_type = 'file'

            message = Message.objects.create(
                room         = room,
                sender       = user,
                content      = file.name,
                file         = file,
                file_name    = file.name,
                message_type = msg_type,
            )

            file_url = request.build_absolute_uri(
                message.file.url)

            return Response({
                "message_id":   message.id,
                "file_url":     file_url,
                "file_name":    file.name,
                "message_type": msg_type,
                "timestamp":    message.timestamp.isoformat(),
                "sender":       user.username,
            }, status=201)

        except User.DoesNotExist:
            return Response(
                {"error": "User not found"},
                status=404)
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=400)