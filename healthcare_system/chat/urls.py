from django.urls import path
from .views import MyRoomsView, MarkReadView, UploadFileView

urlpatterns = [
    path('rooms/',
         MyRoomsView.as_view()),
    path('rooms/<int:room_id>/read/',
         MarkReadView.as_view()),
    path('upload/',
         UploadFileView.as_view()),
]