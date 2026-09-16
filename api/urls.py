# api/urls.py
from django.urls import path
from api.views import HealthCheckView, TriggerTaskView, TaskStatusView

urlpatterns = [
    path('health/', HealthCheckView.as_view(), name='health_check'),
    path('trigger/', TriggerTaskView.as_view(), name='trigger_task'),
    path('status/<str:task_id>/', TaskStatusView.as_view(), name='task_status'),
]