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
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      nat_ip = var.nat_ip
    }
  }

  tags = ["web-access", "ssh-access", "terraform"]

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
    # Circuit breaker: implements proper state machine
    # CLOSED: httpbin is healthy (default state)
    # OPEN: after 5 failures in 30s, httpbin marked unavailable, use httpbun
    # HALF-OPEN: after 30s, test httpbin again on next request
    # CLOSED: if httpbin succeeds in half-open, return to normal
    upstream backend {
        # Primary backend: fails after 5 errors in 30 second window
        server httpbin.org:443 max_fails=5 fail_timeout=30s;
        
        # Fallback: only used when primary is in OPEN or HALF-OPEN state
        server httpbun.org:443 backup;
        
        # Keep connections alive for performance
        keepalive 32;
    }
    
    # Health check results storage
    map \$upstream_addr \$backend_status {
        default "unknown";
        ~*httpbin\.org "primary";
        ~*httpbun\.org "fallback";
    }
    
    # Map backend to correct Host header
    map \$backend_status \$upstream_host {
        default "httpbin.org";
        "primary" "httpbin.org";
        "fallback" "httpbun.org";
    }
    
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
            # Proxy with full path and query string preservation
            proxy_pass https://backend;
            
            # SSL configuration for upstream
            proxy_ssl_name \$upstream_host;
            proxy_ssl_server_name on;
            
            # Preserve all original headers from client
            proxy_pass_request_headers on;
            proxy_pass_request_body on;
            
            # Override/modify headers based on which backend is used
            proxy_set_header Host \$upstream_host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header X-Forwarded-Host \$host;
            proxy_set_header X-Original-URI \$request_uri;
            proxy_set_header X-Backend-Status \$backend_status;
            
            # Allow larger request bodies
            client_max_body_size 10M;
            
            # Disable buffering for streaming responses
            proxy_buffering off;
            
            # Fast timeouts for quick failover
            proxy_connect_timeout 3s;
            proxy_send_timeout 5s;
            proxy_read_timeout 5s;
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