import time
from celery import shared_task

@shared_task
def test_async_task():
    """Simulate a background workload execution."""
    time.sleep(3)
    return "Task completed successfully!"