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

  health_checks = [google_compute_health_check.backend_health_check.id]

  backend {
    group                 = var.instance_group_a_id
    balancing_mode       = "UTILIZATION"
    capacity_scaler      = 1.0
    max_utilization       = 0.8
  }

  backend {
    group                 = var.instance_group_b_id
    balancing_mode       = "UTILIZATION"
    capacity_scaler      = 1.0
    max_utilization       = 0.8
  }
}

# URL map
resource "google_compute_url_map" "url_map" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.backend_service.id
}

# Target HTTP proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Global forwarding rule
resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "${var.name}-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.id
  port_range = "80"
  ip_protocol = "TCP"
}

