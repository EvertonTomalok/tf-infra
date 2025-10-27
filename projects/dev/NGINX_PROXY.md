# Nginx Proxy Server Configuration

This configuration creates an nginx server on Google Cloud Platform that proxies all traffic to `https://httpbin.org/anything`.

## What This Creates

1. **Static External IP Address**: A reserved public IP that won't change
2. **Ubuntu VM Instance**: Running nginx with automatic configuration
3. **Reverse Proxy**: All HTTP requests are forwarded to httpbin.org/anything

## How It Works

When you make a GET request to the nginx server's external IP, nginx will:
1. Receive the request
2. Forward it to `https://httpbin.org/anything`
3. Return the response from httpbin.org

The httpbin.org service returns information about the request (headers, method, URL, etc.), which is useful for testing HTTP clients.

## Deployment

### Prerequisites

1. Configure your `terraform.tfvars` file:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project_id and optionally ssh_public_key
```

2. Initialize and apply:
```bash
terraform init
terraform plan
terraform apply
```

### Accessing the Server

After deployment, you can access your nginx server using the external IP:

```bash
# Get the external IP
terraform output nginx_server_external_ip

# Test the proxy
curl http://$(terraform output -raw nginx_server_external_ip)

# Or use the URL output
curl $(terraform output -raw nginx_server_url)
```

## Configuration Details

- **Machine Type**: e2-micro (suitable for testing, can be upgraded if needed)
- **OS**: Ubuntu 22.04 LTS
- **Zone**: `{region}-a` (e.g., us-central1-a)
- **Disk**: 20GB standard persistent disk
- **Network**: Uses the VPC and subnet created by this Terraform configuration

## nginx Configuration

The nginx configuration:
- Listens on port 80
- Proxies all requests to `https://httpbin.org/anything`
- Preserves client IP address in headers
- Handles large request bodies (up to 10MB)
- Disables buffering for streaming responses

## Firewall Rules

The server is accessible via:
- **Port 80**: HTTP traffic (no SSL/TLS)
- **Port 22**: SSH (if ssh_public_key is configured)

Both are accessible from anywhere (0.0.0.0/0).

## Testing

Test that the proxy works:

```bash
# Simple GET request
curl http://<external-ip>/

# With query parameters
curl "http://<external-ip>/test?foo=bar"

# POST request
curl -X POST http://<external-ip>/ -d "test=data"

# Check response (should include request info from httpbin)
curl http://<external-ip>/ | jq
```

## Cleanup

To remove the nginx server and all associated resources:

```bash
terraform destroy
```

This will:
- Delete the VM instance
- Release the static IP address
- Remove all network resources (if not used by other resources)

## Troubleshooting

### Cannot access the server

1. Check if the VM is running:
   ```bash
   gcloud compute instances describe tf-infra-nginx --zone=us-central1-a
   ```

2. Check firewall rules:
   ```bash
   gcloud compute firewall-rules list
   ```

3. SSH into the server (if ssh_public_key is configured):
   ```bash
   gcloud compute ssh tf-infra-nginx --zone=us-central1-a
   ```

### nginx not working

SSH into the server and check nginx status:
```bash
sudo systemctl status nginx
sudo journalctl -u nginx -n 50
sudo cat /etc/nginx/sites-available/default
```

### Startup script issues

Check the startup script logs:
```bash
sudo cat /var/log/startup-script.log
```

## Customization

You can modify the proxy destination or configuration by editing the `metadata_startup_script` in `main.tf`. For example, to proxy to a different URL:

```hcl
proxy_pass https://example.com/api;
```
