from django.urls import path
from .views import (
    PredictDiseaseView,
    FullRecommendationView,
    SymptomListView,
)

urlpatterns = [
    path('predict/',   PredictDiseaseView.as_view(),
         name='predict_disease'),
    path('recommend/', FullRecommendationView.as_view(),
         name='full_recommendation'),
    path('symptoms/',  SymptomListView.as_view(),
         name='symptom_list'),
]