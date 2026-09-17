# Production-Grade DevOps Django API & Kubernetes Infrastructure

[![CI Pipeline](https://github.com/your-username/devops-django-api/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/devops-django-api/actions)
[![Kubernetes](https://img.shields.io/badge/kubernetes-v1.30-blue.svg)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/terraform-AWS%20EKS-purple.svg)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/python-3.12%20%7C%203.14-blue.svg)](https://www.python.org/)

An enterprise-grade, event-driven REST API engineered with **Django REST Framework**, containerized with **Docker**, and orchestrated across **Docker Compose**, **Kubernetes (Kind)**, and **Terraform (AWS EKS)**. Built with asynchronous task execution via **Celery** and **RabbitMQ**, caching through **Redis**, ingress routing via **Nginx**, and full-spectrum telemetry powered by **Prometheus**, **Loki**, **Promtail/Alloy**, and **Grafana**.

---

## 1. System Architecture

The infrastructure implements a decoupled, event-driven pattern isolating synchronous HTTP transactions from compute-heavy background processing, backed by a unified telemetry pipeline.

```text
                                    ┌─────────────────────────────────────────────────────────────┐
                                    │               Unified Observability Pipeline                │
                                    │                                                             │
                                    │   [ cAdvisor ] ─────────┐                                   │
                                    │                         ▼                                   │
                                    │   [ Promtail / ───► [ Loki ] ─────► [ Grafana ]             │
                                    │       Alloy ]       (Port :3100)      (Port :3000)          │
                                    │     (Log Stream)                           ▲                │
                                    │                                            │                │
                                    │   [ Prometheus ] ──────────────────────────┤                │
                                    │     (Port :9090)                           ▼                │
                                    │          │                          [ Alertmanager ]        │
                                    │          ▼                            (Port :9093)          │
                                    └──────────┼──────────────────────────────────────────────────┘
                                               │
                                 Scrapes /metrics on :8000
                                               │
[ Client / Web Traffic ]                       │
          │                                    │
          │ (HTTP :80 / HTTPS :443)            │
          ▼                                    │
┌─────────────────────────┐                    │
│   Nginx Ingress / Proxy │                    │
└───────────┬─────────────┘                    │
            │                                  │
            ▼ (Proxy Pass :8000)               │
┌─────────────────────────┐                    │
│   Gunicorn (WSGI)       │                    │
│   ┌───────────────────┐ │                    │
│   │ Django REST API   ├─┴────────────────────┘
│   └─────────┬─────────┘
│             │ (Dispatches Task via AMQP :5672)
│             ▼
│       [ RabbitMQ ] ◄────────────── [ Flower Monitoring ]
│     (Broker - :15672)                     (Port :5555)
│             │
│             │ (Consumes Task via Persistent TCP)
│             ▼
│       [ Celery Worker ]
│             │
│             │ (Writes Task Results & State)
│             ▼
│         [ Redis ] (Result Backend & Cache - Port :6379)
└─────────────────────────────────────────────────────────┘
```

---

## 2. Technical Stack Matrix

| Architectural Layer | Technologies | Core Functionality |
| :--- | :--- | :--- |
| **Application Runtime** | Python, Django, DRF, Gunicorn | Synchronous REST endpoints, serialization, WSGI process model. |
| **Asynchronous Engine** | Celery, RabbitMQ, Redis | AMQP message broker, asynchronous task workers, key-value state store. |
| **Worker Monitoring** | Celery Flower | Real-time broker inspection, task lifecycle auditing, worker stats. |
| **Ingress & Gateway** | Nginx, Nginx Ingress Controller | Reverse proxying, TLS termination, path routing, upstream keepalive. |
| **Metrics Telemetry** | Prometheus, `django-prometheus`, cAdvisor | Pull-based time-series scraping, container runtime metrics. |
| **Log Aggregation** | Grafana Loki, Promtail, Grafana Alloy | Docker stdout/stderr collection, label indexing, LogQL stream queries. |
| **Visualization & Alerts** | Grafana, Alertmanager | Unified dashboards (ID: `9528`), Prometheus/Loki query correlation. |
| **Local Orchestration** | Docker Compose, Kind (Kubernetes-in-Docker) | Multi-container composition, local cluster emulation with ingress mappings. |
| **Cluster Autoscaling** | Kubernetes HPA (v2), Metrics Server | Dynamic pod scaling targeting CPU (70%) and Memory (80%) thresholds. |
| **Infrastructure as Code** | Terraform, Kubernetes Manifests | Declarative AWS EKS cluster, VPC topologies, declarative YAML blueprints. |
| **Testing & CI/CD** | Pytest, GitHub Actions, Docker Buildx | Automated test matrices, linting, multi-platform image compilation. |

---

## 3. Repository Structure

```text
.
├── .github/workflows/ci.yml           # Automated Pytest execution & Docker Buildx matrix
├── core/                              # Django project configuration (settings, wsgi, celery)
├── api/                               # Primary DRF app (tasks, views, urls, serializers)
├── k8s/                               # Declarative Kubernetes manifests
│   ├── 00-namespace.yaml              # Dedicated namespace (devops-django)
│   ├── 01-config.yaml                 # ConfigMaps and Base64 operational Secrets
│   ├── 02-infrastructure.yaml         # Redis & RabbitMQ Deployments, Services, and PVCs
│   ├── 03-django-api.yaml             # Django Gunicorn API deployment with migration initContainer
│   ├── 04-celery-worker.yaml          # Asynchronous worker deployment and execution engine
│   ├── 05-ingress.yaml                # Ingress routing rules mapping root (/) and /flower
│   ├── 06-hpa-django.yaml             # Horizontal Pod Autoscaler for Django API (Min: 2, Max: 4)
│   └── 07-hpa-celery.yaml             # Horizontal Pod Autoscaler for Celery Worker (Min: 2, Max: 4)
├── nginx/                             # Docker Compose reverse-proxy configurations
│   └── default.conf                   # Upstream routing to Gunicorn
├── observability/                     # Prometheus targets, alerting rules, and log pipelines
│   ├── prometheus/prometheus.yml      # Scrape configurations
│   ├── loki/loki-config.yaml          # Ingestion and storage retention definitions
│   ├── promtail/promtail-config.yaml  # Docker socket harvesting and pipeline stages
│   └── grafana/provisioning/          # Auto-provisioned datasources and dashboards
├── terraform/                         # Enterprise cloud provisioning
│   ├── main.tf                        # AWS VPC & EKS cluster module definition (K8s v1.30)
│   ├── variables.tf                   # Parameterized subnet cidrs and instance node groups
│   └── outputs.tf                     # EKS cluster endpoints and kubeconfig outputs
├── tests/                             # Pytest suite isolating HTTP and task dispatching
├── docker-compose.yml                 # Local multi-container development environment
├── Dockerfile                         # Production multi-stage container definition
├── kind-config.yaml                   # Kind cluster config with hostPort 80/443 mappings
└── requirements.txt                   # Pinned application dependencies
```

---

## 4. Phase-by-Phase Operational Runbook

### Phase 1: Local Application & Docker Containerization

```bash
# 1. Initialize project structure
django-admin startproject core .
python manage.py startapp api

# 2. Freeze Python dependencies
pip freeze > requirements.txt

# 3. Build and test container isolation
docker build -t devops-django:latest .
docker run -d --name test-django -p 8000:8000 devops-django:latest

# 4. Verify and clean up container
docker rm -f test-django
```

---

### Phase 2: Docker Compose Multi-Container Orchestration

```bash
# 1. Launch web, proxy, and message brokers in detached mode
docker compose up --build -d

# 2. Check runtime container health
docker compose ps
```

* **API Gateway:** `http://localhost` (Port 80)
* **RabbitMQ Management Dashboard:** `http://localhost:15672` *(Default: `guest` / `guest`)*
* **Flower Interface:** `http://localhost:5555`

```bash
# Recovery Note: In case of RabbitMQ credential/broker cache desynchronization:
docker compose down -v
docker compose up --build -d

# Monitor container runtime output
docker compose logs --tail=50 -f web celery_worker
```

#### Queue Testing & Task Dispatch
```bash
# Dispatch 5 asynchronous test tasks
for i in {1..5}; do curl -s -X POST http://localhost/api/trigger/ -w "\n"; done

# Query specific task execution state
curl -s http://localhost/api/status/<TASK_ID>/ -w "\n"
```

---

### Phase 3: Observability Stack Engineering (Docker Compose)

Deploy Prometheus, Loki, Promtail, Grafana, and cAdvisor:

```bash
# Create local configuration directories
mkdir -p prometheus loki promtail grafana/provisioning/datasources

# Bring up the full observability stack
docker compose up --build -d
```

* **Prometheus Targets Status:** `http://localhost:9090/targets`
* **Grafana Dashboards:** `http://localhost:3000` *(Default: `admin` / `admin`)*
* **cAdvisor Hardware Metrics:** `http://localhost:8080`

#### Telemetry Query Cheat Sheet

##### PromQL (Prometheus)
```promql
# Real-time request rate across the last 2 minutes
rate(django_http_requests_total_by_transport_total[2m])

# Failed responses categorized by HTTP status code
django_http_responses_total_by_status_name_total

# End-to-end client latency distribution
django_http_requests_latency_including_middlewares_seconds_bucket

# Top traversed application endpoints
django_http_requests_total_by_view_transport_method_total

# Memory consumption (Resident Set Size)
process_resident_memory_bytes

# CPU execution time counter
process_cpu_seconds_total
```

##### LogQL (Loki)
```logql
# Track Celery background task lifecycle events
{container="celery_worker"} |= "Task"

# Filter and isolate failed execution runs
{container="celery_worker"} |= "failed"

# Capture HTTP 500 server errors from Django
{container="django_web"} |= "500"

# Successful background task completion rate per minute
count_over_time({container="celery_worker"} |= "succeeded"[1m])
```

> **Grafana Dashboard Setup:** Navigate to `Dashboards > New > Import` and import Community Dashboard ID **`9528`** for instant DRF telemetry.

---

### Phase 4: Kubernetes Local Orchestration via Kind

```bash
# 1. Stop Docker Compose to free ports 80 and 443
docker compose down

# 2. Define kind-config.yaml with ingress-ready node mappings
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

# 3. Create Kind cluster
kind create cluster --name devops-cluster --config kind-config.yaml

# 4. Install Nginx Ingress Controller
kubectl apply -f [https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml](https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml)

# 5. Wait for Ingress Controller initialization
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

---

### Phase 5: Manifest Deployment, Metrics Server & HPA

```bash
# 1. Apply declarative Kubernetes infrastructure
kubectl apply -f k8s/

# 2. Deploy official Metrics Server
kubectl apply -f [https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

# 3. Patch Metrics Server to trust Kind self-signed kubelet certificates
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# 4. Verify pod scheduling and resource tracking
kubectl top nodes
kubectl top pods
kubectl get hpa
```

#### Declarative HPA Configuration Sample (`k8s/06-hpa-django.yaml`)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: django-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: django-api
  minReplicas: 2
  maxReplicas: 4
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

---

### Phase 6: In-Cluster Telemetry via Helm

```bash
# 1. Setup monitoring namespace
kubectl create namespace monitoring

# 2. Add Prometheus Community repository
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo update

# 3. Install Prometheus, Alertmanager, Grafana, and Node Exporters
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminUser="admin" \
  --set grafana.adminPassword="securepassword123"

# 4. Establish persistent background port-forwards
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80 > /dev/null 2>&1 &
kubectl port-forward svc/flower-service 5555:5555 > /dev/null 2>&1 &

# Terminate port forwards when complete
# pkill -f "port-forward"
```

---

### Phase 7: Verification & Testing Suite

```bash
# 1. Health Probe Verification
curl -s http://localhost/api/v1/health/

# Expected Output:
# {"status":"healthy","service":"django-api"}

# 2. Asynchronous Task Dispatch
curl -s -X POST http://localhost/api/v1/task/

# Expected Output:
# {"task_id":"d12b071c-3f41-4775-a83a-3453b3b42a9b","status":"enqueued"}

# 3. Live Worker Inspection
kubectl logs -l app=celery-worker --tail=20 -f

# 4. Inspect container runtimes inside the Kind control-plane node
docker exec -it devops-cluster-control-plane crictl ps

# 5. Run test suite locally and inside container runtime
pytest
docker compose exec web pytest
```

---

### Phase 8: Zero-Downtime Rolling Update Pipeline

Execute this workflow to push code updates to the Kubernetes cluster without dropped requests:

```bash
# 1. Compile the updated container image
docker build -t devops-django-web:latest .

# 2. Sideload the artifact directly into the Kind control-plane node
kind load docker-image devops-django-web:latest --name devops-cluster

# 3. Trigger a rolling restart of the deployment
kubectl rollout restart deployment/django-api

# 4. Monitor rollout status in real time
kubectl rollout status deployment/django-api
```

---

## 5. Infrastructure as Code (Terraform AWS EKS)

The `terraform/` directory provisions production AWS cloud topologies:
* **VPC:** 2 Availability Zones with dedicated public and private subnet tiers.
* **Gateways:** Single NAT Gateway for cost-effective private egress routing.
* **EKS Cluster:** Managed Kubernetes `v1.30` with an auto-scaling Node Group (`t3.medium`, 2 to 5 instances).

```bash
cd terraform

# Initialize providers and modules
terraform init

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan
```

---

## 6. Teardown & Resource Decommissioning

```bash
# 1. Destroy Docker Compose containers, networks, and persistent storage volumes
docker compose down -v

# 2. Terminate background port-forward daemons
pkill -f "port-forward"

# 3. Delete the local Kind Kubernetes cluster
kind delete cluster --name devops-cluster
```