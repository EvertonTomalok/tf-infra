# Terraform version requirements are in versions.tf

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
resource "google_compute_address" "nginx_external_ip" {
  name   = "${var.project_name}-nginx-external-ip"
  region = var.region
}

# nginx VM instance that redirects traffic to httpbin.org/anything
resource "google_compute_instance" "nginx_server" {
  name         = "${var.project_name}-nginx"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
    
    access_config {
      nat_ip = google_compute_address.nginx_external_ip.address
    }
  }

  tags = ["web-access", "ssh-access"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system packages
    apt-get update
    apt-get install -y nginx curl
    
    # Configure nginx to proxy requests to httpbin.org/anything
    cat > /etc/nginx/sites-available/default <<NGINX_CONFIG
    server {
        listen 80;
        server_name _;
        
        location / {
            proxy_pass https://httpbin.org/anything;
            proxy_set_header Host httpbin.org;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            
            # Allow larger request bodies
            client_max_body_size 10M;
            
            # Disable buffering for streaming responses
            proxy_buffering off;
        }
    }
    NGINX_CONFIG
    
    # Enable and restart nginx
    systemctl enable nginx
    systemctl restart nginx
    
    # Log completion
    echo "Nginx configured and started successfully" >> /var/log/startup-script.log
  EOF

  metadata = var.ssh_public_key != "" ? {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  } : {}

  service_account {
    scopes = ["cloud-platform"]
  }
}
