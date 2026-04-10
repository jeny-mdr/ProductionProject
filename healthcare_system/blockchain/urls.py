from django.urls import path
from .views import (
    SavePrescriptionView,
    MyPrescriptionsView,
    VerifyChainView,
    DoctorVerificationHashView,
)

urlpatterns = [
    path('prescriptions/save/',
         SavePrescriptionView.as_view()),
    path('prescriptions/mine/',
         MyPrescriptionsView.as_view()),
    path('verify/',
         VerifyChainView.as_view()),
    path('verify-doctor/',
         DoctorVerificationHashView.as_view()),
]