from django.urls import path
from .views import MyRoomsView, MarkReadView

urlpatterns = [
    path('rooms/', MyRoomsView.as_view(), name='my_rooms'),
    path('rooms/<int:room_id>/read/', MarkReadView.as_view(), name='mark_read'),
]