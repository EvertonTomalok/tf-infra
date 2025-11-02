# Terraform Infrastructure - Development Environment

> **Note**: This repository is not open to contributions. Please do not submit pull requests.

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

### Networking
- `vpc_id`: VPC network ID
- `vpc_name`: VPC network name
- `subnet_id`: Subnet ID
- `subnet_name`: Subnet name

### Compute Instances
- `server_a_name`: Server A instance name
- `server_a_url`: Server A URL (HTTP)
- `server_b_name`: Server B instance name
- `server_b_url`: Server B URL (HTTP)

### Load Balancer
- `load_balancer_ip`: Load balancer IP address (prefers HTTPS IP if SSL configured)
- `load_balancer_url`: Load balancer HTTP URL
- `load_balancer_https_url`: Load balancer HTTPS URL (if SSL configured)

To view all outputs:

```bash
terraform output
```

To get a specific output value:

```bash
terraform output -raw load_balancer_url
terraform output -raw load_balancer_ip
```

## Module Details

This configuration uses the following modules:
- **`cloud-engine`**: Creates nginx VM instances with Ubuntu 22.04 LTS and pre-configured nginx reverse proxy
  - See [modules/cloud-engine/README.md](../../modules/cloud-engine/README.md) for detailed documentation
- **`load-balancer`**: Creates the global HTTP(S) load balancer with health checks and optional SSL certificate support
  - See [modules/load-balancer/README.md](../../modules/load-balancer/README.md) for detailed documentation

For more details about the nginx configuration and proxy setup, see [NGINX_PROXY.md](./NGINX_PROXY.md).

For an overview of all available modules, see [modules/MODULES.md](../../modules/MODULES.md).

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

## DNS Propagation

When you configure a custom domain name to point to your load balancer or servers, DNS changes need to propagate across DNS servers worldwide. Understanding and checking DNS propagation is crucial for verifying that your DNS records are correctly configured and accessible globally.

### What is DNS Propagation?

DNS propagation is the time it takes for DNS record changes to spread across all DNS servers on the internet. When you create or modify a DNS record (such as an A record pointing to your load balancer IP), the change needs to be cached and distributed to DNS resolvers worldwide. This process can take anywhere from a few minutes to 48 hours, depending on the Time To Live (TTL) value of your DNS records.

### Checking DNS Propagation

There are several methods to check if your DNS records have propagated correctly:

#### Using Command Line Tools

##### Check A Record (IPv4)

```bash
# Check A record from your local machine
dig test.amaodontomedica.com.br +short A

# Check A record with detailed information
dig test.amaodontomedica.com.br A

# Check from a specific DNS server (e.g., Google's DNS)
dig @8.8.8.8 test.amaodontomedica.com.br A

# Check using nslookup
nslookup test.amaodontomedica.com.br
nslookup -type=A test.amaodontomedica.com.br
```

##### Check AAAA Record (IPv6)

```bash
dig test.amaodontomedica.com.br AAAA
nslookup -type=AAAA test.amaodontomedica.com.br
```

##### Check CNAME Record

```bash
dig test.amaodontomedica.com.br CNAME
nslookup -type=CNAME test.amaodontomedica.com.br
```

##### Check MX Record (Mail Exchange)

```bash
dig test.amaodontomedica.com.br MX
nslookup -type=MX test.amaodontomedica.com.br
```

##### Check TXT Record

```bash
dig test.amaodontomedica.com.br TXT
nslookup -type=TXT test.amaodontomedica.com.br
```

##### Check All Record Types

```bash
# Get all DNS records for a domain
dig test.amaodontomedica.com.br ANY

# Using host command
host test.amaodontomedica.com.br
host -a test.amaodontomedica.com.br
```

#### Checking from Multiple Locations

DNS propagation can vary by geographic location. To check propagation globally, you can:

1. **Use different DNS servers** to simulate different locations:
   ```bash
   # Google DNS (8.8.8.8, 8.8.4.4)
   dig @8.8.8.8 test.amaodontomedica.com.br A
   
   # Cloudflare DNS (1.1.1.1, 1.0.0.1)
   dig @1.1.1.1 test.amaodontomedica.com.br A
   
   # OpenDNS (208.67.222.222, 208.67.220.220)
   dig @208.67.222.222 test.amaodontomedica.com.br A
   
   # Quad9 (9.9.9.9)
   dig @9.9.9.9 test.amaodontomedica.com.br A
   ```

2. **Use online DNS checker tools** that check from multiple locations:
   - [whatsmydns.net](https://www.whatsmydns.net/)
   - [dnschecker.org](https://dnschecker.org/)
   - [dnsmap.io](https://dnsmap.io/)

#### Check Specific Load Balancer IP

If you've configured a domain to point to your load balancer IP:

```bash
# Get your load balancer IP
LB_IP=$(terraform output -raw load_balancer_ip)
echo "Load Balancer IP: $LB_IP"

# Check if domain points to your load balancer IP
dig test.amaodontomedica.com.br +short A

# Verify the IP matches
dig test.amaodontomedica.com.br +short A | grep -q "$LB_IP" && echo "DNS points to correct IP" || echo "DNS does not match"
```

#### Understanding TTL (Time To Live)

TTL determines how long DNS records are cached. Lower TTL values mean faster propagation but more DNS queries:

```bash
# Check TTL value
dig test.amaodontomedica.com.br A +noall +answer +ttlid

# Example output shows TTL in seconds:
# test.amaodontomedica.com.br.  300  IN  A  192.0.2.1
#                                ^^^
#                                TTL = 300 seconds (5 minutes)
```

#### Common DNS Propagation Issues

1. **DNS records not resolving**:
   ```bash
   # Check if DNS server can resolve the domain
   dig test.amaodontomedica.com.br +trace
   
   # Check authoritative nameservers
   dig test.amaodontomedica.com.br NS
   ```

2. **Cached old DNS records**:
   - DNS resolvers cache records based on TTL
   - Wait for TTL to expire or flush local DNS cache:
     ```bash
     # macOS
     sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
     
     # Linux
     sudo systemd-resolve --flush-caches
     
     # Windows
     ipconfig /flushdns
     ```

3. **Verify DNS configuration in GCP**:
   If using Google Cloud DNS:
   ```bash
   # List DNS zones
   gcloud dns managed-zones list
   
   # List DNS records in a zone
   gcloud dns record-sets list --zone=YOUR_ZONE_NAME
   
   # Describe a specific record
   gcloud dns record-sets describe test.amaodontomedica.com.br. --type=A --zone=YOUR_ZONE_NAME
   ```

#### Quick DNS Propagation Check Script

Create a simple script to check DNS propagation:

```bash
#!/bin/bash
DOMAIN="test.amaodontomedica.com.br"
EXPECTED_IP=$(terraform output -raw load_balancer_ip)

echo "Checking DNS propagation for $DOMAIN..."
echo "Expected IP: $EXPECTED_IP"
echo ""

DNS_SERVERS=(
    "8.8.8.8:Google"
    "1.1.1.1:Cloudflare"
    "208.67.222.222:OpenDNS"
    "9.9.9.9:Quad9"
)

for server_info in "${DNS_SERVERS[@]}"; do
    IFS=':' read -r server_ip server_name <<< "$server_info"
    result=$(dig @$server_ip $DOMAIN +short A)
    echo "[$server_name ($server_ip)]: $result"
    
    if [[ "$result" == "$EXPECTED_IP" ]]; then
        echo "  ✓ Match"
    else
        echo "  ✗ Mismatch"
    fi
    echo ""
done
```

### DNS Propagation Best Practices

1. **Set appropriate TTL values**: Lower TTL (300-600 seconds) before making changes, then increase after propagation
2. **Use multiple DNS servers** to verify propagation globally
3. **Check both A and AAAA records** if using IPv6
4. **Monitor DNS propagation** using online tools for global verification
5. **Wait for full propagation** before switching traffic to new DNS records

### Related Commands

```bash
# Get all DNS information for troubleshooting
dig test.amaodontomedica.com.br +noall +answer

# Check DNS propagation with timing information
time dig test.amaodontomedica.com.br A

# Continuous DNS monitoring
watch -n 5 'dig test.amaodontomedica.com.br +short A'

# Check if DNS server is responding
dig @8.8.8.8 test.amaodontomedica.com.br +stats
```

## Customization

You can customize this configuration by:

- Modifying `variables.tf` to add new variables
- Changing the subnet CIDR in `terraform.tfvars`
- Adjusting firewall rules in `main.tf`
- Modifying the load balancer configuration via the `load-balancer` module variables
- Updating nginx configuration in the `cloud-engine` module

For more information, see the module documentation in `modules/MODULES.md`.
