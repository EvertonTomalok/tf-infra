output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.forwarding_rule.ip_address
}

output "load_balancer_url" {
  description = "The URL of the load balancer"
  value       = "http://${google_compute_global_forwarding_rule.forwarding_rule.ip_address}"
}

output "forwarding_rule_name" {
  description = "The name of the forwarding rule"
  value       = google_compute_global_forwarding_rule.forwarding_rule.name
}

output "backend_service_name" {
  description = "The name of the backend service"
  value       = google_compute_backend_service.backend_service.name
}

