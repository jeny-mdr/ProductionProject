from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import get_user_model
from .models import Patient, Doctor
from .serializers import RegisterSerializer, PatientProfileSerializer, DoctorProfileSerializer

User = get_user_model()


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(
                {"message": f"Account created for {user.username}. "
                            f"{'Await admin verification.' if user.role == 'doctor' else 'You can log in now.'}"},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == 'patient':
            try:
                serializer = PatientProfileSerializer(user.patient)
                return Response(serializer.data)
            except Patient.DoesNotExist:
                return Response({"error": "Patient profile not found"}, status=404)

        elif user.role == 'doctor':
            try:
                serializer = DoctorProfileSerializer(user.doctor)
                return Response(serializer.data)
            except Doctor.DoesNotExist:
                return Response({"error": "Doctor profile not found"}, status=404)

        return Response({"error": "Admin profile has no extended data"}, status=400)

    def patch(self, request):
        user = request.user
        if user.role == 'patient':
            serializer = PatientProfileSerializer(user.patient, data=request.data, partial=True)
        elif user.role == 'doctor':
            serializer = DoctorProfileSerializer(user.doctor, data=request.data, partial=True)
        else:
            return Response({"error": "Cannot update admin profile here"}, status=400)

        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)


class DoctorListView(APIView):
    """Returns only verified doctors. Optionally filter by specialization."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        specialization = request.query_params.get('specialization', None)
        doctors = Doctor.objects.filter(is_verified=True).select_related('user')

        if specialization:
            doctors = doctors.filter(specialization__icontains=specialization)

        serializer = DoctorProfileSerializer(doctors, many=True)
        return Response(serializer.data)