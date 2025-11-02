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

# Static external IP address for nginx server
resource "google_compute_address" "server_a_external_ip" {
  name   = "server-a-nginx-external-ip"
  region = var.region
}

module "server_a" {
  source = "../../modules/cloud-engine"

  project_id   = var.project_id
  project_name = "server-a"
  nat_ip       = google_compute_address.server_a_external_ip.address
  network      = google_compute_network.vpc.name
  subnetwork   = google_compute_subnetwork.subnet.name
}

resource "google_compute_address" "server_b_external_ip" {
  name   = "server-b-nginx-external-ip"
  region = var.region
}

module "server_b" {
  source = "../../modules/cloud-engine"

  project_id   = var.project_id
  project_name = "server-b"
  nat_ip       = google_compute_address.server_b_external_ip.address
  network      = google_compute_network.vpc.name
  subnetwork   = google_compute_subnetwork.subnet.name
}

# Firewall rule to allow health checks from Google Cloud Load Balancer
resource "google_compute_firewall" "allow_lb_health_check" {
  name    = "${var.project_name}-allow-lb-health-check"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Google Cloud Load Balancer health check source ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web-access"]
}

# Single unmanaged instance group containing both server_a and server_b
# NOTE: Both servers must be in the same zone for unmanaged instance groups with global load balancers
resource "google_compute_instance_group" "instance_group" {
  name = "${var.project_name}-instance-group"
  zone = module.server_a.nginx_server_zone
  
  instances = [
    module.server_a.nginx_server_self_link,
    module.server_b.nginx_server_self_link
  ]

  named_port {
    name = "http"
    port = 80
  }
  
  # Ensure instances are created before adding them to the group
  depends_on = [
    module.server_a,
    module.server_b
  ]
}

# SSL certificate for test.amaodontomedica.com.br
resource "google_compute_managed_ssl_certificate" "ssl_certificate" {
  name = "amaodontomedica-ssl-cert"

  managed {
    domains = ["test.amaodontomedica.com.br"]
  }
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  project_id = var.project_id
  region     = var.region
  name       = "primary-lb"
  instance_groups = {
    backend = {
      group           = google_compute_instance_group.instance_group.id
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
      max_utilization = 0.8
    }
  }
  health_check_path = "/health"
  health_check_port = 80
  ssl_certificates  = [google_compute_managed_ssl_certificate.ssl_certificate.id]
  # Note: test.amaodontomedica.com.br subdomain will use the same backend service
  depends_on = [
    module.server_a,
    module.server_b,
    google_compute_instance_group.instance_group,
    google_compute_managed_ssl_certificate.ssl_certificate,
  ]
}

# Reference existing Cloud DNS Zone for amaodontomedica.com.br (ama-clinica)
# Using data source to avoid managing/deleting this zone with Terraform
data "google_dns_managed_zone" "amaodontomedica_zone" {
  name = "ama-clinica"
}

# DNS A record for test.amaodontomedica.com.br pointing to load balancer
resource "google_dns_record_set" "test_subdomain" {
  name = "test.amaodontomedica.com.br."
  type = "A"
  ttl  = 30

  managed_zone = data.google_dns_managed_zone.amaodontomedica_zone.name

  # Point to the load balancer IP (output prefers HTTPS IP when available)
  # HTTP requests will be automatically redirected to HTTPS
  rrdatas = [module.load_balancer.load_balancer_ip]

  depends_on = [module.load_balancer]
}