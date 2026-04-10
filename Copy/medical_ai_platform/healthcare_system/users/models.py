from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings


class User(AbstractUser):
    ROLE_CHOICES = (
        ('patient', 'Patient'),
        ('doctor', 'Doctor'),
        ('admin', 'Admin'),
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES)

    def __str__(self):
        return f"{self.username} ({self.role})"


class Patient(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    age = models.IntegerField(null=True, blank=True)
    medical_history = models.TextField(blank=True)

    def __str__(self):
        return self.user.username


class Doctor(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    specialization = models.CharField(max_length=200)
    hospital = models.CharField(max_length=200)
    consultation_fee = models.IntegerField()
    is_verified = models.BooleanField(default=False)   # admin must approve
    bio = models.TextField(blank=True)
    profile_picture = models.ImageField(upload_to='doctors/', null=True, blank=True)

    def __str__(self):
        return f"Dr. {self.user.username} — {self.specialization}"