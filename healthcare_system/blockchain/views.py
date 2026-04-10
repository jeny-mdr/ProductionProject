from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from .models import BlockchainRecord
from .serializers import BlockchainRecordSerializer
from users.models import Doctor
from django.contrib.auth import get_user_model

User = get_user_model()


class SavePrescriptionView(APIView):
    """Doctor saves a prescription → stored as blockchain record."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Only doctors can save prescriptions
        if request.user.role != 'doctor':
            return Response(
                {"error": "Only doctors can save prescriptions."},
                status=status.HTTP_403_FORBIDDEN
            )

        patient_id   = request.data.get('patient_id')
        prescription = request.data.get('prescription', '').strip()

        if not patient_id:
            return Response(
                {"error": "patient_id is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        if not prescription:
            return Response(
                {"error": "Prescription text is required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            patient = User.objects.get(
                id=patient_id, role='patient')
        except User.DoesNotExist:
            return Response(
                {"error": "Patient not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        record = BlockchainRecord.objects.create(
            record_type = 'prescription',
            patient     = patient,
            doctor      = request.user,
            data        = prescription,
        )

        serializer = BlockchainRecordSerializer(record)
        return Response({
            "message":  "Prescription saved to blockchain.",
            "record":   serializer.data,
        }, status=status.HTTP_201_CREATED)


class MyPrescriptionsView(APIView):
    """Patient views their own prescriptions."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'patient':
            return Response(
                {"error": "Only patients can view prescriptions."},
                status=status.HTTP_403_FORBIDDEN
            )
        records = BlockchainRecord.objects.filter(
            patient     = request.user,
            record_type = 'prescription'
        )
        serializer = BlockchainRecordSerializer(
            records, many=True)
        return Response(serializer.data)


class VerifyChainView(APIView):
    """Verify the entire blockchain is intact : no tampering."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        records = BlockchainRecord.objects.all()

        if not records.exists():
            return Response({
                "valid": True,
                "total_blocks": 0,
                "message": "No records yet. Blockchain is empty.",
            })

        prev_hash = '0' * 64  # genesis

        for record in records:
            # Recompute expected hash
            expected = BlockchainRecord.compute_hash(
                record.data_hash,
                prev_hash,
                record.created_at.isoformat() if record.created_at else ''
            )
            if expected != record.block_hash:
                return Response({
                    "valid": False,
                    "message": f"Chain broken at record ID {record.id}!",
                })
            prev_hash = record.block_hash

        return Response({
            "valid": True,
            "total_blocks": records.count(),
            "message": "Blockchain is intact. No tampering detected.",
        })


class DoctorVerificationHashView(APIView):
    """Auto-called when admin verifies a doctor — stores hash."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Only admin can call this
        if request.user.role != 'admin':
            return Response(
                {"error": "Admin only."},
                status=status.HTTP_403_FORBIDDEN
            )

        doctor_id = request.data.get('doctor_id')
        try:
            doctor = User.objects.get(
                id=doctor_id, role='doctor')
        except User.DoesNotExist:
            return Response(
                {"error": "Doctor not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        data = (f"Doctor {doctor.username} verified "
                f"by admin {request.user.username}")

        record = BlockchainRecord.objects.create(
            record_type = 'doctor_verification',
            doctor      = doctor,
            patient     = None,
            data        = data,
        )

        serializer = BlockchainRecordSerializer(record)
        return Response({
            "message": "Doctor verification recorded on blockchain.",
            "record":  serializer.data,
        }, status=status.HTTP_201_CREATED)