# Cloud Engine Module

> **Note**: This repository is not open to contributions. Please do not submit pull requests.

This module creates a Google Compute Engine VM instance with Ubuntu 22.04 LTS and pre-configured nginx as a reverse proxy. The nginx instance includes a circuit breaker pattern for high availability with automatic failover between primary and fallback backends.

## Features

- ✅ Ubuntu 22.04 LTS VM instance
- ✅ Pre-configured nginx reverse proxy
- ✅ Circuit breaker pattern with automatic failover
- ✅ Health check endpoint (`/health`)
- ✅ Configurable SSH keys
- ✅ Static external IP support
- ✅ VPC and subnet integration
- ✅ Automatic startup script configuration

## Architecture

The nginx reverse proxy implements a circuit breaker pattern:

- **CLOSED**: Primary backend (httpbin.org) is healthy (default state)
- **OPEN**: After 5 failures in 30s, primary backend marked unavailable, uses fallback (httpbun.org)
- **HALF-OPEN**: After 30s timeout, tests primary backend again on next request
- **CLOSED**: If primary succeeds in half-open, returns to normal operation

## Usage

### Basic Example

```hcl
module "nginx_server" {
  source = "./modules/cloud-engine"

  project_id   = var.project_id
  project_name = "my-server"
  region       = "us-central1"
  nat_ip       = google_compute_address.external_ip.address
  network      = google_compute_network.vpc.name
  subnetwork   = google_compute_subnetwork.subnet.name
}
```

### With SSH Key

```hcl
module "nginx_server" {
  source = "./modules/cloud-engine"

  project_id    = var.project_id
  project_name  = "my-server"
  region        = "us-central1"
  nat_ip        = google_compute_address.external_ip.address
  network       = google_compute_network.vpc.name
  subnetwork    = google_compute_subnetwork.subnet.name
  ssh_public_key = "ssh-rsa AAAAB3..."
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
| project_name | The nginx project name (used for instance naming) | `string` | n/a | yes |
| network | The VPC network name | `string` | n/a | yes |
| subnetwork | The subnet name | `string` | n/a | yes |
| nat_ip | The static external IP address to assign to the instance | `string` | n/a | yes |
| region | The GCP region for resources | `string` | `"us-central1"` | no |
| subnet_cidr | CIDR block for the subnet | `string` | `"10.0.1.0/24"` | no |
| ssh_public_key | SSH public key for VM access | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| nginx_server_address | The external IP address of the nginx server |
| nginx_server_name | The name of the nginx VM instance |
| nginx_server_zone | The zone of the nginx VM instance |
| nginx_server_self_link | The self link of the nginx VM instance (useful for instance groups) |

## Nginx Configuration

The module automatically configures nginx with:

- **Reverse Proxy**: Proxies requests to httpbin.org with fallback to httpbun.org
- **Circuit Breaker**: Implements proper state machine for high availability
- **Health Check**: Endpoint at `/health` returns `200 OK` for load balancer health checks
- **Request Preservation**: All original headers, query strings, and request bodies are preserved
- **SSL Configuration**: Proper SSL/TLS configuration for upstream connections
- **Performance**: Keepalive connections and optimized timeouts

### Health Check Endpoint

The health check endpoint is available at `/health`:

```bash
curl http://<server-ip>/health
# Returns: healthy
```

### Request Headers

The nginx instance adds the following custom headers:
- `X-Real-IP`: Client's real IP address
- `X-Forwarded-For`: Chain of forwarded IP addresses
- `X-Forwarded-Proto`: Original protocol (http/https)
- `X-Forwarded-Host`: Original host header
- `X-Original-URI`: Original request URI
- `X-Backend-Status`: Which backend is being used (primary/fallback)

## Example Usage in Project

See `projects/dev/main.tf` for a complete example that uses this module to create multiple nginx servers behind a load balancer.

## Notes

- The instance uses the `e2-micro` machine type by default
- Boot disk is 20GB standard persistent disk
- Instance includes tags: `web-access`, `ssh-access`, `terraform`
- Service account has `cloud-platform` scope for full GCP access
- Startup script logs are available at `/var/log/startup-script.log` on the instance

## Troubleshooting

### Check nginx Status

```bash
gcloud compute ssh <instance-name> --zone=<zone>
sudo systemctl status nginx
sudo systemctl restart nginx
```

### Check nginx Logs

```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Test Health Endpoint

```bash
curl http://<server-ip>/health
```

### Verify nginx Configuration

```bash
sudo nginx -t
```

### Check Startup Script Logs

```bash
sudo tail -f /var/log/startup-script.log
```

