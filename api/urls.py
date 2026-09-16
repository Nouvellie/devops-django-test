from django.urls import path
from .views import health_check, trigger_task

urlpatterns = [
    path("health/", health_check, name="health_check"),
    path("task/", trigger_task, name="trigger_task"),
]