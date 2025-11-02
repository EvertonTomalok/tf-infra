output "load_balancer_ip" {
  description = "The IP address of the load balancer (prefers HTTPS IP if available)"
  value       = length(google_compute_global_forwarding_rule.https_forwarding_rule) > 0 ? google_compute_global_forwarding_rule.https_forwarding_rule[0].ip_address : google_compute_global_forwarding_rule.forwarding_rule.ip_address
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

output "backend_service_id" {
  description = "The ID of the backend service"
  value       = google_compute_backend_service.backend_service.id
}

output "health_check_id" {
  description = "The ID of the health check"
  value       = google_compute_health_check.backend_health_check.id
}

output "https_forwarding_rule_ip" {
  description = "The IP address of the HTTPS forwarding rule"
  value       = length(google_compute_global_forwarding_rule.https_forwarding_rule) > 0 ? google_compute_global_forwarding_rule.https_forwarding_rule[0].ip_address : null
}

output "load_balancer_https_url" {
  description = "The HTTPS URL of the load balancer"
  value       = length(google_compute_global_forwarding_rule.https_forwarding_rule) > 0 ? "https://${google_compute_global_forwarding_rule.https_forwarding_rule[0].ip_address}" : null
}

