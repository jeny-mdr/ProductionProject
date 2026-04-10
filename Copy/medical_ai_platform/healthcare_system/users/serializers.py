from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Patient, Doctor

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    role = serializers.ChoiceField(choices=['patient', 'doctor'])

    # Doctor-only fields (optional at registration)
    specialization = serializers.CharField(required=False)
    hospital = serializers.CharField(required=False)
    consultation_fee = serializers.IntegerField(required=False)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'role',
                  'specialization', 'hospital', 'consultation_fee']

    def validate(self, data):
        if data['role'] == 'doctor':
            if not data.get('specialization'):
                raise serializers.ValidationError("Doctors must provide specialization.")
            if not data.get('hospital'):
                raise serializers.ValidationError("Doctors must provide hospital.")
            if not data.get('consultation_fee'):
                raise serializers.ValidationError("Doctors must provide consultation fee.")
        return data

    def create(self, validated_data):
        role = validated_data['role']
        specialization = validated_data.pop('specialization', None)
        hospital = validated_data.pop('hospital', None)
        consultation_fee = validated_data.pop('consultation_fee', None)

        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            role=role,
        )

        if role == 'patient':
            Patient.objects.create(user=user)
        elif role == 'doctor':
            Doctor.objects.create(
                user=user,
                specialization=specialization,
                hospital=hospital,
                consultation_fee=consultation_fee,
                is_verified=False,   # waits for admin approval
            )
        return user


class PatientProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = Patient
        fields = ['username', 'email', 'age', 'medical_history']


class DoctorProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = Doctor
        fields = ['username', 'email', 'specialization', 'hospital',
                  'consultation_fee', 'is_verified', 'bio', 'profile_picture']