# Terraform Infrastructure - Development Environment

This Terraform configuration deploys a high-availability nginx proxy setup on Google Cloud Platform with a load balancer distributing traffic across two backend servers.

## Overview

This infrastructure creates:
- **VPC Network**: A custom VPC with a subnet for isolated networking
- **Two Nginx Servers**: Server A and Server B running nginx reverse proxy to httpbin.org/httpbun.org
- **Global Load Balancer**: Distributes traffic across both servers with health checks
- **Firewall Rules**: Configured for SSH, HTTP/HTTPS, and load balancer health checks

## Architecture

```
Internet → Global Load Balancer → [Server A, Server B] → httpbin.org/httpbun.org
```

Both servers are configured to proxy requests to external services (httpbin.org/httpbun.org) and include automatic failover capabilities. The load balancer uses health checks to route traffic only to healthy instances.

## Prerequisites

1. **GCP Project**: A GCP project with billing enabled
2. **Required APIs**: Enable the following APIs:
   ```bash
   gcloud services enable compute.googleapis.com
   ```
3. **Terraform**: Terraform >= 1.0 installed
4. **Authentication**: Authenticated with GCP (via `gcloud auth application-default login` or service account)

## Configuration

### 1. Configure Variables

Edit `terraform.tfvars` with your project details:

```hcl
project_id = "your-project-id"
project_name = "dev"  # Optional: prefix for resource names
region = "us-central1"  # Optional: GCP region
subnet_cidr = "10.0.1.0/24"  # Optional: CIDR for subnet
ssh_public_key = ""  # Optional: SSH public key for VM access
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

This will show you all resources that will be created:
- VPC network and subnet
- Two static external IP addresses
- Two Cloud Engine instances with nginx
- Firewall rules (SSH, HTTP/HTTPS, health checks)
- Instance groups
- Global load balancer

### 4. Apply the Configuration

```bash
terraform apply
```

## What Gets Created

### Networking
- **VPC Network**: Custom VPC with auto-create subnets disabled
- **Subnet**: Regional subnet in the specified region
- **Firewall Rules**:
  - SSH access (port 22) from anywhere
  - HTTP/HTTPS access (ports 80, 443) from anywhere
  - Health check access (port 80) from GCP load balancer IP ranges

### Compute Resources
- **Server A**: Nginx VM instance with static external IP
- **Server B**: Nginx VM instance with static external IP
- Both servers:
  - Run nginx reverse proxy
  - Proxy to httpbin.org with failover to httpbun.org
  - Include health check endpoint at `/health`

### Load Balancing
- **Global HTTP Load Balancer**: Distributes traffic across both servers
- **Backend Service**: Configured with health checks
- **Instance Groups**: One for each server
- **Forwarding Rule**: Routes global traffic to the backend service

## Accessing Your Infrastructure

After deployment, retrieve the endpoints:

```bash
# Get the load balancer URL (recommended)
terraform output load_balancer_url

# Get individual server URLs
terraform output server_a_url
terraform output server_b_url

# Get the load balancer IP
terraform output load_balancer_ip
```

### Testing Endpoints

#### Testing the Load Balancer

```bash
# Get the load balancer URL
LB_URL=$(terraform output -raw load_balancer_url)

# Test health check endpoint
curl $(terraform output -raw load_balancer_url)/health

# Or using the variable
curl $LB_URL/health

# Make GET requests through the load balancer
curl $(terraform output -raw load_balancer_url)/anything
curl $LB_URL/anything

# With query parameters
curl "$(terraform output -raw load_balancer_url)/anything/test?foo=bar&baz=qux"

# POST request
curl -X POST $(terraform output -raw load_balancer_url)/anything -d "test=data"

# POST with JSON
curl -X POST $(terraform output -raw load_balancer_url)/anything \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'

# With custom headers
curl -H "X-Custom-Header: test-value" $(terraform output -raw load_balancer_url)/anything

# Pretty print JSON response
curl $(terraform output -raw load_balancer_url)/anything | jq
```

#### Testing Server A Directly

```bash
# Get Server A URL
SERVER_A_URL=$(terraform output -raw server_a_url)

# Test health check
curl $(terraform output -raw server_a_url)/health
curl $SERVER_A_URL/health

# Make requests directly to Server A
curl $(terraform output -raw server_a_url)/anything
curl $SERVER_A_URL/anything

# With query parameters
curl "$(terraform output -raw server_a_url)/anything/test?foo=bar"

# POST request
curl -X POST $(terraform output -raw server_a_url)/anything -d "test=data"

# Pretty print JSON response
curl $(terraform output -raw server_a_url)/anything | jq
```

#### Testing Server B Directly

```bash
# Get Server B URL
SERVER_B_URL=$(terraform output -raw server_b_url)

# Test health check
curl $(terraform output -raw server_b_url)/health
curl $SERVER_B_URL/health

# Make requests directly to Server B
curl $(terraform output -raw server_b_url)/anything
curl $SERVER_B_URL/anything

# With query parameters
curl "$(terraform output -raw server_b_url)/anything/test?foo=bar"

# POST request
curl -X POST $(terraform output -raw server_b_url)/anything -d "test=data"

# Pretty print JSON response
curl $(terraform output -raw server_b_url)/anything | jq
```

#### Quick Test Commands

```bash
# Quick test all endpoints at once
echo "Load Balancer:" && curl -s $(terraform output -raw load_balancer_url)/health && echo ""
echo "Server A:" && curl -s $(terraform output -raw server_a_url)/health && echo ""
echo "Server B:" && curl -s $(terraform output -raw server_b_url)/health && echo ""

# Test load balancer distribution (multiple requests)
for i in {1..5}; do
  echo "Request $i:"
  curl -s $(terraform output -raw load_balancer_url)/anything | jq -r '.url'
done
```

## Features

- **High Availability**: Two backend servers with load balancing
- **Health Checks**: Automatic routing only to healthy instances
- **Reverse Proxy**: Both servers proxy to httpbin.org with failover to httpbun.org
- **Custom VPC**: Isolated network environment
- **Static IPs**: Reserved external IP addresses that persist
- **Automatic Failover**: Nginx servers handle backend failures automatically

## Outputs

The configuration provides the following outputs:

- `vpc_id`: VPC network ID
- `vpc_name`: VPC network name
- `subnet_id`: Subnet ID
- `subnet_name`: Subnet name
- `server_a_name`: Server A instance name
- `server_a_url`: Server A URL
- `server_b_name`: Server B instance name
- `server_b_url`: Server B URL
- `load_balancer_ip`: Load balancer IP address
- `load_balancer_url`: Load balancer URL

## Module Details

This configuration uses the following modules:
- `cloud-engine`: Creates nginx VM instances (see `modules/cloud-engine/`)
- `load-balancer`: Creates the global load balancer (see `modules/load-balancer/`)

For more details about the nginx configuration and proxy setup, see [NGINX_PROXY.md](./NGINX_PROXY.md).

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

This will remove:
- All VM instances
- Load balancer and backend services
- Static IP addresses
- Firewall rules
- VPC network and subnet

⚠️ **Warning**: This will delete all resources created by this configuration. Make sure you don't have other resources using the VPC or other shared resources.

## Troubleshooting

### Cannot access the load balancer

1. Check if instances are running:
   ```bash
   gcloud compute instances list
   ```

2. Check firewall rules:
   ```bash
   gcloud compute firewall-rules list
   ```

3. Check health check status:
   ```bash
   gcloud compute backend-services get-health <backend-service-name> --global
   ```

### Health checks failing

1. SSH into one of the servers:
   ```bash
   gcloud compute ssh <server-name> --zone=<zone>
   ```

2. Check nginx status:
   ```bash
   sudo systemctl status nginx
   curl http://localhost/health
   ```

3. Check nginx logs:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   sudo tail -f /var/log/nginx/access.log
   ```

### Load balancer not distributing traffic

1. Verify both instances are in the backend service:
   ```bash
   terraform output
   ```

2. Check backend service configuration:
   ```bash
   gcloud compute backend-services describe <backend-service-name> --global
   ```

## Customization

You can customize this configuration by:

- Modifying `variables.tf` to add new variables
- Changing the subnet CIDR in `terraform.tfvars`
- Adjusting firewall rules in `main.tf`
- Modifying the load balancer configuration via the `load-balancer` module variables
- Updating nginx configuration in the `cloud-engine` module

For more information, see the module documentation in `modules/MODULES.md`.
