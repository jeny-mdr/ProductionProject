from django.urls import path
from .views import predict_disease, full_recommendation

urlpatterns = [
    path('predict/', predict_disease),
    path('full/', full_recommendation),
]