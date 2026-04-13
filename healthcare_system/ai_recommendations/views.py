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

BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, 'ml_model', 'disease_model.pkl')
META_PATH  = os.path.join(BASE_DIR, 'ml_model', 'model_metadata.json')

with open(MODEL_PATH, 'rb') as f:
    ML_MODEL = pickle.load(f)

with open(META_PATH, 'r') as f:
    META = json.load(f)

ALL_SYMPTOMS = META['symptoms']
DISEASES     = META['diseases']
DESCRIPTIONS = META['descriptions']
PRECAUTIONS  = META['precautions']
# ── Symptom suggestions map ───────────────────────────
SYMPTOM_SUGGESTIONS = {
    'high_fever': ['chills', 'sweating', 'headache', 'nausea', 'vomiting', 'muscle_pain'],
    'headache': ['nausea', 'vomiting', 'dizziness', 'blurred_and_distorted_vision', 'fatigue'],
    'vomiting': ['nausea', 'stomach_pain', 'abdominal_pain', 'diarrhoea', 'loss_of_appetite'],
    'chest_pain': ['breathlessness', 'sweating', 'fatigue', 'fast_heart_rate', 'vomiting'],
    'cough': ['breathlessness', 'phlegm', 'chest_pain', 'high_fever', 'fatigue'],
    'fatigue': ['weight_loss', 'loss_of_appetite', 'weakness_in_limbs', 'lethargy', 'malaise'],
    'breathlessness': ['chest_pain', 'fatigue', 'cough', 'phlegm', 'sweating'],
    'abdominal_pain': ['nausea', 'vomiting', 'diarrhoea', 'loss_of_appetite', 'acidity'],
    'skin_rash': ['itching', 'nodal_skin_eruptions', 'burning_micturition', 'blister'],
    'joint_pain': ['muscle_pain', 'swelling_joints', 'fatigue', 'fever', 'weakness_in_limbs'],
    'back_pain': ['neck_pain', 'weakness_in_limbs', 'muscle_weakness', 'stiff_neck'],
    'dizziness': ['headache', 'nausea', 'vomiting', 'loss_of_balance', 'unsteadiness'],
    'nausea': ['vomiting', 'loss_of_appetite', 'stomach_pain', 'abdominal_pain'],
    'itching': ['skin_rash', 'nodal_skin_eruptions', 'dischromic_patches'],
    'yellowing_of_eyes': ['yellowish_skin', 'dark_urine', 'nausea', 'loss_of_appetite', 'abdominal_pain'],
    'loss_of_appetite': ['nausea', 'fatigue', 'weight_loss', 'weakness_in_limbs'],
    'muscle_pain': ['joint_pain', 'fatigue', 'high_fever', 'chills', 'sweating'],
    'sweating': ['high_fever', 'chills', 'fatigue', 'dehydration'],
    'chills': ['high_fever', 'sweating', 'shivering', 'muscle_pain'],
    'diarrhoea': ['vomiting', 'nausea', 'abdominal_pain', 'dehydration'],
}


class SymptomSuggestionsView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        selected = request.data.get('symptoms', [])
        suggestions = set()

        for s in selected:
            sym = s.strip().lower().replace(' ', '_')
            if sym in SYMPTOM_SUGGESTIONS:
                for sugg in SYMPTOM_SUGGESTIONS[sym]:
                    if sugg not in selected and sugg in ALL_SYMPTOMS:
                        suggestions.add(sugg)

        return Response({
            "suggestions": list(suggestions)[:6]
        })

print(f"✅ ML Model loaded — "
      f"{len(ALL_SYMPTOMS)} symptoms, "
      f"{len(DISEASES)} diseases, "
      f"Accuracy: {META['accuracy']}%")


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


def symptoms_to_vector(symptoms):
    vector  = np.zeros(len(ALL_SYMPTOMS), dtype=int)
    matched = []
    symptoms_lower = [
        s.strip().lower().replace(' ', '_')
        for s in symptoms
    ]
    for i, sym in enumerate(ALL_SYMPTOMS):
        if sym in symptoms_lower:
            vector[i] = 1
            matched.append(sym)
    return vector, matched


def get_general_doctors(budget=None):
    """Returns only General Physicians."""
    doctors = Doctor.objects.filter(
        is_verified=True,
        specialization__icontains='General'
    ).select_related('user')

    if not doctors.exists():
        doctors = Doctor.objects.filter(
            is_verified=True
        ).select_related('user')

    if budget:
        filtered = doctors.filter(
            consultation_fee__lte=int(budget))
        if filtered.exists():
            doctors = filtered

    return [
        {
            "id":               d.user.id,
            "username":         d.user.username,
            "name":             d.user.username,
            "specialization":   d.specialization,
            "hospital":         d.hospital,
            "consultation_fee": d.consultation_fee,
        }
        for d in doctors[:3]
    ]


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


DISEASE_SPEC_MAP = {
    'Fungal infection':             'Dermatologist',
    'Allergy':                      'General Physician',
    'GERD':                         'Gastroenterologist',
    'Chronic cholestasis':          'Gastroenterologist',
    'Drug Reaction':                'General Physician',
    'Peptic ulcer disease':         'Gastroenterologist',
    'AIDS':                         'General Physician',
    'Diabetes':                     'Endocrinologist',
    'Gastroenteritis':              'Gastroenterologist',
    'Bronchial Asthma':             'Pulmonologist',
    'Hypertension ':                'Cardiologist',
    'Migraine':                     'Neurologist',
    'Cervical spondylosis':         'Orthopedist',
    'Paralysis (brain hemorrhage)': 'Neurologist',
    'Jaundice':                     'Gastroenterologist',
    'Malaria':                      'General Physician',
    'Chicken pox':                  'General Physician',
    'Dengue':                       'General Physician',
    'Typhoid':                      'General Physician',
    'hepatitis A':                  'Gastroenterologist',
    'Hepatitis B':                  'Gastroenterologist',
    'Hepatitis C':                  'Gastroenterologist',
    'Hepatitis D':                  'Gastroenterologist',
    'Hepatitis E':                  'Gastroenterologist',
    'Alcoholic hepatitis':          'Gastroenterologist',
    'Tuberculosis':                 'Pulmonologist',
    'Common Cold':                  'General Physician',
    'Pneumonia':                    'Pulmonologist',
    'Dimorphic hemorrhoids':        'General Physician',
    'Heart attack':                 'Cardiologist',
    'Varicose veins':               'General Physician',
    'Hypothyroidism':               'Endocrinologist',
    'Hyperthyroidism':              'Endocrinologist',
    'Hypoglycemia':                 'Endocrinologist',
    'Osteoarthritis':               'Orthopedist',
    'Arthritis':                    'General Physician',
    'Vertigo':                      'Neurologist',
    'Acne':                         'Dermatologist',
    'Urinary tract infection':      'General Physician',
    'Psoriasis':                    'Dermatologist',
    'Impetigo':                     'Dermatologist',
}


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

        vector, matched_symptoms = \
            symptoms_to_vector(symptoms)

        if sum(vector) == 0:
            return Response({
                "error": "No recognised symptoms found.",
                "hint":  "Please select symptoms from the dropdown list",
                "available_symptoms": ALL_SYMPTOMS[:20],
            }, status=400)

        proba          = ML_MODEL.predict_proba([vector])[0]
        max_confidence = round(max(proba) * 100, 1)
        prediction     = ML_MODEL.predict([vector])[0]
        disease_name   = DISEASES[prediction]

        top_indices  = np.argsort(proba)[::-1][:3]
        top_diseases = [
            {
                "disease":    DISEASES[i],
                "confidence": round(proba[i] * 100, 1),
            }
            for i in top_indices
            if proba[i] > 0.05
        ]

        hospital_list, pharmacy_list = get_nearby(
            user_lat, user_lng)

        # ── Low confidence threshold lowered to 20% ──
        if max_confidence < 20:
            return Response({
                "predicted_disease":   "Uncertain",
                "description": (
                    "Your symptoms are too general. "
                    "Please select more specific symptoms "
                    "from the dropdown list."
                ),
                "precautions": [
                    "Consult a General Physician",
                    "Rest and stay hydrated",
                    "Monitor your symptoms",
                ],
                "confidence":          max_confidence,
                "symptoms_matched":    matched_symptoms,
                "top_predictions":     [],
                "recommended_doctors": get_general_doctors(budget),
                "nearby_hospitals":    hospital_list,
                "nearby_pharmacies":   pharmacy_list,
                "message": (
                    f"Confidence too low ({max_confidence}%). "
                    "Please select symptoms from the dropdown."
                )
            })

        # ── High confidence ──────────────────────────
        description    = DESCRIPTIONS.get(
            disease_name, "No description available.")
        precautions    = PRECAUTIONS.get(disease_name, [])
        specialization = DISEASE_SPEC_MAP.get(
            disease_name, 'General Physician')

        doctors      = Doctor.objects.filter(
            is_verified=True
        ).select_related('user')

        # Try exact specialization match first
        spec_doctors = doctors.filter(
            specialization__icontains=specialization)

        # Only fall back if NO doctors of that specialty exist
        if not spec_doctors.exists():
            spec_doctors = doctors.filter(
                specialization__icontains='General')

        # Apply budget filter
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


class SymptomListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({
            "symptoms": ALL_SYMPTOMS,
            "total":    len(ALL_SYMPTOMS),
        })