# api/views.py
from rest_framework.response import Response
from rest_framework.decorators import api_view
from celery.result import AsyncResult
from api.tasks import test_async_task

@api_view(["GET"])
def health_check(request):
    return Response({"status": "healthy", "service": "django-api"})

@api_view(["POST"])
def trigger_task(request):
    task = test_async_task.delay()
    return Response({"task_id": task.id, "status": "enqueued"}, status=202)

@api_view(["GET"])
def task_status(request, task_id):
    """Fetch the status and outcome of an async Celery task from Redis."""
    task_result = AsyncResult(task_id)
    
    response_data = {
        "task_id": task_id,
        "status": task_result.status,        # PENDING, STARTED, SUCCESS, FAILURE, etc.
        "ready": task_result.ready(),         # True if finished (either success or failure)
        "result": str(task_result.result) if task_result.failed() else task_result.result,
    }
    return Response(response_data)