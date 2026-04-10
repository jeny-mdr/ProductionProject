from rest_framework import serializers
from .models import Appointment


class AppointmentSerializer(serializers.ModelSerializer):
    patient_name          = serializers.CharField(
        source='patient.username', read_only=True)
    doctor_name           = serializers.CharField(
        source='doctor.username', read_only=True)
    doctor_specialization = serializers.SerializerMethodField()
    doctor_hospital       = serializers.SerializerMethodField()

    class Meta:
        model  = Appointment
        fields = [
            'id', 'patient_name', 'doctor_name',
            'doctor_specialization', 'doctor_hospital',
            'date', 'time', 'reason', 'status',
            'created_at'
        ]

    def get_doctor_specialization(self, obj):
        try:
            return obj.doctor.doctor.specialization
        except Exception:
            return ''

    def get_doctor_hospital(self, obj):
        try:
            return obj.doctor.doctor.hospital
        except Exception:
            return ''