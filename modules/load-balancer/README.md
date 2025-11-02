# Load Balancer Module

> **Note**: This repository is not open to contributions. Please do not submit pull requests.

This module creates a Google Cloud HTTP(S) Load Balancer with health checks, backend services, and optional SSL certificate support. The load balancer distributes traffic across multiple backend instance groups with configurable load balancing algorithms.

## Features

- ✅ Global HTTP Load Balancer
- ✅ Optional HTTPS support with SSL certificates
- ✅ Automatic HTTP to HTTPS redirect (when SSL is configured)
- ✅ Health checks with configurable path and port
- ✅ Multiple backend instance groups support
- ✅ Utilization-based load balancing
- ✅ Configurable capacity scaling
- ✅ Connection draining
- ✅ Path-based routing support

## Usage

### Basic Example (HTTP Only)

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id = var.project_id
  region     = var.region
  name       = "my-lb"
  
  instance_groups = {
    backend = {
      group           = google_compute_instance_group.group.id
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
      max_utilization = 0.8
    }
  }
  
  health_check_path = "/health"
  health_check_port = 80
}
```

### With HTTPS and SSL Certificates

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id = var.project_id
  region     = var.region
  name       = "my-lb"
  
  instance_groups = {
    backend = {
      group           = google_compute_instance_group.group.id
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
      max_utilization = 0.8
    }
  }
  
  health_check_path = "/health"
  health_check_port = 80
  
  ssl_certificates = [
    google_compute_managed_ssl_certificate.cert.id
  ]
}
```

### With Multiple Backends

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id = var.project_id
  region     = var.region
  name       = "my-lb"
  
  instance_groups = {
    primary = {
      group           = google_compute_instance_group.primary.id
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
      max_utilization = 0.8
    }
    secondary = {
      group           = google_compute_instance_group.secondary.id
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 0.5
      max_utilization = 0.8
    }
  }
  
  health_check_path = "/health"
  health_check_port = 80
}
```

### With Path-Based Routing

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  project_id = var.project_id
  region     = var.region
  name       = "my-lb"
  
  instance_groups = {
    backend = {
      group           = google_compute_instance_group.group.id
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
      max_utilization = 0.8
    }
  }
  
  health_check_path = "/health"
  health_check_port = 80
  
  path_routes = {
    "/api/*" = {
      service = google_compute_backend_service.api_backend.id
    }
    "/static/*" = {
      service = google_compute_backend_service.static_backend.id
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.4 |
| google | ~> 7.8.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The GCP project ID | `string` | n/a | yes |
| instance_groups | Map of instance groups to use as backends. Each backend must specify: group (instance group ID), balancing_mode (UTILIZATION or RATE), capacity_scaler (0.0-1.0), max_utilization (0.0-1.0) | `map(object)` | n/a | yes |
| region | The GCP region for resources | `string` | `"us-central1"` | no |
| name | Name for the load balancer resources | `string` | `"lb"` | no |
| health_check_path | Path for health check | `string` | `"/health"` | no |
| health_check_port | Port for health check | `number` | `80` | no |
| ssl_certificates | List of SSL certificate self links to use for HTTPS | `list(string)` | `[]` | no |
| path_routes | Map of path patterns to backend services for path-based routing | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| load_balancer_ip | The IP address of the load balancer (prefers HTTPS IP if available) |
| load_balancer_url | The HTTP URL of the load balancer |
| load_balancer_https_url | The HTTPS URL of the load balancer (null if SSL not configured) |
| forwarding_rule_name | The name of the HTTP forwarding rule |
| backend_service_name | The name of the backend service |
| backend_service_id | The ID of the backend service |
| health_check_id | The ID of the health check |
| https_forwarding_rule_ip | The IP address of the HTTPS forwarding rule (null if SSL not configured) |

## Health Checks

The module creates an HTTP health check with the following default settings:

- **Check Interval**: 10 seconds
- **Timeout**: 5 seconds
- **Healthy Threshold**: 2 consecutive successful checks
- **Unhealthy Threshold**: 3 consecutive failed checks
- **Port**: Configurable (default: 80)
- **Path**: Configurable (default: `/health`)

Health checks are performed from Google Cloud Load Balancer IP ranges (130.211.0.0/22, 35.191.0.0/16). Ensure your firewall rules allow traffic from these ranges.

## SSL Certificate Support

When SSL certificates are provided:

1. A static global IP address is reserved for the load balancer
2. HTTPS forwarding rule is created on port 443
3. HTTP requests are automatically redirected to HTTPS (301 redirect)
4. Both HTTP and HTTPS forwarding rules use the same IP address

### Creating SSL Certificates

Example with managed SSL certificate:

```hcl
resource "google_compute_managed_ssl_certificate" "cert" {
  name = "my-ssl-cert"

  managed {
    domains = ["example.com", "www.example.com"]
  }
}

module "load_balancer" {
  # ... other configuration ...
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}
```

**Note**: Managed SSL certificates can take 10-60 minutes to provision. Ensure your DNS records point to the load balancer IP before the certificate can be issued.

## Load Balancing Modes

### UTILIZATION Mode

Balances traffic based on backend CPU utilization:

```hcl
instance_groups = {
  backend = {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0      # Scale factor (0.0 to 1.0)
    max_utilization = 0.8      # Target CPU utilization (0.0 to 1.0)
  }
}
```

### RATE Mode

Balances traffic based on requests per second (requires `max_rate` or `max_rate_per_instance`):

```hcl
instance_groups = {
  backend = {
    balancing_mode  = "RATE"
    capacity_scaler = 1.0
    max_utilization = 0.8
    # Note: RATE mode requires additional configuration in backend service
  }
}
```

## Path-Based Routing

The module supports path-based routing to direct traffic to different backend services based on URL paths:

```hcl
path_routes = {
  "/api/*" = {
    service = google_compute_backend_service.api_backend.id
  }
  "/static/*" = {
    service = google_compute_backend_service.static_backend.id
  }
}
```

Path patterns support wildcards (`*`). All unmatched paths route to the default backend service.

## Example Usage in Project

See `projects/dev/main.tf` for a complete example that uses this module with multiple nginx servers behind a load balancer with SSL certificate support.

## Resources Created

- `google_compute_health_check`: HTTP health check for backend instances
- `google_compute_backend_service`: Backend service with instance groups
- `google_compute_url_map`: URL mapping for request routing
- `google_compute_target_http_proxy`: HTTP proxy (or redirect map if SSL enabled)
- `google_compute_target_https_proxy`: HTTPS proxy (only if SSL enabled)
- `google_compute_global_forwarding_rule`: HTTP forwarding rule (port 80)
- `google_compute_global_forwarding_rule`: HTTPS forwarding rule (port 443, only if SSL enabled)
- `google_compute_global_address`: Static IP address (only if SSL enabled)
- `google_compute_url_map`: HTTP to HTTPS redirect map (only if SSL enabled)

## Troubleshooting

### Check Backend Health

```bash
gcloud compute backend-services get-health <backend-service-name> --global
```

### Verify Load Balancer Configuration

```bash
gcloud compute forwarding-rules list --global
gcloud compute backend-services describe <backend-service-name> --global
```

### Check Health Check Status

```bash
gcloud compute health-checks describe <health-check-name>
```

### Verify Instance Groups

```bash
gcloud compute instance-groups list
gcloud compute instance-groups describe <instance-group-name> --zone=<zone>
```

### Test Load Balancer

```bash
# Get load balancer IP
LB_IP=$(terraform output -raw load_balancer_ip)

# Test HTTP
curl http://$LB_IP/health

# Test HTTPS (if configured)
curl https://$LB_IP/health
```

## Notes

- The load balancer uses global forwarding rules for external access
- Connection draining timeout is set to 30 seconds
- CDN is disabled by default (can be enabled via backend service)
- Health checks require firewall rules allowing traffic from GCP load balancer IP ranges
- When SSL is configured, HTTP traffic is automatically redirected to HTTPS

