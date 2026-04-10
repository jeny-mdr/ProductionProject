from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/ai/', include('ai_recommendations.urls')),
    path('api/chat/', include('chat.urls')),
    # hospitals app urls
    # path('api/hospitals/', include('hospitals.urls')),
]