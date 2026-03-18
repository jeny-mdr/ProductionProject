from django.http import JsonResponse
from .models import SymptomDisease, Disease
from users.models import Doctor


def predict_disease(request):

    symptoms = request.GET.getlist("symptoms")
    budget = request.GET.get("budget")

    diseases = SymptomDisease.objects.filter(
        symptom__name__in=symptoms
    ).values_list("disease__name", flat=True)

    if not diseases:
        return JsonResponse({"message": "No disease prediction found"})

    disease = diseases[0]

    # ✅ NEW PART
    disease_obj = Disease.objects.get(name=disease)

    doctors = Doctor.objects.filter(
        specialization__icontains=disease_obj.recommended_doctor
    )

    if budget:
        doctors = doctors.filter(consultation_fee__lte=budget)

    doctor_list = [
        {
            "name": d.user.username,
            "specialization": d.specialization,
            "fee": d.consultation_fee
        }
        for d in doctors
    ]

    return JsonResponse({
        "predicted_disease": disease,
        "recommended_doctors": doctor_list
    })