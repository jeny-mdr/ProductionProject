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
#  Symptom suggestions map
SYMPTOM_SUGGESTIONS = {
    # Fever related
    'high_fever': ['chills', 'sweating', 'headache', 'nausea', 'vomiting', 'muscle_pain', 'fatigue', 'loss_of_appetite'],
    'mild_fever': ['headache', 'fatigue', 'chills', 'sweating', 'nausea', 'loss_of_appetite'],
    'chills': ['high_fever', 'sweating', 'shivering', 'muscle_pain', 'headache', 'fatigue'],
    'sweating': ['high_fever', 'chills', 'fatigue', 'dehydration', 'nausea'],
    'shivering': ['chills', 'high_fever', 'sweating', 'fatigue', 'nausea'],

    # Head related
    'headache': ['nausea', 'vomiting', 'dizziness', 'blurred_and_distorted_vision', 'fatigue', 'high_fever', 'neck_pain'],
    'dizziness': ['headache', 'nausea', 'vomiting', 'loss_of_balance', 'unsteadiness', 'spinning_movements'],
    'spinning_movements': ['dizziness', 'loss_of_balance', 'nausea', 'vomiting', 'unsteadiness'],
    'loss_of_balance': ['dizziness', 'unsteadiness', 'spinning_movements', 'weakness_in_limbs'],
    'unsteadiness': ['loss_of_balance', 'dizziness', 'spinning_movements', 'weakness_in_limbs'],
    'blurred_and_distorted_vision': ['headache', 'dizziness', 'nausea', 'weakness_of_one_body_side'],
    'visual_disturbances': ['blurred_and_distorted_vision', 'headache', 'dizziness', 'nausea'],

    # Stomach/Digestive
    'nausea': ['vomiting', 'loss_of_appetite', 'stomach_pain', 'abdominal_pain', 'indigestion'],
    'vomiting': ['nausea', 'stomach_pain', 'abdominal_pain', 'diarrhoea', 'loss_of_appetite', 'dehydration'],
    'abdominal_pain': ['nausea', 'vomiting', 'diarrhoea', 'loss_of_appetite', 'acidity', 'indigestion'],
    'stomach_pain': ['nausea', 'vomiting', 'indigestion', 'acidity', 'loss_of_appetite', 'diarrhoea'],
    'diarrhoea': ['vomiting', 'nausea', 'abdominal_pain', 'dehydration', 'stomach_pain'],
    'constipation': ['stomach_pain', 'abdominal_pain', 'indigestion', 'passage_of_gases', 'acidity'],
    'indigestion': ['acidity', 'stomach_pain', 'nausea', 'vomiting', 'loss_of_appetite'],
    'acidity': ['indigestion', 'stomach_pain', 'nausea', 'chest_pain', 'vomiting'],
    'loss_of_appetite': ['nausea', 'fatigue', 'weight_loss', 'weakness_in_limbs', 'vomiting'],
    'passage_of_gases': ['stomach_pain', 'abdominal_pain', 'indigestion', 'constipation'],
    'distention_of_abdomen': ['abdominal_pain', 'stomach_pain', 'nausea', 'vomiting', 'swelling_of_stomach'],
    'stomach_bleeding': ['bloody_stool', 'vomiting', 'abdominal_pain', 'fatigue', 'weakness_in_limbs'],
    'bloody_stool': ['stomach_bleeding', 'pain_during_bowel_movements', 'abdominal_pain', 'fatigue'],
    'pain_during_bowel_movements': ['bloody_stool', 'constipation', 'pain_in_anal_region', 'irritation_in_anus'],
    'pain_in_anal_region': ['pain_during_bowel_movements', 'irritation_in_anus', 'bloody_stool', 'constipation'],
    'irritation_in_anus': ['pain_in_anal_region', 'pain_during_bowel_movements', 'bloody_stool'],

    # Chest/Breathing
    'chest_pain': ['breathlessness', 'sweating', 'fatigue', 'fast_heart_rate', 'vomiting', 'nausea'],
    'breathlessness': ['chest_pain', 'fatigue', 'cough', 'phlegm', 'sweating', 'wheezing'],
    'cough': ['breathlessness', 'phlegm', 'chest_pain', 'high_fever', 'fatigue', 'throat_irritation'],
    'phlegm': ['cough', 'breathlessness', 'chest_pain', 'mucoid_sputum', 'rusty_sputum'],
    'mucoid_sputum': ['cough', 'phlegm', 'breathlessness', 'chest_pain'],
    'rusty_sputum': ['cough', 'phlegm', 'breathlessness', 'blood_in_sputum', 'chest_pain'],
    'blood_in_sputum': ['cough', 'chest_pain', 'breathlessness', 'fatigue', 'weight_loss'],
    'fast_heart_rate': ['chest_pain', 'breathlessness', 'fatigue', 'sweating', 'palpitations'],
    'palpitations': ['fast_heart_rate', 'chest_pain', 'breathlessness', 'fatigue', 'sweating'],

    # Fatigue/Weakness
    'fatigue': ['weight_loss', 'loss_of_appetite', 'weakness_in_limbs', 'lethargy', 'malaise'],
    'weakness_in_limbs': ['fatigue', 'joint_pain', 'muscle_pain', 'lethargy', 'malaise'],
    'lethargy': ['fatigue', 'weakness_in_limbs', 'malaise', 'loss_of_appetite', 'depression'],
    'malaise': ['fatigue', 'lethargy', 'weakness_in_limbs', 'loss_of_appetite', 'high_fever'],
    'muscle_pain': ['joint_pain', 'fatigue', 'high_fever', 'chills', 'sweating', 'weakness_in_limbs'],
    'muscle_weakness': ['weakness_in_limbs', 'fatigue', 'muscle_pain', 'joint_pain', 'lethargy'],
    'muscle_wasting': ['weakness_in_limbs', 'fatigue', 'weight_loss', 'muscle_weakness'],

    # Skin related
    'skin_rash': ['itching', 'nodal_skin_eruptions', 'burning_micturition', 'blister', 'redness_of_eyes'],
    'itching': ['skin_rash', 'nodal_skin_eruptions', 'dischromic _patches', 'scurring'],
    'nodal_skin_eruptions': ['skin_rash', 'itching', 'blister', 'red_spots_over_body'],
    'blister': ['skin_rash', 'itching', 'nodal_skin_eruptions', 'red_spots_over_body'],
    'pus_filled_pimples': ['blackheads', 'skin_rash', 'itching', 'scurring'],
    'blackheads': ['pus_filled_pimples', 'skin_rash', 'scurring', 'skin_peeling'],
    'scurring': ['skin_rash', 'itching', 'blackheads', 'pus_filled_pimples'],
    'skin_peeling': ['skin_rash', 'itching', 'silver_like_dusting', 'small_dents_in_nails'],
    'silver_like_dusting': ['skin_peeling', 'skin_rash', 'itching', 'small_dents_in_nails'],
    'dischromic _patches': ['itching', 'skin_rash', 'nodal_skin_eruptions'],
    'red_spots_over_body': ['skin_rash', 'itching', 'blister', 'nodal_skin_eruptions', 'high_fever'],
    'red_sore_around_nose': ['runny_nose', 'congestion', 'continuous_sneezing', 'throat_irritation'],
    'yellow_crust_ooze': ['skin_rash', 'blister', 'pus_filled_pimples', 'itching'],

    # Eyes
    'redness_of_eyes': ['watering_from_eyes', 'itching', 'pain_behind_the_eyes', 'blurred_and_distorted_vision'],
    'watering_from_eyes': ['redness_of_eyes', 'itching', 'continuous_sneezing', 'runny_nose'],
    'pain_behind_the_eyes': ['headache', 'redness_of_eyes', 'blurred_and_distorted_vision', 'nausea'],
    'puffy_face_and_eyes': ['fatigue', 'weight_gain', 'swollen_legs', 'swollen_extremeties'],

    # Joints/Bones
    'joint_pain': ['muscle_pain', 'swelling_joints', 'fatigue', 'high_fever', 'weakness_in_limbs'],
    'swelling_joints': ['joint_pain', 'muscle_pain', 'fatigue', 'painful_walking', 'knee_pain'],
    'knee_pain': ['joint_pain', 'swelling_joints', 'painful_walking', 'muscle_pain'],
    'hip_joint_pain': ['joint_pain', 'painful_walking', 'knee_pain', 'muscle_pain'],
    'painful_walking': ['knee_pain', 'hip_joint_pain', 'joint_pain', 'swelling_joints'],
    'movement_stiffness': ['joint_pain', 'muscle_pain', 'neck_pain', 'back_pain'],
    'back_pain': ['neck_pain', 'weakness_in_limbs', 'muscle_weakness', 'stiff_neck', 'joint_pain'],
    'neck_pain': ['back_pain', 'stiff_neck', 'headache', 'muscle_pain'],
    'stiff_neck': ['neck_pain', 'back_pain', 'headache', 'high_fever'],

    # Liver related
    'yellowing_of_eyes': ['yellowish_skin', 'dark_urine', 'nausea', 'loss_of_appetite', 'abdominal_pain'],
    'yellowish_skin': ['yellowing_of_eyes', 'dark_urine', 'nausea', 'loss_of_appetite', 'itching'],
    'dark_urine': ['yellowing_of_eyes', 'yellowish_skin', 'fatigue', 'loss_of_appetite', 'abdominal_pain'],
    'acute_liver_failure': ['yellowing_of_eyes', 'dark_urine', 'abdominal_pain', 'fatigue', 'nausea'],

    # Urinary
    'burning_micturition': ['continuous_feel_of_urine', 'bladder_discomfort', 'foul_smell_of urine', 'spotting_ urination'],
    'continuous_feel_of_urine': ['burning_micturition', 'bladder_discomfort', 'spotting_ urination'],
    'bladder_discomfort': ['burning_micturition', 'continuous_feel_of_urine', 'foul_smell_of urine'],
    'foul_smell_of urine': ['burning_micturition', 'bladder_discomfort', 'continuous_feel_of_urine'],
    'spotting_ urination': ['burning_micturition', 'continuous_feel_of_urine', 'bladder_discomfort'],
    'polyuria': ['excessive_hunger', 'increased_appetite', 'weight_loss', 'fatigue', 'irregular_sugar_level'],

    # Diabetes/Thyroid
    'excessive_hunger': ['polyuria', 'weight_loss', 'fatigue', 'irregular_sugar_level', 'increased_appetite'],
    'increased_appetite': ['excessive_hunger', 'weight_loss', 'polyuria', 'irregular_sugar_level'],
    'irregular_sugar_level': ['excessive_hunger', 'polyuria', 'fatigue', 'weight_loss', 'increased_appetite'],
    'weight_loss': ['fatigue', 'loss_of_appetite', 'weakness_in_limbs', 'excessive_hunger', 'polyuria'],
    'weight_gain': ['fatigue', 'swollen_legs', 'puffy_face_and_eyes', 'obesity', 'depression'],
    'enlarged_thyroid': ['weight_gain', 'fatigue', 'depression', 'cold_hands_and_feets', 'brittle_nails'],
    'obesity': ['weight_gain', 'fatigue', 'joint_pain', 'breathlessness', 'depression'],

    # Mental/Neurological
    'depression': ['anxiety', 'fatigue', 'irritability', 'lack_of_concentration', 'mood_swings'],
    'anxiety': ['depression', 'restlessness', 'irritability', 'fatigue', 'mood_swings'],
    'mood_swings': ['depression', 'anxiety', 'irritability', 'fatigue', 'restlessness'],
    'irritability': ['depression', 'anxiety', 'mood_swings', 'lack_of_concentration'],
    'lack_of_concentration': ['depression', 'anxiety', 'fatigue', 'irritability', 'mood_swings'],
    'restlessness': ['anxiety', 'depression', 'mood_swings', 'irritability', 'fatigue'],
    'altered_sensorium': ['coma', 'weakness_of_one_body_side', 'slurred_speech', 'loss_of_balance'],
    'slurred_speech': ['weakness_of_one_body_side', 'loss_of_balance', 'altered_sensorium', 'unsteadiness'],
    'weakness_of_one_body_side': ['slurred_speech', 'loss_of_balance', 'altered_sensorium', 'unsteadiness'],
    'coma': ['altered_sensorium', 'weakness_of_one_body_side', 'high_fever', 'loss_of_balance'],

    # Cold/Flu
    'runny_nose': ['congestion', 'continuous_sneezing', 'throat_irritation', 'cough', 'watering_from_eyes'],
    'congestion': ['runny_nose', 'continuous_sneezing', 'sinus_pressure', 'throat_irritation'],
    'continuous_sneezing': ['runny_nose', 'congestion', 'watering_from_eyes', 'throat_irritation'],
    'sinus_pressure': ['congestion', 'headache', 'runny_nose', 'continuous_sneezing'],
    'throat_irritation': ['cough', 'patches_in_throat', 'runny_nose', 'congestion'],
    'patches_in_throat': ['throat_irritation', 'cough', 'high_fever', 'swelled_lymph_nodes'],
    'swelled_lymph_nodes': ['patches_in_throat', 'high_fever', 'fatigue', 'throat_irritation'],
    'loss_of_smell': ['congestion', 'runny_nose', 'continuous_sneezing', 'throat_irritation'],

    # Blood/Circulation
    'swollen_legs': ['swollen_extremeties', 'prominent_veins_on_calf', 'swollen_blood_vessels', 'fatigue'],
    'swollen_extremeties': ['swollen_legs', 'prominent_veins_on_calf', 'fatigue', 'puffy_face_and_eyes'],
    'prominent_veins_on_calf': ['swollen_legs', 'swollen_blood_vessels', 'painful_walking'],
    'swollen_blood_vessels': ['prominent_veins_on_calf', 'swollen_legs', 'bruising'],
    'bruising': ['swollen_blood_vessels', 'fatigue', 'weakness_in_limbs'],
    'cold_hands_and_feets': ['fatigue', 'depression', 'enlarged_thyroid', 'weight_gain'],
    'fluid_overload': ['swollen_legs', 'breathlessness', 'fatigue', 'puffy_face_and_eyes'],

    # Nails
    'brittle_nails': ['enlarged_thyroid', 'fatigue', 'weight_gain', 'depression'],
    'small_dents_in_nails': ['skin_peeling', 'silver_like_dusting', 'inflammatory_nails'],
    'inflammatory_nails': ['small_dents_in_nails', 'joint_pain', 'skin_rash'],

    # Other
    'dehydration': ['vomiting', 'diarrhoea', 'fatigue', 'sunken_eyes', 'dark_urine'],
    'sunken_eyes': ['dehydration', 'fatigue', 'weight_loss', 'dark_urine'],
    'ulcers_on_tongue': ['throat_irritation', 'patches_in_throat', 'high_fever'],
    'drying_and_tingling_lips': ['dehydration', 'sunken_eyes', 'fatigue'],
    'toxic_look_(typhos)': ['high_fever', 'fatigue', 'nausea', 'vomiting', 'weakness_in_limbs'],
    'belly_pain': ['abdominal_pain', 'stomach_pain', 'nausea', 'cramps'],
    'cramps': ['belly_pain', 'abdominal_pain', 'muscle_pain', 'fatigue'],
    'family_history': ['obesity', 'weight_gain', 'depression', 'anxiety'],
    'history_of_alcohol_consumption': ['nausea', 'vomiting', 'abdominal_pain', 'fatigue', 'yellowish_skin'],
    'receiving_blood_transfusion': ['fatigue', 'weakness_in_limbs', 'high_fever'],
    'receiving_unsterile_injections': ['high_fever', 'fatigue', 'weakness_in_limbs'],
    'extra_marital_contacts': ['burning_micturition', 'skin_rash', 'fatigue'],
    'loss_of_smell': ['congestion', 'runny_nose', 'continuous_sneezing'],
    'internal_itching': ['itching', 'skin_rash', 'yellowing_of_eyes', 'dark_urine'],
    'swelling_of_stomach': ['distention_of_abdomen', 'abdominal_pain', 'nausea', 'vomiting'],
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