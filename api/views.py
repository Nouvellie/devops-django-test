# api/views.py
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from celery.result import AsyncResult
from api.tasks import test_async_task

class HealthCheckView(APIView):
    def get(self, request):
        return Response({"status": "healthy", "service": "django-api"})

class TriggerTaskView(APIView):
    def post(self, request):
        task = test_async_task.delay()
        return Response(
            {"task_id": task.id, "status": "enqueued"}, 
            status=status.HTTP_202_ACCEPTED
        )

class TaskStatusView(APIView):
    def get(self, request, task_id):
        task_result = AsyncResult(task_id)
        return Response({
            "task_id": task_id,
            "status": task_result.status,
            "ready": task_result.ready(),
            "result": str(task_result.result) if task_result.failed() else task_result.result,
        }, status=status.HTTP_200_OK)