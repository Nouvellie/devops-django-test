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
## Restart if there are multiple old ones
docker compose restart flower

# Check errors (web --> docker-compose-name)
docker compose logs --tail=50 web

# Queue check
for i in {1..5}; do curl -s -X POST http://localhost/api/trigger/ -w "\n"; done

# Check queue item status
curl -s http://localhost/api/status/<queue_id>/ -w "\n"