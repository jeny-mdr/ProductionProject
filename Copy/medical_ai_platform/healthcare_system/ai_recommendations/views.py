from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from collections import Counter
import math

from .models import SymptomDisease
from users.models import Doctor
from hospitals.models import Hospital, Pharmacy


def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) *
         math.sin(d_lon / 2) ** 2)
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


class PredictDiseaseView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        symptoms = request.data.get('symptoms', [])

        if not symptoms:
            return Response({"error": "No symptoms provided"}, status=400)

        matches = SymptomDisease.objects.filter(
            symptom__name__in=symptoms
        ).select_related('disease')

        if not matches:
            return Response({"message": "No matching disease found for these symptoms"}, status=404)

        # Count how many input symptoms matched each disease
        disease_counter = Counter()
        disease_objects = {}
        for m in matches:
            disease_counter[m.disease.id] += 1
            disease_objects[m.disease.id] = m.disease

        # Sort diseases by match count descending
        ranked = sorted(disease_counter.items(), key=lambda x: x[1], reverse=True)

        results = []
        for disease_id, match_count in ranked:
            disease = disease_objects[disease_id]
            results.append({
                "disease": disease.name,
                "description": disease.description,
                "recommended_specialization": disease.doctor_specialization,
                "symptoms_matched": match_count,
                "match_score": f"{match_count}/{len(symptoms)}",
            })

        return Response({"predictions": results})


class FullRecommendationView(APIView):

    permission_classes = [IsAuthenticated]

    def post(self, request):
        symptoms = request.data.get('symptoms', [])
        budget = request.data.get('budget', None)
        user_lat = request.data.get('lat', 0)
        user_lng = request.data.get('lng', 0)

        if not symptoms:
            return Response({"error": "No symptoms provided"}, status=400)

        try:
            user_lat = float(user_lat)
            user_lng = float(user_lng)
        except (TypeError, ValueError):
            return Response({"error": "Invalid lat/lng"}, status=400)

        # --- Disease scoring (same fix as above) ---
        matches = SymptomDisease.objects.filter(
            symptom__name__in=symptoms
        ).select_related('disease')

        if not matches:
            return Response({"message": "No disease found for these symptoms"}, status=404)

        disease_counter = Counter()
        disease_objects = {}
        for m in matches:
            disease_counter[m.disease.id] += 1
            disease_objects[m.disease.id] = m.disease

        top_disease_id = max(disease_counter, key=disease_counter.get)
        disease = disease_objects[top_disease_id]

        # --- Doctors: only verified, matching specialization ---
        doctors = Doctor.objects.filter(
            specialization__icontains=disease.doctor_specialization,
            is_verified=True
        ).select_related('user')

        if budget:
            doctors = doctors.filter(consultation_fee__lte=int(budget))

        doctor_list = [
            {
                "name": f"Dr. {d.user.username}",
                "specialization": d.specialization,
                "hospital": d.hospital,
                "fee": d.consultation_fee,
            }
            for d in doctors
        ]

        # --- Nearby hospitals ---
        hospital_list = []
        for h in Hospital.objects.exclude(latitude=None, longitude=None):
            dist = haversine(user_lat, user_lng, h.latitude, h.longitude)
            hospital_list.append({
                "name": h.name,
                "address": h.address,
                "distance_km": round(dist, 2),
                "map_link": f"https://www.google.com/maps/dir/?api=1&destination={h.latitude},{h.longitude}",
            })
        hospital_list.sort(key=lambda x: x["distance_km"])

        # --- Nearby pharmacies ---
        pharmacy_list = []
        for p in Pharmacy.objects.exclude(latitude=None, longitude=None):
            dist = haversine(user_lat, user_lng, p.latitude, p.longitude)
            pharmacy_list.append({
                "name": p.name,
                "address": p.address,
                "distance_km": round(dist, 2),
                "map_link": f"https://www.google.com/maps/dir/?api=1&destination={p.latitude},{p.longitude}",
            })
        pharmacy_list.sort(key=lambda x: x["distance_km"])

        return Response({
            "predicted_disease": disease.name,
            "description": disease.description,
            "symptoms_matched": f"{disease_counter[top_disease_id]}/{len(symptoms)}",
            "recommended_doctors": doctor_list,
            "nearby_hospitals": hospital_list[:5],      # top 5 closest
            "nearby_pharmacies": pharmacy_list[:5],
        })