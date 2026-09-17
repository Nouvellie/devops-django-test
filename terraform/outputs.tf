output "app_namespace" {
  description = "Namespace creado para Django"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "monitoring_namespace" {
  description = "Namespace creado para Prometheus y Grafana"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_access_info" {
  description = "Comando para acceder a Grafana una vez aprovisionado"
  value       = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/prometheus-stack-grafana 3000:80"
}