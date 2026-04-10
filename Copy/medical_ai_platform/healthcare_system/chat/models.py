from django.db import models
from django.conf import settings


class Room(models.Model):
    """
    One Room per patient-doctor pair.
    Created automatically when a patient first messages a doctor.
    """
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='patient_rooms'
    )
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='doctor_rooms'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('patient', 'doctor')   # one room per pair

    def __str__(self):
        return f"Room: {self.patient.username} ↔ {self.doctor.username}"

    @property
    def room_name(self):
        # Stable channel group name regardless of who opened it
        ids = sorted([self.patient.id, self.doctor.id])
        return f"chat_{ids[0]}_{ids[1]}"


class Message(models.Model):
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_messages'
    )
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"{self.sender.username}: {self.content[:40]}"