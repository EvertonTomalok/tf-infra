# Terraform version requirements are in versions.tf

terraform {
  required_version = ">= 1.13.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.8.0"
    }
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
    
    # Log start
    echo "Starting nginx configuration..." | sudo tee -a /var/log/startup-script.log
    
    # Update system packages with retries
    for i in 1 2 3; do
      if sudo apt-get update; then
        break
      fi
      echo "apt-get update attempt $i failed, retrying..." | sudo tee -a /var/log/startup-script.log
      sleep 5
    done
    
    # Install nginx and curl
    sudo apt-get install -y nginx curl || echo "Package installation had issues" | sudo tee -a /var/log/startup-script.log
    
    # Configure nginx to proxy requests to httpbin.org/anything
    sudo tee /etc/nginx/sites-available/default > /dev/null <<NGINX_CONFIG
    server {
        listen 80;
        server_name _;
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
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
    
    # Test nginx configuration
    if sudo nginx -t; then
      echo "Nginx configuration is valid" | sudo tee -a /var/log/startup-script.log
    else
      echo "Nginx configuration test failed!" | sudo tee -a /var/log/startup-script.log
      exit 1
    fi
    
    # Enable and restart nginx
    sudo systemctl enable nginx
    sudo systemctl restart nginx
    
    # Wait a moment and verify nginx is running
    sleep 2
    if sudo systemctl is-active --quiet nginx; then
      echo "Nginx configured and started successfully" | sudo tee -a /var/log/startup-script.log
    else
      echo "Nginx failed to start!" | sudo tee -a /var/log/startup-script.log
      sudo systemctl status nginx | sudo tee -a /var/log/startup-script.log
      exit 1
    fi
  EOF

  metadata = var.ssh_public_key != "" ? {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  } : {}

  service_account {
    scopes = ["cloud-platform"]
  }
}
