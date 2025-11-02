output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "server_a_name" {
  description = "The name of the nginx VM instance"
  value       = module.server_a.nginx_server_name
}

output "server_a_url" {
  description = "The URL to access the nginx server (proxies to httpbin.org/anything)"
  value       = "http://${module.server_a.nginx_server_address}"
}

output "server_b_name" {
  description = "The name of the nginx VM instance"
  value       = module.server_b.nginx_server_name
}

output "server_b_url" {
  description = "The health check endpoint URL"
  value       = "http://${module.server_b.nginx_server_address}"
}

output "load_balancer_ip" {
  description = "The IP address of the load balancer"
  value       = module.load_balancer.load_balancer_ip
}

output "load_balancer_url" {
  description = "The URL of the load balancer"
  value       = module.load_balancer.load_balancer_url
}

output "load_balancer_https_ip" {
  description = "The IP address of the HTTPS load balancer"
  value       = module.load_balancer.https_forwarding_rule_ip
}

output "load_balancer_https_url" {
  description = "The HTTPS URL of the load balancer"
  value       = module.load_balancer.load_balancer_https_url
}

output "dns_zone_name_servers" {
  description = "The nameservers for the DNS zone (update your domain registrar with these)"
  value       = data.google_dns_managed_zone.amaodontomedica_zone.name_servers
}

output "dns_zone" {
  description = "The DNS zone name"
  value       = data.google_dns_managed_zone.amaodontomedica_zone.name
}

# Example: Cloud Function outputs (uncomment when using the Cloud Function module)
# output "cloud_function_url" {
#   description = "The URL of the Cloud Function"
#   value       = module.example_cloud_function.function_url
# }
#
# output "cloud_function_name" {
#   description = "The name of the Cloud Function"
#   value       = module.example_cloud_function.function_name
# }
