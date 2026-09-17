# 1. Namespace para la aplicación Django
resource "kubernetes_namespace" "app" {
  metadata {
    name = "devops-django"
    labels = {
      environment = "local"
      managed_by  = "terraform"
    }
  }
}

# 2. Namespace para el stack de observabilidad
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      environment = "local"
      managed_by  = "terraform"
    }
  }
}

# 3. Secretos de infraestructura gestionados por Terraform
resource "kubernetes_secret" "django_secrets" {
  metadata {
    name      = "django-core-secrets"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    DJANGO_SECRET_KEY = "django-insecure-terraform-local-key"
    CELERY_BROKER_URL = "amqp://guest:guest@rabbitmq-service:5672//"
    REDIS_URL         = "redis://redis-service:6379/0"
  }

  type = "Opaque"
}

# 4. Despliegue automatizado de Kube-Prometheus-Stack (Prometheus + Grafana)
resource "helm_release" "prometheus_stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "grafana.adminUser"
    value = var.grafana_admin_user
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  # Evita bloqueos en máquinas locales deshabilitando validaciones innecesarias
  set {
    name  = "prometheusOperator.admissionWebhooks.enabled"
    value = "false"
  }

  depends_on = [kubernetes_namespace.monitoring]
}