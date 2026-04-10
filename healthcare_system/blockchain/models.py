import hashlib
import json
from django.db import models
from django.conf import settings
from django.utils import timezone


class BlockchainRecord(models.Model):
    RECORD_TYPES = (
        ('prescription', 'Prescription'),
        ('doctor_verification', 'Doctor Verification'),
    )

    record_type = models.CharField(max_length=30, choices=RECORD_TYPES)
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='patient_records',
        null=True, blank=True
    )
    doctor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='doctor_records'
    )
    data = models.TextField()
    data_hash = models.CharField(max_length=64)
    previous_hash = models.CharField(max_length=64)
    block_hash = models.CharField(max_length=64)
    created_at = models.DateTimeField(default=timezone.now)  # ← changed

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"[{self.record_type}] {self.doctor} → {self.patient} | {self.created_at.date()}"

    @staticmethod
    def compute_hash(data_hash, previous_hash, timestamp_str):
        content = f"{data_hash}{previous_hash}{timestamp_str}"
        return hashlib.sha256(content.encode()).hexdigest()

    @staticmethod
    def get_last_hash():
        last = BlockchainRecord.objects.last()
        if last:
            return last.block_hash
        return '0' * 64

    def save(self, *args, **kwargs):
        # Set timestamp first if not set
        if not self.created_at:
            self.created_at = timezone.now()

        # Hash the raw data
        self.data_hash = hashlib.sha256(
            self.data.encode()).hexdigest()

        # Get previous block hash
        self.previous_hash = BlockchainRecord.get_last_hash()

        # Compute this block's hash using real timestamp
        self.block_hash = BlockchainRecord.compute_hash(
            self.data_hash,
            self.previous_hash,
            self.created_at.isoformat()
        )
        super().save(*args, **kwargs)