from django.urls import path
from .views import NearbyHospitalsView, NearbyPharmaciesView

urlpatterns = [
    path('nearby/',     NearbyHospitalsView.as_view()),
    path('pharmacies/', NearbyPharmaciesView.as_view()),
]