from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Appointment
from .serializers import AppointmentSerializer

User = get_user_model()


class BookAppointmentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != 'patient':
            return Response(
                {"error": "Only patients can book appointments."},
                status=status.HTTP_403_FORBIDDEN)

        doctor_id = request.data.get('doctor_id')
        date      = request.data.get('date')
        time      = request.data.get('time')
        reason    = request.data.get('reason', '')

        if not all([doctor_id, date, time]):
            return Response(
                {"error": "doctor_id, date and time are required."},
                status=status.HTTP_400_BAD_REQUEST)

        try:
            doctor = User.objects.get(
                id=doctor_id, role='doctor')
        except User.DoesNotExist:
            return Response(
                {"error": "Doctor not found."},
                status=status.HTTP_404_NOT_FOUND)

        # Check slot availability
        existing = Appointment.objects.filter(
            doctor=doctor,
            date=date,
            time=time,
            status__in=['pending', 'confirmed']
        ).exists()

        if existing:
            return Response(
                {"error": "This time slot is already booked."},
                status=status.HTTP_400_BAD_REQUEST)

        appointment = Appointment.objects.create(
            patient=request.user,
            doctor=doctor,
            date=date,
            time=time,
            reason=reason,
        )

        serializer = AppointmentSerializer(appointment)
        return Response({
            "message": "Appointment booked successfully!",
            "appointment": serializer.data,
        }, status=status.HTTP_201_CREATED)


class MyAppointmentsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == 'patient':
            appointments = Appointment.objects.filter(
                patient=user).select_related(
                'doctor', 'doctor__doctor')
        elif user.role == 'doctor':
            appointments = Appointment.objects.filter(
                doctor=user).select_related(
                'patient', 'doctor__doctor')
        else:
            return Response(
                {"error": "Admin has no appointments."},
                status=400)

        serializer = AppointmentSerializer(
            appointments, many=True)
        return Response(serializer.data)


class UpdateAppointmentView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        if request.user.role != 'doctor':
            return Response(
                {"error": "Only doctors can update appointments."},
                status=status.HTTP_403_FORBIDDEN)

        try:
            appointment = Appointment.objects.get(
                pk=pk, doctor=request.user)
        except Appointment.DoesNotExist:
            return Response(
                {"error": "Appointment not found."},
                status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get('status')
        if new_status not in [
                'confirmed', 'cancelled', 'completed']:
            return Response(
                {"error": "Invalid status."},
                status=status.HTTP_400_BAD_REQUEST)

        appointment.status = new_status
        appointment.save()

        serializer = AppointmentSerializer(appointment)
        return Response({
            "message": f"Appointment {new_status}.",
            "appointment": serializer.data,
        })