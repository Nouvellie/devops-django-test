# Complete Production-Grade Django DevOps & Kubernetes Deployment Guide

A comprehensive, end-to-end operational guide for building, containerizing, monitoring, and orchestrating a production-grade Django stack (Django, Celery, Redis, RabbitMQ, Flower, Prometheus, Loki, Promtail, Grafana) across both Docker Compose and Kubernetes (Kind).

---

## Table of Contents
1. [Phase 1: Local Django & Docker Foundation](#phase-1-local-django--docker-foundation)
2. [Phase 2: Docker Compose Core Stack](#phase-2-docker-compose-core-stack)
3. [Phase 3: Asynchronous Tasks with Celery & Flower](#phase-3-asynchronous-tasks-with-celery--flower)
4. [Phase 4: Observability with Prometheus, Loki & Grafana](#phase-4-observability-with-prometheus-loki--grafana)
5. [Phase 5: Kubernetes Migration via Kind](#phase-5-kubernetes-migration-via-kind)
6. [Phase 6: Ingress, Metrics Server & Horizontal Pod Autoscaling](#phase-6-ingress-metrics-server--horizontal-pod-autoscaling)
7. [Phase 7: Production-Grade Monitoring in Kubernetes (Helm)](#phase-7-production-grade-monitoring-in-kubernetes-helm)
8. [Phase 8: Zero-Downtime Code Update Workflow](#phase-8-zero-downtime-code-update-workflow)

---

## Phase 1: Local Django & Docker Foundation

### 1. Initialize the Django Project
```bash
# Initialize Django project in the current working directory
django-admin startproject core .

# Create the primary API application
python manage.py startapp api
```
*Configure a modular structure by creating dedicated `api/urls.py` and implementing business endpoints in `api/views.py`.*

### 2. Freeze Dependencies & Build Dockerfile
Create a production-ready `Dockerfile` in the project root:
```bash
# Freeze environment dependencies
pip freeze > requirements.txt

# Build the base Django Docker image
docker build -t devops-django:latest .

# Run a test container to verify startup
docker run -d --name test-django -p 8000:8000 devops-django:latest

# Remove the test container after verification
docker rm -f test-django
```

---

## Phase 2: Docker Compose Core Stack

### 1. Nginx Reverse Proxy Setup
Create `nginx/default.conf` to handle incoming reverse proxy traffic to Gunicorn on port `8000`.

### 2. Define Infrastructure Services
Add `web`, `nginx`, `redis`, and `rabbitmq` services into `docker-compose.yml`.

```bash
# Build and run the core infrastructure in detached mode
docker compose up --build -d

# Verify container runtime status
docker ps
```

* **Application Endpoint:** `http://localhost` (Port 80)
* **RabbitMQ Management Dashboard:** `http://localhost:15672` (Default credentials: `guest`/`guest`)

> **Volume Reset Note:** If RabbitMQ encounters authentication or storage permission conflicts, execute a full volume purge:
> ```bash
> docker compose down -v
> docker compose up --build -d
> ```

---

## Phase 3: Asynchronous Tasks with Celery & Flower

### 1. Celery Architecture Setup
Create and configure the required application files:
* `core/celery.py`: Celery instance initialization and autodiscovery.
* `core/__init__.py`: Import Celery app on project startup.
* `core/settings.py`: Configure `CELERY_BROKER_URL` and `CELERY_RESULT_BACKEND`.
* `api/tasks.py`: Define long-running background tasks.
* `api/views.py`: Expose task trigger (`/api/trigger/`) and status polling (`/api/status/<task_id>/`) endpoints.

### 2. Integrate Workers & Flower Dashboard
Update `docker-compose.yml` to include `celery_worker` and `celery_flower`.

```bash
# Rebuild and run with asynchronous worker services
docker compose up --build -d

# Check live logs for task execution
docker compose logs --tail=50 -f web celery_worker
```

* **Flower Monitoring Interface:** `http://localhost:5555`
* **Restart Flower (if worker discovery hangs):**
  ```bash
  docker compose restart flower
  ```

### 3. Task Execution & Polling Verification
```bash
# Dispatch 5 asynchronous background tasks
for i in {1..5}; do curl -s -X POST http://localhost/api/trigger/ -w "\n"; done

# Check specific task execution status
curl -s http://localhost/api/status/<TASK_ID>/ -w "\n"
```

---

## Phase 4: Observability with Prometheus, Loki & Grafana

### 1. Directory Structure Setup
```bash
# Create configuration directories
mkdir -p prometheus loki promtail grafana/provisioning/datasources
```

Create configuration files:
* `prometheus/prometheus.yml`: Scrapes metrics from `web:8000/metrics`.
* `loki/loki-config.yaml`: Ingestion and storage configuration for container logs.
* `promtail/promtail-config.yaml`: Scrapes Docker container JSON logs and pushes to Loki.
* `grafana/provisioning/datasources/datasources.yaml`: Auto-provisions Prometheus and Loki datasources.

### 2. Observability Architecture Flow
```text
[ Django API ]
     │
     ├──> Exposes raw metrics at /metrics ──> [ Prometheus ] (Pulls & Stores) ──┐
     │                                                                           │
     └──> Writes stdout/stderr text logs                                         ▼
              │                                                             [ Grafana ]
              ▼                                                             (Unified UI)
     [ Docker Daemon Logs ]                                                      ▲
              │                                                                  │
              ▼                                                                  │
         [ Promtail ] ───> Sends streams ───> [ Loki ] (Indexes & Stores) ───────┘
```

### 3. Launch Observability Stack
Add Prometheus, Loki, Promtail, Grafana, and cAdvisor to `docker-compose.yml`:
```bash
docker compose up --build -d
```
* **Prometheus Targets Dashboard:** `http://localhost:9090/targets`
* **Grafana Interface:** `http://localhost:3000` (Default: `admin`/`admin`)
* **cAdvisor Container Metrics:** `http://localhost:8080`

### 4. Essential PromQL & LogQL Queries

#### PromQL (Prometheus Metrics)
* **Request Rate (last 2 minutes):**
  ```promql
  rate(django_http_requests_total_by_transport_total[2m])
  ```
* **HTTP Failure Rate by Status:**
  ```promql
  django_http_responses_total_by_status_name_total
  ```
* **Real Client Request Latency:**
  ```promql
  django_http_requests_latency_including_middlewares_seconds_bucket
  ```
* **Most Traversed Endpoints:**
  ```promql
  django_http_requests_total_by_view_transport_method_total
  ```
* **Real-time Memory & CPU Consumption:**
  ```promql
  process_resident_memory_bytes
  process_cpu_seconds_total
  ```

#### LogQL (Loki Log Filtering)
* **Track Celery Task Lifecycles:** `{container="celery_worker"} |= "Task"`
* **Filter Failed Background Tasks:** `{container="celery_worker"} |= "failed"`
* **Isolate HTTP 500 Internal Errors:** `{container="django_web"} |= "500"`
* **Successful Tasks per Minute:** `count_over_time({container="celery_worker"} |= "succeeded"[1m])`

> **Grafana Dashboard Setup:** Navigate to `Dashboards > New > Import` and import Community Dashboard ID **`9528`** for instant Django Prometheus analytics.

---

## Phase 5: Kubernetes Migration via Kind

### 1. Teardown Docker Compose
To avoid port conflicts on ports `80` and `443`, stop all running Docker Compose containers:
```bash
docker compose down
```

### 2. Define Cluster Architecture (`kind-config.yaml`)
Create the Kind cluster configuration file with ingress port forward mappings:
```yaml
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
```

### 3. Provision the Local Kubernetes Cluster
```bash
kind create cluster --config kind-config.yaml
```

---

## Phase 6: Ingress, Metrics Server & Horizontal Pod Autoscaling

### 1. Install Nginx Ingress Controller
Deploy the official Kind-tailored Nginx Ingress Controller:
```bash
kubectl apply -f [https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml](https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml)

# Wait until the Ingress Controller pod is completely healthy
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 2. Organize Manifest Directory Structure
```bash
mkdir -p k8s
```
Maintain your declarative Kubernetes manifests:
* `k8s/01-config.yaml`: Environment variables, ConfigMaps, and Secrets.
* `k8s/02-infrastructure.yaml`: Redis and RabbitMQ Deployments, Services, and PVCs.
* `k8s/03-django-api.yaml`: Django API Deployment with DB Migration `initContainers`.
* `k8s/04-celery-worker.yaml`: Celery Worker Deployment.
* `k8s/05-ingress.yaml`: Ingress routing rules mapping `/` to Django and `/flower` to Flower.
* `k8s/06-hpa-django.yaml`: Horizontal Pod Autoscaler for Django API.
* `k8s/07-hpa-celery.yaml`: Horizontal Pod Autoscaler for Celery Worker.

Apply all manifests to the cluster:
```bash
kubectl apply -f k8s/
```

### 3. Deploy & Patch the Metrics Server
To enable resource metrics for `kubectl top` and HPA autoscaling in Kind:
```bash
# Apply official Metrics Server components
kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

# Patch Metrics Server to bypass self-signed TLS restrictions in Kind
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

### 4. Verify Cluster Resource Consumption
```bash
# Check node CPU and Memory consumption
kubectl top nodes

# Check pod resource utilization
kubectl top pods

# Verify HPA target status
kubectl get hpa
```

---

## Phase 7: Production-Grade Monitoring in Kubernetes (Helm)

### 1. Deploy Kube-Prometheus-Stack
Deploy Prometheus Operator, Grafana, and Node Exporter via Helm:
```bash
# Create isolated namespace for monitoring
kubectl create namespace monitoring

# Add Prometheus Community Helm repository
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo update

# Install monitoring stack with predefined admin credentials
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminUser="admin" \
  --set grafana.adminPassword="adminpassword"
```

Verify that all monitoring components are ready:
```bash
kubectl get pods -n monitoring -w
```

### 2. Access Dashboards via Background Port-Forwarding
Run port-forwards silently in the background:
```bash
# Forward Grafana to http://localhost:3000
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80 > /dev/null 2>&1 &

# Forward Flower to http://localhost:5555
kubectl port-forward svc/flower-service 5555:5555 > /dev/null 2>&1 &
```

> **Stop Background Port-Forwards:**
> ```bash
> pkill -f "port-forward"
> ```

---

## Phase 8: Zero-Downtime Code Update Workflow

When making modifications to the Django application code, execute this three-step pipeline to update the live cluster without downtime:

```bash
# 1. Rebuild the local Docker image
docker build -t devops-django-web:latest .

# 2. Side-load the updated image directly into Kind nodes
kind load docker-image devops-django-web:latest

# 3. Trigger a rolling restart of the deployment
kubectl rollout restart deployment/django-api

# 4. Monitor the rolling update progress
kubectl rollout status deployment/django-api
```

---

## Cluster Teardown
To permanently remove the local Kubernetes cluster and clean up all host resources:
```bash
kind delete cluster
```