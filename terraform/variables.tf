variable "kube_context" {
  description = "Contexto de Kubernetes a apuntar (por defecto el de Kind)"
  type        = string
  default     = "kind-kind"
}

variable "grafana_admin_user" {
  description = "Usuario administrador para Grafana"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Contraseña para el usuario admin de Grafana"
  type        = string
  default     = "adminpassword123"
  sensitive   = true
}