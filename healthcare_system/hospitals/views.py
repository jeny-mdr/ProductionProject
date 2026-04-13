from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Hospital, Pharmacy
import math


def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (math.sin(d_lat/2) ** 2 +
         math.cos(math.radians(lat1)) *
         math.cos(math.radians(lat2)) *
         math.sin(d_lon/2) ** 2)
    return R * 2 * math.atan2(
        math.sqrt(a), math.sqrt(1 - a))


class NearbyHospitalsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            lat = float(request.GET.get('lat', 27.7172))
            lng = float(request.GET.get('lng', 85.3240))
        except ValueError:
            return Response({"error": "Invalid coordinates"}, status=400)

        hospital_list = []
        for h in Hospital.objects.exclude(
                latitude=None, longitude=None):
            dist = haversine(lat, lng,
                           h.latitude, h.longitude)
            hospital_list.append({
                "name":        h.name,
                "address":     h.address,
                "phone":       h.phone,
                "distance_km": round(dist, 2),
                "latitude":    h.latitude,
                "longitude":   h.longitude,
                "map_link":    f"https://www.google.com/maps/dir/?api=1&destination={h.latitude},{h.longitude}",
            })
        hospital_list.sort(
            key=lambda x: x["distance_km"])
        return Response({"hospitals": hospital_list})


class NearbyPharmaciesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            lat = float(request.GET.get('lat', 27.7172))
            lng = float(request.GET.get('lng', 85.3240))
        except ValueError:
            return Response({"error": "Invalid coordinates"}, status=400)

        pharmacy_list = []
        for p in Pharmacy.objects.exclude(
                latitude=None, longitude=None):
            dist = haversine(lat, lng,
                           p.latitude, p.longitude)
            pharmacy_list.append({
                "name":        p.name,
                "address":     p.address,
                "phone":       p.phone,
                "distance_km": round(dist, 2),
                "latitude":    p.latitude,
                "longitude":   p.longitude,
                "map_link":    f"https://www.google.com/maps/dir/?api=1&destination={p.latitude},{p.longitude}",
            })
        pharmacy_list.sort(
            key=lambda x: x["distance_km"])
        return Response({"pharmacies": pharmacy_list})