from django.http import JsonResponse
from .models import Hospital, Pharmacy
import math


# Haversine function
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # km

    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)

    a = (math.sin(d_lat/2) ** 2 +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) *
         math.sin(d_lon/2) ** 2)

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


# Hospitals API
def get_nearby_hospitals(request):
    user_lat = float(request.GET.get("lat"))
    user_lng = float(request.GET.get("lng"))

    hospital_list = []

    for h in Hospital.objects.exclude(latitude=None, longitude=None):

        distance = haversine(user_lat, user_lng, h.latitude, h.longitude)

        map_link = f"https://www.google.com/maps/dir/?api=1&destination={h.latitude},{h.longitude}"

        hospital_list.append({
            "name": h.name,
            "address": h.address,
            "distance_km": round(distance, 2),
            "map_link": map_link
        })

    hospital_list.sort(key=lambda x: x["distance_km"])

    return JsonResponse({"hospitals": hospital_list})


# Pharmacies API
def get_nearby_pharmacies(request):
    user_lat = float(request.GET.get("lat"))
    user_lng = float(request.GET.get("lng"))

    pharmacy_list = []

    for p in Pharmacy.objects.exclude(latitude=None, longitude=None):

        distance = haversine(user_lat, user_lng, p.latitude, p.longitude)

        map_link = f"https://www.google.com/maps/dir/?api=1&destination={p.latitude},{p.longitude}"

        pharmacy_list.append({
            "name": p.name,
            "address": p.address,
            "distance_km": round(distance, 2),
            "map_link": map_link
        })

    pharmacy_list.sort(key=lambda x: x["distance_km"])

    return JsonResponse({"pharmacies": pharmacy_list})