# Production-Grade DevOps Django API, Kubernetes & Terraform Infrastructure

[![CI Pipeline](https://github.com/your-username/devops-django-api/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/devops-django-api/actions)
[![Kubernetes](https://img.shields.io/badge/kubernetes-v1.30-blue.svg)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/terraform-AWS%20EKS-purple.svg)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/python-3.12%20%7C%203.14-blue.svg)](https://www.python.org/)

An enterprise-grade, event-driven REST API engineered with **Django REST Framework**, containerized with **Docker**, orchestrated across **Docker Compose** and **Kubernetes (Kind & AWS EKS)**, and provisioned declaratively using **Terraform**. Built with asynchronous execution via **Celery** and **RabbitMQ**, key-value caching with **Redis**, reverse proxy routing with **Nginx**, and full-spectrum telemetry powered by **Prometheus**, **Loki**, **Promtail/Alloy**, and **Grafana**.

---

## 1. System Architecture

The infrastructure implements a decoupled, event-driven architecture isolating compute-heavy background workloads from the synchronous HTTP request-response cycle, backed by automated cloud provisioning and telemetry.

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
                            ▲
                            │ Provisions & Manages AWS EKS / VPC
                            │
┌─────────────────────────────────────────────────────────┐
│               Terraform Infrastructure as Code          │
│   [ VPC Module ] ──► [ AWS EKS Cluster ] ──► [ Nodes ]  │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Technical Stack Matrix

| Architectural Layer | Technologies | Core Functionality |
| :--- | :--- | :--- |
| **Application Runtime** | Python, Django, DRF, Gunicorn | Synchronous REST endpoints, serialization, WSGI process model. |
| **Asynchronous Engine** | Celery, RabbitMQ, Redis | AMQP message broker, background task workers, in-memory state store. |
| **Worker Telemetry** | Celery Flower | Broker inspection, task lifecycle tracking, worker health metrics. |
| **Routing & Ingress** | Nginx, Nginx Ingress Controller | Static asset handling, reverse proxy, path-based load routing. |
| **Metrics Pipeline** | Prometheus, `django-prometheus`, cAdvisor | Pull-based metrics scraping, container runtime resource tracking. |
| **Log Management** | Grafana Loki, Promtail, Grafana Alloy | Docker stdout/stderr collection, label indexing, LogQL stream engine. |
| **Alerting & Dashboards**| Grafana, Alertmanager | Unified metrics visualization (Dashboard ID: `9528`), threshold alerting. |
| **Local Orchestration** | Docker Compose, Kind | Local multi-container dev, cluster emulation with ingress mappings. |
| **Cluster Autoscaling** | Kubernetes HPA (v2), Metrics Server | Automatic pod scaling based on CPU (70%) and Memory (80%) thresholds. |
| **Cloud Provisioning** | Terraform (AWS Provider, VPC, EKS) | Declarative cloud IaC for VPC networks, subnets, and EKS clusters. |
| **Testing & CI/CD** | Pytest, GitHub Actions, Docker Buildx | Automated linting, test suites, multi-arch container compilation. |

---

## 3. Repository Structure

```text
.
├── .github/workflows/ci.yml           # Automated Pytest suite & Docker Buildx pipeline
├── core/                              # Django project configuration (settings, wsgi, celery)
├── api/                               # Primary DRF app (tasks, views, urls, serializers)
├── k8s/                               # Declarative Kubernetes blueprints
│   ├── 00-namespace.yaml              # Dedicated namespace (devops-django)
│   ├── 01-config.yaml                 # ConfigMaps and Base64 operational Secrets
│   ├── 02-infrastructure.yaml         # Redis & RabbitMQ Deployments, Services, and PVCs
│   ├── 03-django-api.yaml             # Django Gunicorn API deployment with migration initContainer
│   ├── 04-celery-worker.yaml          # Asynchronous Celery worker deployment
│   ├── 05-ingress.yaml                # Ingress routing rules mapping root (/) and /flower
│   ├── 06-hpa-django.yaml             # Horizontal Pod Autoscaler for Django API (Min: 2, Max: 4)
│   └── 07-hpa-celery.yaml             # Horizontal Pod Autoscaler for Celery Worker (Min: 2, Max: 4)
├── nginx/                             # Docker Compose reverse-proxy configurations
│   └── default.conf                   # Upstream routing to Gunicorn
├── observability/                 # Prometheus targets, alerting rules, and log pipelines
│   ├── prometheus/prometheus.yml      # Scrape configurations
│   ├── loki/loki-config.yaml          # Log ingestion and retention definitions
│   ├── promtail/promtail-config.yaml  # Docker socket harvesting and pipeline stages
│   └── grafana/provisioning/          # Auto-provisioned datasources and dashboards
├── terraform/                         # Enterprise Infrastructure as Code (AWS)
│   ├── versions.tf                    # Terraform, AWS, and Kubernetes provider constraints
│   ├── vpc.tf                         # VPC topology, subnets, NAT Gateways, and route tables
│   ├── eks.tf                         # AWS EKS cluster, node groups, and IAM roles
│   ├── variables.tf                   # Parameterized inputs (regions, CIDR blocks, node types)
│   └── outputs.tf                     # EKS endpoints, cluster name, and kubeconfig command
├── tests/                             # Pytest suite isolating HTTP and task dispatching
├── docker-compose.yml                 # Local multi-container development environment
├── Dockerfile                         # Production multi-stage container definition
├── kind-config.yaml                   # Kind cluster config with hostPort 80/443 mappings
└── requirements.txt                   # Pinned application dependencies
```

---

## 4. Phase-by-Phase Operational Runbook

### Phase 1: Local Django & Docker Foundation

```bash
# 1. Initialize project structure
django-admin startproject core .
python manage.py startapp api

# 2. Freeze Python dependencies
pip freeze > requirements.txt

# 3. Build and test container isolation
docker build -t devops-django:latest .
docker run -d --name test-django -p 8000:8000 devops-django:latest

# 4. Clean up test container
docker rm -f test-django
```

---

### Phase 2: Docker Compose Multi-Container Orchestration

```bash
# 1. Launch web, proxy, and message brokers in detached mode
docker compose up --build -d

# 2. Verify runtime container health
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

### Phase 7: Cloud Provisioning with Terraform (AWS EKS)

The `terraform/` directory transitions the declarative architecture from local Kind clusters to a production AWS environment.

#### 1. Terraform Core Definitions

**`terraform/versions.tf`**
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

**`terraform/variables.tf`**
```hcl
variable "aws_region" {
  description = "Target AWS deployment region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS Cluster identifier"
  type        = string
  default     = "devops-django-eks"
}

variable "vpc_cidr" {
  description = "Base VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}
```

**`terraform/vpc.tf`**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
```

**`terraform/eks.tf`**
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    workers = {
      min_size     = 2
      max_size     = 5
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
}
```

**`terraform/outputs.tf`**
```hcl
output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "CLI command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name${module.eks.cluster_name}"
}
```

#### 2. Provisioning & Connecting to EKS
```bash
cd terraform

# Initialize providers and download modules
terraform init

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan

# Provision AWS VPC and EKS infrastructure
terraform apply -auto-approve

# Configure local kubectl to point to the new AWS EKS cluster
aws eks update-kubeconfig --region us-east-1 --name devops-django-eks

# Verify cluster connectivity
kubectl get nodes
```

#### 3. Deploy Application Blueprints to EKS
Once connected to EKS, apply the existing manifests directly to the cloud cluster:
```bash
cd ..

# Deploy AWS Load Balancer Controller or Ingress Controller
kubectl apply -f [https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml](https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml)

# Apply the application stack to EKS
kubectl apply -f k8s/
```

---

### Phase 8: Verification & Telemetry Inspection

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

### Phase 9: Zero-Downtime Rolling Update Pipeline

Execute this workflow to push code updates to the cluster without dropping requests:

```bash
# 1. Compile the updated container image
docker build -t devops-django-web:latest .

# 2. Sideload into Kind (or push to AWS ECR for EKS deployments)
kind load docker-image devops-django-web:latest --name devops-cluster
# For AWS: docker tag devops-django-web:latest <ECR_URL>:latest && docker push <ECR_URL>:latest

# 3. Trigger a rolling restart of the deployment
kubectl rollout restart deployment/django-api

# 4. Monitor rollout status in real time
kubectl rollout status deployment/django-api
```

---

### Phase 10: Teardown & Resource Decommissioning

```bash
# 1. Destroy Docker Compose containers, networks, and persistent storage volumes
docker compose down -v

# 2. Terminate background port-forward daemons
pkill -f "port-forward"

# 3. Delete the local Kind Kubernetes cluster
kind delete cluster --name devops-cluster

# 4. Destroy AWS cloud infrastructure provisioned by Terraform
cd terraform
terraform destroy -auto-approve
```