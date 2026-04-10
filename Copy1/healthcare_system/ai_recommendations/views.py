from django.http import JsonResponse
from .models import SymptomDisease
from users.models import Doctor
from hospitals.models import Hospital, Pharmacy
import math


# 🔹 Haversine Formula (distance calculation)
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # Earth radius in km

    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)

    a = (math.sin(d_lat/2) ** 2 +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) *
         math.sin(d_lon/2) ** 2)

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


# 1. SIMPLE DISEASE PREDICTION API
def predict_disease(request):
    symptoms = request.GET.getlist("symptoms")

    if not symptoms:
        return JsonResponse({"error": "No symptoms provided"})

    diseases = SymptomDisease.objects.filter(
        symptom__name__in=symptoms
    ).select_related("disease")

    if not diseases:
        return JsonResponse({"message": "No disease prediction found"})

    disease = diseases[0].disease

    return JsonResponse({
        "predicted_disease": disease.name
    })


# 2. FULL RECOMMENDATION SYSTEM
def full_recommendation(request):

    # 🔹 INPUTS
    symptoms = request.GET.getlist("symptoms")
    budget = request.GET.get("budget")

    try:
        user_lat = float(request.GET.get("lat", 0))
        user_lng = float(request.GET.get("lng", 0))
    except:
        return JsonResponse({"error": "Invalid location data"})

    # 🔹 DISEASE PREDICTION
    diseases = SymptomDisease.objects.filter(
        symptom__name__in=symptoms
    ).select_related("disease")

    if not diseases:
        return JsonResponse({"message": "No disease prediction found"})

    disease = diseases[0].disease

    # DOCTOR FILTER
    doctors = Doctor.objects.filter(
        specialization__icontains=disease.doctor_specialization
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

    # HOSPITALS
    hospital_list = []
    for h in Hospital.objects.exclude(latitude=None, longitude=None):

        dist = haversine(user_lat, user_lng, h.latitude, h.longitude)

        map_link = f"https://www.google.com/maps/dir/?api=1&destination={h.latitude},{h.longitude}"

        hospital_list.append({
            "name": h.name,
            "address": h.address,
            "distance_km": round(dist, 2),
            "map_link": map_link
        })

    hospital_list.sort(key=lambda x: x["distance_km"])

    # PHARMACIES
    pharmacy_list = []
    for p in Pharmacy.objects.exclude(latitude=None, longitude=None):

        dist = haversine(user_lat, user_lng, p.latitude, p.longitude)

        map_link = f"https://www.google.com/maps/dir/?api=1&destination={p.latitude},{p.longitude}"

        pharmacy_list.append({
            "name": p.name,
            "address": p.address,
            "distance_km": round(dist, 2),
            "map_link": map_link
        })

    pharmacy_list.sort(key=lambda x: x["distance_km"])

    # FINAL RESPONSE
    return JsonResponse({
        "predicted_disease": disease.name,
        "recommended_doctors": doctor_list,
        "nearby_hospitals": hospital_list,
        "nearby_pharmacies": pharmacy_list
    })