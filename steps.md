# Create project 
django-admin startproject core .

# Create api v1
only urls/views file

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
- Create core/celery.py
- Create api/tasks.py
- Update api/views.py
- Update core/init.py
- Update core/settings.py

# Docker compose (Flower)
RabbitMQ monitor
update docker-compose.yml

# Docker Build
docker compose up --build -d

# Flower check
localhost:5555

# Check errors
docker compose logs --tail=50 web


# Prometheus 
add on settings/urls ("")
## Access
localhost/metrics