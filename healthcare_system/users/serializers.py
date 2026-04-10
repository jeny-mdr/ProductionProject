from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Patient, Doctor, SPECIALIZATION_CHOICES

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password       = serializers.CharField(
        write_only=True, min_length=8)
    role           = serializers.ChoiceField(
        choices=['patient', 'doctor'])

    # Patient fields
    age            = serializers.IntegerField(required=False)
    gender         = serializers.CharField(required=False)
    patient_bio    = serializers.CharField(required=False, allow_blank=True)

    # Doctor fields
    specialization   = serializers.ChoiceField(
        choices=[c[0] for c in SPECIALIZATION_CHOICES],
        required=False)
    hospital         = serializers.CharField(required=False)
    consultation_fee = serializers.IntegerField(required=False)
    qualifications   = serializers.CharField(required=False)
    experience_years = serializers.IntegerField(required=False)
    doctor_bio = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model  = User
        fields = [
            'username', 'email', 'password', 'role',
            # patient
            'age', 'gender', 'patient_bio',
            # doctor
            'specialization', 'hospital',
            'consultation_fee', 'qualifications',
            'experience_years', 'doctor_bio',
        ]

    def validate(self, data):
        if data['role'] == 'doctor':
            if not data.get('specialization'):
                raise serializers.ValidationError(
                    "Doctors must provide specialization.")
            if not data.get('hospital'):
                raise serializers.ValidationError(
                    "Doctors must provide hospital.")
            if not data.get('consultation_fee'):
                raise serializers.ValidationError(
                    "Doctors must provide consultation fee.")
        return data

    def create(self, validated_data):
        role = validated_data['role']

        # Pop patient fields
        age         = validated_data.pop('age', None)
        gender      = validated_data.pop('gender', '')
        patient_bio = validated_data.pop('patient_bio', '')

        # Pop doctor fields
        specialization   = validated_data.pop('specialization', None)
        hospital         = validated_data.pop('hospital', None)
        consultation_fee = validated_data.pop('consultation_fee', None)
        qualifications   = validated_data.pop('qualifications', '')
        experience_years = validated_data.pop('experience_years', None)
        doctor_bio       = validated_data.pop('doctor_bio', '')

        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            role=role,
        )

        if role == 'patient':
            Patient.objects.create(
                user=user,
                age=age,
                gender=gender,
                bio=patient_bio,
            )
        elif role == 'doctor':
            Doctor.objects.create(
                user=user,
                specialization=specialization,
                hospital=hospital,
                consultation_fee=consultation_fee,
                qualifications=qualifications,
                experience_years=experience_years,
                bio=doctor_bio,
                is_verified=False,
            )
        return user


class PatientProfileSerializer(serializers.ModelSerializer):
    username        = serializers.CharField(
        source='user.username', read_only=True)
    email           = serializers.EmailField(
        source='user.email', read_only=True)
    role            = serializers.CharField(
        source='user.role', read_only=True)
    profile_picture = serializers.ImageField(
        required=False, allow_null=True)

    class Meta:
        model  = Patient
        fields = [
            'username', 'email', 'role',
            'age', 'gender', 'bio',
            'medical_history', 'profile_picture',
        ]


class DoctorProfileSerializer(serializers.ModelSerializer):
    username        = serializers.CharField(
        source='user.username', read_only=True)
    email           = serializers.EmailField(
        source='user.email', read_only=True)
    id              = serializers.IntegerField(
        source='user.id', read_only=True)
    role            = serializers.CharField(
        source='user.role', read_only=True)
    profile_picture = serializers.ImageField(
        required=False, allow_null=True)
    payment_qr      = serializers.ImageField(
        required=False, allow_null=True)

    class Meta:
        model  = Doctor
        fields = [
            'id', 'username', 'email', 'role',
            'specialization', 'hospital',
            'consultation_fee', 'is_verified',
            'bio', 'qualifications', 'experience_years',
            'profile_picture', 'payment_qr',
        ]