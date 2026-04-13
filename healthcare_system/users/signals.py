from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Doctor
from blockchain.models import BlockchainRecord


@receiver(post_save, sender=Doctor)
def store_verification_hash(
        sender, instance, **kwargs):
    # Only trigger when doctor is verified
    if not instance.is_verified:
        return

    # Check if already stored
    already_exists = BlockchainRecord.objects.filter(
        record_type='doctor_verification',
        doctor=instance.user,
    ).exists()

    if already_exists:
        return

    # Store verification hash on blockchain
    data = (
        f"Doctor {instance.user.username} "
        f"specialization: {instance.specialization} "
        f"hospital: {instance.hospital} "
        f"verified on blockchain."
    )

    BlockchainRecord.objects.create(
        record_type='doctor_verification',
        doctor=instance.user,
        patient=None,
        data=data,
    )
    print(f"✅ Blockchain: Doctor verification hash stored for {instance.user.username}")