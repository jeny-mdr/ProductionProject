from django.db import models
from django.conf import settings


class Room(models.Model):
    patient    = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='patient_rooms'
    )
    doctor     = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='doctor_rooms'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('patient', 'doctor')

    def __str__(self):
        return f"Room: {self.patient.username} ↔ {self.doctor.username}"

    @property
    def room_name(self):
        ids = sorted([self.patient.id, self.doctor.id])
        return f"chat_{ids[0]}_{ids[1]}"


class Message(models.Model):
    MESSAGE_TYPES = (
        ('text',  'Text'),
        ('file',  'File'),
        ('image', 'Image'),
    )
    room         = models.ForeignKey(
        Room, on_delete=models.CASCADE,
        related_name='messages')
    sender       = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_messages')
    content      = models.TextField(blank=True)
    file         = models.FileField(
        upload_to='chat_files/',
        null=True, blank=True)
    file_name    = models.CharField(
        max_length=255, blank=True)
    message_type = models.CharField(
        max_length=10,
        choices=MESSAGE_TYPES,
        default='text')
    timestamp    = models.DateTimeField(auto_now_add=True)
    is_read      = models.BooleanField(default=False)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"{self.sender.username}: {self.content[:40]}"