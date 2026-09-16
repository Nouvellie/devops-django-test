# api/views.py
from rest_framework.response import Response
from rest_framework.decorators import api_view
from api.tasks import test_async_task

@api_view(["GET"])
def health_check(request):
    return Response({"status": "healthy", "service": "django-api"})

@api_view(["POST"])
def trigger_task(request):
    # Dispatch background task to RabbitMQ
    task = test_async_task.delay()
    return Response({"task_id": task.id, "status": "enqueued"}, status=202)