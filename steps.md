# Create project 
django-admin startproject core .

# Create api v1
only urls/views file

# Prometheus 
add on settings/urls ("")
## Access
localhost/metrics

# Create Dockerfile
only for django proyect

# Req file
pip freeze > requirements.txt

# Test Dockerfile
docker build -t devops-django:latest .
docker run -d --name test-django -p 8000:8000 devops-django:latest

# If container error
docker rm -f test-django