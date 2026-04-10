from django.urls import path
from .views import (
    BookAppointmentView,
    MyAppointmentsView,
    UpdateAppointmentView,
)

urlpatterns = [
    path('book/',
         BookAppointmentView.as_view()),
    path('mine/',
         MyAppointmentsView.as_view()),
    path('<int:pk>/update/',
         UpdateAppointmentView.as_view()),

]