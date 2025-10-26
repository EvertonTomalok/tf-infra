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
