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
    GENDER_CHOICES = (
        ('male',   'Male'),
        ('female', 'Female'),
        ('other',  'Other'),
    )
    user            = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE)
    age             = models.IntegerField(null=True, blank=True)
    gender          = models.CharField(
        max_length=10,
        choices=GENDER_CHOICES,
        blank=True)
    bio             = models.TextField(blank=True)
    profile_picture = models.ImageField(
        upload_to='patients/', null=True, blank=True)
    medical_history = models.TextField(blank=True)

    def __str__(self):
        return self.user.username


SPECIALIZATION_CHOICES = (
    ('General Physician',    'General Physician'),
    ('Cardiologist',         'Cardiologist'),
    ('Neurologist',          'Neurologist'),
    ('Dermatologist',        'Dermatologist'),
    ('Pediatrician',         'Pediatrician'),
    ('Orthopedist',          'Orthopedist'),
    ('Gynecologist',         'Gynecologist'),
    ('Pulmonologist',        'Pulmonologist'),
    ('Gastroenterologist',   'Gastroenterologist'),
    ('Endocrinologist',      'Endocrinologist'),
    ('Ophthalmologist',      'Ophthalmologist'),
    ('Psychiatrist',         'Psychiatrist'),
    ('Urologist',            'Urologist'),
    ('Oncologist',           'Oncologist'),
    ('ENT Specialist',       'ENT Specialist'),
)


class Doctor(models.Model):
    user             = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE)
    specialization   = models.CharField(
        max_length=200,
        choices=SPECIALIZATION_CHOICES)
    hospital         = models.CharField(max_length=200)
    consultation_fee = models.IntegerField()
    is_verified      = models.BooleanField(default=False)
    bio              = models.TextField(blank=True)
    qualifications   = models.CharField(
        max_length=200, blank=True,
        help_text='e.g. MBBS, MD, PhD')
    experience_years = models.IntegerField(
        null=True, blank=True)
    profile_picture  = models.ImageField(
        upload_to='doctors/', null=True, blank=True)
    payment_qr       = models.ImageField(
        upload_to='payment_qr/', null=True, blank=True)

    def __str__(self):
        return f"Dr. {self.user.username} — {self.specialization}"