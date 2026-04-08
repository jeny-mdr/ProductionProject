from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
import math
import pickle
import json
import numpy as np
import os

from users.models import Doctor
from hospitals.models import Hospital, Pharmacy

# ── Load ML model on startup ──────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(
    BASE_DIR, 'ml_model', 'disease_model.pkl')
META_PATH = os.path.join(
    BASE_DIR, 'ml_model', 'model_metadata.json')

with open(MODEL_PATH, 'rb') as f:
    ML_MODEL = pickle.load(f)

with open(META_PATH, 'r') as f:
    META = json.load(f)

ALL_SYMPTOMS = META['symptoms']
DISEASES     = META['diseases']
DESCRIPTIONS = META['descriptions']
PRECAUTIONS  = META['precautions']

print(f"✅ ML Model loaded — "
      f"{len(ALL_SYMPTOMS)} symptoms, "
      f"{len(DISEASES)} diseases, "
      f"Accuracy: {META['accuracy']}%")


# ── Haversine distance ────────────────────────────────
def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) *
         math.sin(d_lon / 2) ** 2)
    return R * 2 * math.atan2(
        math.sqrt(a), math.sqrt(1 - a))


# ── Helper: symptoms to vector ────────────────────────
def symptoms_to_vector(symptoms):
    vector = np.zeros(len(ALL_SYMPTOMS), dtype=int)
    matched = []
    symptoms_lower = [s.strip().lower() for s in symptoms]
    for i, sym in enumerate(ALL_SYMPTOMS):
        if sym in symptoms_lower:
            vector[i] = 1
            matched.append(sym)
    return vector, matched


# ── General doctors helper ────────────────────────────
def get_general_doctors():
    doctors = Doctor.objects.filter(
        is_verified=True
    ).select_related('user')[:3]
    return [
        {
            "id":               d.user.id,
            "username":         d.user.username,
            "name":             d.user.username,
            "specialization":   d.specialization,
            "hospital":         d.hospital,
            "consultation_fee": d.consultation_fee,
        }
        for d in doctors
    ]


# ── Hospitals and pharmacies helper ──────────────────
def get_nearby(user_lat, user_lng):
    hospital_list = []
    for h in Hospital.objects.exclude(
            latitude=None, longitude=None):
        dist = haversine(
            user_lat, user_lng,
            h.latitude, h.longitude)
        hospital_list.append({
            "name":        h.name,
            "address":     h.address,
            "distance_km": round(dist, 2),
            "map_link": (
                f"https://www.google.com/maps/"
                f"dir/?api=1&destination="
                f"{h.latitude},{h.longitude}"
            ),
        })
    hospital_list.sort(key=lambda x: x["distance_km"])

    pharmacy_list = []
    for p in Pharmacy.objects.exclude(
            latitude=None, longitude=None):
        dist = haversine(
            user_lat, user_lng,
            p.latitude, p.longitude)
        pharmacy_list.append({
            "name":        p.name,
            "address":     p.address,
            "distance_km": round(dist, 2),
            "map_link": (
                f"https://www.google.com/maps/"
                f"dir/?api=1&destination="
                f"{p.latitude},{p.longitude}"
            ),
        })
    pharmacy_list.sort(key=lambda x: x["distance_km"])

    return hospital_list[:5], pharmacy_list[:5]


# ── Disease to specialization map ─────────────────────
DISEASE_SPEC_MAP = {
    'Fungal infection':        'Dermatologist',
    'Allergy':                 'General Physician',
    'GERD':                    'Gastroenterologist',
    'Chronic cholestasis':     'Gastroenterologist',
    'Drug Reaction':           'General Physician',
    'Peptic ulcer disease':    'Gastroenterologist',
    'AIDS':                    'General Physician',
    'Diabetes':                'Endocrinologist',
    'Gastroenteritis':         'Gastroenterologist',
    'Bronchial Asthma':        'Pulmonologist',
    'Hypertension':            'Cardiologist',
    'Migraine':                'Neurologist',
    'Cervical spondylosis':    'Orthopedist',
    'Paralysis (brain hemorrhage)': 'Neurologist',
    'Jaundice':                'Gastroenterologist',
    'Malaria':                 'General Physician',
    'Chicken pox':             'General Physician',
    'Dengue':                  'General Physician',
    'Typhoid':                 'General Physician',
    'hepatitis A':             'Gastroenterologist',
    'Hepatitis B':             'Gastroenterologist',
    'Hepatitis C':             'Gastroenterologist',
    'Hepatitis D':             'Gastroenterologist',
    'Hepatitis E':             'Gastroenterologist',
    'Alcoholic hepatitis':     'Gastroenterologist',
    'Tuberculosis':            'Pulmonologist',
    'Common Cold':             'General Physician',
    'Pneumonia':               'Pulmonologist',
    'Dimorphic hemorrhoids':   'General Physician',
    'Heart attack':            'Cardiologist',
    'Varicose veins':          'General Physician',
    'Hypothyroidism':          'Endocrinologist',
    'Hyperthyroidism':         'Endocrinologist',
    'Hypoglycemia':            'Endocrinologist',
    'Osteoarthritis':          'Orthopedist',
    'Arthritis':               'General Physician',
    'Vertigo':                 'Neurologist',
    'Acne':                    'Dermatologist',
    'Urinary tract infection': 'General Physician',
    'Psoriasis':               'Dermatologist',
    'Impetigo':                'Dermatologist',
}


# ── Main recommendation view ──────────────────────────
class FullRecommendationView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        symptoms = request.data.get('symptoms', [])
        budget   = request.data.get('budget', None)
        user_lat = request.data.get('lat', 0)
        user_lng = request.data.get('lng', 0)

        if not symptoms:
            return Response(
                {"error": "No symptoms provided"},
                status=400)

        if len(symptoms) < 3:
            return Response({
                "error": "Please add at least 3 symptoms.",
                "hint":  "Example: fever, headache, fatigue, nausea"
            }, status=400)

        try:
            user_lat = float(user_lat)
            user_lng = float(user_lng)
        except (TypeError, ValueError):
            return Response(
                {"error": "Invalid lat/lng"},
                status=400)

        # ── Build feature vector ──────────────────────
        vector, matched_symptoms = \
            symptoms_to_vector(symptoms)

        if sum(vector) == 0:
            return Response({
                "error": "No recognised symptoms found.",
                "hint":  "Try: fever, headache, cough, fatigue",
                "available_symptoms": ALL_SYMPTOMS[:20],
            }, status=400)

        # ── ML Prediction ─────────────────────────────
        proba          = ML_MODEL.predict_proba([vector])[0]
        max_confidence = round(max(proba) * 100, 1)
        prediction     = ML_MODEL.predict([vector])[0]
        disease_name   = DISEASES[prediction]

        # Top 3 predictions
        top_indices = np.argsort(proba)[::-1][:3]
        top_diseases = [
            {
                "disease":    DISEASES[i],
                "confidence": round(proba[i] * 100, 1),
            }
            for i in top_indices
            if proba[i] > 0.05
        ]

        # ── Get hospitals and pharmacies ──────────────
        hospital_list, pharmacy_list = get_nearby(
            user_lat, user_lng)

        # ── Low confidence — don't guess! ─────────────
        if max_confidence < 40:
            return Response({
                "predicted_disease": "Uncertain",
                "description": (
                    "Your symptoms are too general to make "
                    "a confident prediction. Please add more "
                    "specific symptoms or consult a doctor."
                ),
                "precautions": [
                    "Consult a doctor",
                    "Rest and stay hydrated",
                    "Monitor your symptoms",
                ],
                "confidence":        max_confidence,
                "symptoms_matched":  matched_symptoms,
                "top_predictions":   [],
                "recommended_doctors": get_general_doctors(),
                "nearby_hospitals":  hospital_list,
                "nearby_pharmacies": pharmacy_list,
                "message": (
                    f"Confidence too low ({max_confidence}%). "
                    "Please describe your symptoms more specifically."
                )
            })

        # ── High confidence — full response ───────────
        description  = DESCRIPTIONS.get(
            disease_name, "No description available.")
        precautions  = PRECAUTIONS.get(disease_name, [])
        specialization = DISEASE_SPEC_MAP.get(
            disease_name, 'General Physician')

        # Find matching doctors
        doctors = Doctor.objects.filter(
            is_verified=True
        ).select_related('user')

        spec_doctors = doctors.filter(
            specialization__icontains=specialization)

        if not spec_doctors.exists():
            spec_doctors = doctors.filter(
                specialization__icontains='General')

        if not spec_doctors.exists():
            spec_doctors = doctors

        if budget:
            budget_filtered = spec_doctors.filter(
                consultation_fee__lte=int(budget))
            if budget_filtered.exists():
                spec_doctors = budget_filtered

        doctor_list = [
            {
                "id":               d.user.id,
                "username":         d.user.username,
                "name":             d.user.username,
                "specialization":   d.specialization,
                "hospital":         d.hospital,
                "consultation_fee": d.consultation_fee,
            }
            for d in spec_doctors[:5]
        ]

        return Response({
            "predicted_disease":   disease_name,
            "description":         description,
            "precautions":         precautions,
            "confidence":          max_confidence,
            "symptoms_matched":    matched_symptoms,
            "top_predictions":     top_diseases,
            "recommended_doctors": doctor_list,
            "nearby_hospitals":    hospital_list,
            "nearby_pharmacies":   pharmacy_list,
        })


# ── Old predict view ──────────────────────────────────
class PredictDiseaseView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        symptoms = request.data.get('symptoms', [])
        if not symptoms:
            return Response(
                {"error": "No symptoms provided"},
                status=400)

        vector, matched = symptoms_to_vector(symptoms)

        if sum(vector) == 0:
            return Response(
                {"error": "No recognised symptoms"},
                status=400)

        prediction   = ML_MODEL.predict([vector])[0]
        disease_name = DISEASES[prediction]

        return Response({
            "predicted_disease": disease_name,
            "description":       DESCRIPTIONS.get(
                disease_name, ""),
            "symptoms_matched":  matched,
        })


# ── Symptom list view ─────────────────────────────────
class SymptomListView(APIView):
    """Returns all 131 known symptoms for autocomplete."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({
            "symptoms": ALL_SYMPTOMS,
            "total":    len(ALL_SYMPTOMS),
        })