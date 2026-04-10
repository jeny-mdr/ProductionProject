from django.urls import path
from .views import get_nearby_hospitals, get_nearby_pharmacies

urlpatterns = [
    path('nearby/', get_nearby_hospitals),
    path('pharmacies/', get_nearby_pharmacies),
]