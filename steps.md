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

# Create Nginx
nginx/default.conf

# Docker compose (nginx)
update docker-compose.yml

# Docker Build
docker compose up --build -d

# Docker check
docker ps

# Check app
localhost:80 / localhost

# Docker compose (Redis/RabbitMQ)
update docker-compose.yml

# Docker Build
docker compose up --build -d

# Docker check
docker ps

# Reset volume if guest/guest error 
docker compose down -v
docker compose down
docker compose up --build -d

# Check RabbitMQ
localhost:15672

# Docker compose (celery)
update docker-compose.yml

# Celery
- Create celery.py
- Update init.py
- Update settings.py

# Docker compose (Flower)
RabbitMQ monitor
update docker-compose.yml

# Docker Build
docker compose up --build -d
