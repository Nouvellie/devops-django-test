# core/celery.py
import os
from celery import Celery

# Set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')

# Initialize the Celery application instance named after the Django core project
app = Celery('core')

# Read configuration from Django settings using the CELERY_ prefix namespace
app.config_from_object('django.conf:settings', namespace='CELERY')

# Automatically discover and register tasks from all installed apps (looks for tasks.py)
app.autodiscover_tasks()