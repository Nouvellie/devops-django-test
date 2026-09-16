from django.urls import path
from api.views import health_check, trigger_task

urlpatterns = [
    path('health/', health_check, name='health_check'),
    path('trigger/', trigger_task, name='trigger_task'),
]