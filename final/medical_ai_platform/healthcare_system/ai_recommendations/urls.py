from django.urls import path
from .views import PredictDiseaseView, FullRecommendationView

urlpatterns = [
    path('predict/', PredictDiseaseView.as_view(), name='predict_disease'),
    path('recommend/', FullRecommendationView.as_view(), name='full_recommendation'),
]