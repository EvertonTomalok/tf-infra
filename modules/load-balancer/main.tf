# Health check for backend instances
resource "google_compute_health_check" "backend_health_check" {
  name               = "${var.name}-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

# Backend service
resource "google_compute_backend_service" "backend_service" {
  name                  = "${var.name}-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn            = false
  load_balancing_scheme = "EXTERNAL_MANAGED"
  connection_draining_timeout_sec = 30

  health_checks = [google_compute_health_check.backend_health_check.id]

  dynamic "backend" {
    for_each = var.instance_groups
    content {
      group           = backend.value.group
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      max_utilization = backend.value.max_utilization
    }
  }
}

# URL map with path-based routing (used for HTTPS)
resource "google_compute_url_map" "url_map" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.backend_service.id

  dynamic "host_rule" {
    for_each = length(var.path_routes) > 0 ? [1] : []
    content {
      hosts        = ["*"]
      path_matcher = "${var.name}-path-matcher"
    }
  }

  dynamic "path_matcher" {
    for_each = length(var.path_routes) > 0 ? [1] : []
    content {
      name            = "${var.name}-path-matcher"
      default_service = google_compute_backend_service.backend_service.id

      dynamic "path_rule" {
        for_each = var.path_routes
        content {
          paths   = [path_rule.key]
          service = path_rule.value.service
        }
      }
    }
  }
}

# Static IP address for load balancer (only created if SSL certificates are provided)
# This ensures both HTTP and HTTPS forwarding rules use the same IP
resource "google_compute_global_address" "lb_ip" {
  count   = length(var.ssl_certificates) > 0 ? 1 : 0
  name    = "${var.name}-ip"
  project = var.project_id
}

# URL map for HTTP to HTTPS redirect (only created if SSL certificates are provided)
resource "google_compute_url_map" "http_redirect" {
  count   = length(var.ssl_certificates) > 0 ? 1 : 0
  name    = "${var.name}-http-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# Target HTTP proxy (uses redirect map if SSL is configured, otherwise uses backend map)
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.name}-http-proxy"
  url_map = length(var.ssl_certificates) > 0 ? google_compute_url_map.http_redirect[0].id : google_compute_url_map.url_map.id
}

# Target HTTPS proxy (only created if SSL certificates are provided)
resource "google_compute_target_https_proxy" "https_proxy" {
  count            = length(var.ssl_certificates) > 0 ? 1 : 0
  name             = "${var.name}-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = var.ssl_certificates
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  count             = length(var.ssl_certificates) > 0 ? 1 : 0
  name              = "${var.name}-https-forwarding-rule"
  target            = google_compute_target_https_proxy.https_proxy[0].id
  port_range        = "443"
  ip_protocol       = "TCP"
  ip_address        = google_compute_global_address.lb_ip[0].address
}

# Global forwarding rule for HTTP
# When SSL is configured, use the same IP as HTTPS forwarding rule
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "${var.name}-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
  ip_protocol = "TCP"
  
  # Use the same IP address as HTTPS forwarding rule when SSL is configured
  # Otherwise, let GCP assign an ephemeral IP
  ip_address = length(var.ssl_certificates) > 0 ? google_compute_global_address.lb_ip[0].address : null
}

