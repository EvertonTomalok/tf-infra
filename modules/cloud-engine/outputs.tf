output "nginx_server_address" {
  description = "The external IP address of the nginx server"
  value       = google_compute_instance.nginx_server.network_interface[0].access_config[0].nat_ip
}

output "nginx_server_name" {
  description = "The name of the nginx VM instance"
  value       = google_compute_instance.nginx_server.name
}

output "nginx_server_zone" {
  description = "The zone of the nginx VM instance"
  value       = google_compute_instance.nginx_server.zone
}

output "nginx_server_self_link" {
  description = "The self link of the nginx VM instance"
  value       = google_compute_instance.nginx_server.self_link
}

