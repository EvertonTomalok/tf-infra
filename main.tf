# Terraform version requirements are in versions.tf

# Configure backend for state management
# Uncomment to use GCS backend
terraform {
  backend "gcs" {
    bucket = "everton_infra"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a VPC network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Create a firewall rule to allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-access"]
}

# Create a firewall rule to allow HTTP and HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "${var.project_name}-allow-http-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-access"]
}

# Example: Cloud Function module usage
# Uncomment and configure to deploy a Cloud Function
#
# module "example_cloud_function" {
#   source = "./modules/cloud-function"
#
#   function_name         = "${var.project_name}-hello-world"
#   description           = "Example Hello World Cloud Function"
#   runtime               = "python39"
#   entry_point           = "hello_world"
#   source_archive_bucket = "your-bucket-name"
#   source_archive_object = "functions/hello.zip"
#
#   available_memory_mb   = 256
#   timeout               = 60
#
#   environment_variables = {
#     ENV = "production"
#   }
#
#   labels = {
#     environment = "production"
#     team        = "devops"
#   }
#
#   allow_unauthenticated_invocations = true
#   min_instances                     = 1
#   max_instances                     = 10
#
#   project_id = var.project_id
#   region     = var.region
# }
