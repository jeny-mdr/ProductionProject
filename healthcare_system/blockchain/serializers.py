from rest_framework import serializers
from .models import BlockchainRecord


class BlockchainRecordSerializer(serializers.ModelSerializer):
    doctor_name  = serializers.CharField(
        source='doctor.username', read_only=True)
    patient_name = serializers.CharField(
        source='patient.username', read_only=True)

    class Meta:
        model  = BlockchainRecord
        fields = [
            'id', 'record_type', 'doctor_name',
            'patient_name', 'data', 'data_hash',
            'previous_hash', 'block_hash', 'created_at'
        ]