from django.urls import path
from .views import (
    FullRecommendationView,
    PredictDiseaseView,
    SymptomListView,
    SymptomSuggestionsView,
)

urlpatterns = [
    path('recommend/', FullRecommendationView.as_view()),
    path('predict/',   PredictDiseaseView.as_view()),
    path('symptoms/',  SymptomListView.as_view()),
    path('suggest/',   SymptomSuggestionsView.as_view()),
]