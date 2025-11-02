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

# Unmanaged instance group for server_a
resource "google_compute_instance_group" "instance_group_a" {
  name      = "${var.project_name}-instance-group-a"
  zone      = module.server_a.nginx_server_zone
  instances = [module.server_a.nginx_server_self_link]

  named_port {
    name = "http"
    port = 80
  }
}

# Unmanaged instance group for server_b
resource "google_compute_instance_group" "instance_group_b" {
  name      = "${var.project_name}-instance-group-b"
  zone      = module.server_b.nginx_server_zone
  instances = [module.server_b.nginx_server_self_link]

  named_port {
    name = "http"
    port = 80
  }
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  project_id          = var.project_id
  region              = var.region
  name                = "primary-lb"
  instance_group_a_id = google_compute_instance_group.instance_group_a.id
  instance_group_b_id = google_compute_instance_group.instance_group_b.id
  health_check_path   = "/health"
  health_check_port   = 80
}