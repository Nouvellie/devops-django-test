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

# Prometheus 
add on settings/urls ("")
## Access
localhost/metrics

# Folders (prometheus, loki, promptail and grafana)
mkdir -p prometheus loki promtail grafana/provisioning/datasources
## YMLs
prometheus/prometheus.yml
loki/loki-config.yaml
promtail/promtail-config.yaml
grafana/provisioning/datasources/datasources.yaml

# Docker compose (prometheus, loki, promptail and grafana)
update docker-compose.yml

# Check
repeat 5 curl -s -X POST http://localhost/api/trigger/ -w "\n"
## Check Enpoint and status UP
http://localhost:9090/targets
## Grafana
http://localhost:3000
## Grafana/explore/prometheus
django_http_requests_total_by_transport_total
## Grafana/explore/loki (gunicorn terminal)
{container="django_web"}

[ Django API ]
     │
     ├──> expone números en /metrics ────> (Prometheus hace PULL y los guarda) ──┐
     │                                                                           │
     └──> imprime texto en la terminal                                            ▼
              │                                                              [ Grafana ]
              ▼                                                              (Muestra
     [ Docker logs ]                                                          ambos en
              │                                                              un panel)
              ▼                                                                  ▲
     (Promtail lee los logs y los envía) ──> [ Loki los indexa y guarda ] ───────┘

## Grafana/explorer/prometheus (request/sec last 2 min)
rate(django_http_requests_total_by_transport_total[2m])
## Grafana/explorer/prometheus (Get fail rate)
django_http_responses_total_by_status_name_total
## Grafana/explorer/prometheus (Client real latency)
django_http_requests_latency_including_middlewares_seconds_bucket
## Grafana/explorer/prometheus (Most used endpoint)
django_http_requests_total_by_view_transport_method_total
## Grafana/explorer/prometheus (Real RAM use)
process_resident_memory_bytes
## Grafana/explorer/prometheus (Real CPU use)
process_cpu_seconds_total
## Grafana/explore/loki (Celery task lived)
{container="celery_worker"} |= "Task"
## Grafana/explore/loki (Failed Celery tasks)
{container="celery_worker"} |= "failed"
## Grafana/explore/loki (Django statuscode 500)
{container="django_web"} |= "500"
## Grafana/explore/loki (Success-tasks/min)
count_over_time({container="celery_worker"} |= "succeeded"[1m])

# Grafana (django-dashboard)
http://localhost:3000/dashboards
new --> import --> 9528 

# Kubernetes
mkdir -p k8s
k8s/01-config.yaml
k8s/02-infrastructure.yaml
k8s/03-django-api.yaml
k8s/04-celery-worker.yaml
k8s/05-ingress.yaml
k8s/06-hpa-django.yaml
k8s/07-hpa-celery.yaml

# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
## Once NIC is ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Metric server fix (must be)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
## Check
kubectl top nodes

# Kind creation
```
cat << 'EOF' > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

# Stop docker containers
docker compose down

# Start k8s
kind create cluster --config kind-config.yaml