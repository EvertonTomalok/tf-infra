# Terraform Infrastructure for GCP

> **Note**: This repository is not open to contributions. Please do not submit pull requests.

A base Terraform repository for Google Cloud Platform (GCP) infrastructure provisioning.

## Features

- ✅ VPC network with custom subnet configuration
- ✅ Firewall rules for SSH, HTTP, and HTTPS
- ✅ High-availability nginx reverse proxy setup with load balancing
- ✅ Cloud Load Balancer with health checks
- ✅ Multiple backend servers for redundancy
- ✅ Cloud Functions module for serverless deployments
- ✅ Cloud Engine module for VM instances
- ✅ Load Balancer module for distributed traffic
- ✅ Modular structure with separate files for variables, outputs, and versions
- ✅ Ready for production use with remote state backend support
- ✅ Comprehensive documentation

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured
- A GCP project with billing enabled
- Appropriate IAM permissions to create resources

## Authentication

Authenticate with Google Cloud:

```bash
gcloud auth application-default login
```

Or set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to a service account key file.

## Quick Start

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repository-url>
   cd tf-infra
   ```

2. **Navigate to the project directory**:
   ```bash
   cd projects/dev
   ```

3. **Configure your variables**:
   Create a `terraform.tfvars` file with your configuration:
   ```hcl
   project_id = "your-gcp-project-id"
   project_name = "my-infra"
   region = "us-central1"
   ssh_public_key = "ssh-rsa AAAAB3..." # Optional: for VM SSH access
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Review the execution plan**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

7. **View outputs**:
   ```bash
   terraform output
   ```

8. **Access your load-balanced nginx servers**:
   ```bash
   # Access through the load balancer (recommended)
   curl $(terraform output -raw load_balancer_url)
   
   # Or access individual servers directly
   curl $(terraform output -raw server_a_url)
   curl $(terraform output -raw server_b_url)
   ```

## Configuration

### Required Variables

- `project_id`: Your GCP project ID

### Optional Variables

- `project_name`: Prefix for resource names (default: "tf-infra")
- `region`: GCP region (default: "us-central1")
- `subnet_cidr`: Subnet CIDR block (default: "10.0.1.0/24")
- `ssh_public_key`: SSH public key for VM access (default: empty)

## Remote State Backend

This project is configured to use Google Cloud Storage (GCS) as the backend for remote state.

The backend configuration is in `projects/dev/backend.tf`. To customize it:

1. Create a GCS bucket (if you don't have one):
   ```bash
   gsutil mb -p <PROJECT_ID> -l us-central1 gs://<BUCKET_NAME>
   ```

2. Update the backend configuration in `projects/dev/backend.tf`:
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "your-terraform-state-bucket"
       prefix = "terraform/state/projects/dev"
     }
   }
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

## Resources Created

- **VPC Network**: Custom VPC with manual subnet creation
- **Subnet**: Regional subnet within the VPC
- **Firewall Rules**:
  - SSH access (port 22) from anywhere
  - HTTP/HTTPS access (ports 80, 443) from anywhere
  - Load balancer health checks (ports 80)
- **Static External IPs**: Reserved public IPs for both nginx servers
- **Instance Groups**: Unmanaged instance groups for each server
- **Health Checks**: HTTP health checks monitoring `/health` endpoint
- **Cloud Load Balancer**: HTTP(S) load balancer distributing traffic across backend servers
- **Backend Service**: Load balancer backend service with utilization-based balancing
- **Nginx VM Instances** (2x): Ubuntu 22.04 VMs with nginx configured as a reverse proxy to httpbin.org/anything
  - Each server includes a `/health` endpoint for health checks

## Modules

This repository includes reusable modules for common infrastructure patterns. All modules follow consistent naming conventions and include comprehensive documentation.

See [modules/MODULES.md](modules/MODULES.md) for an overview of all available modules.

### Cloud Function Module

The `modules/cloud-function` module provides a reusable way to deploy Google Cloud Functions with configurable options.

See [modules/cloud-function/README.md](modules/cloud-function/README.md) for detailed documentation.

#### Basic Usage Example

```hcl
module "my_function" {
  source = "./modules/cloud-function"

  function_name         = "hello-world"
  runtime               = "python39"
  entry_point           = "hello"
  source_archive_bucket = "my-function-bucket"
  source_archive_object = "functions/hello.zip"
  
  project_id = var.project_id
  region     = var.region
}
```

### Cloud Engine Module

The `modules/cloud-engine` module provides a reusable way to deploy Google Compute Engine VM instances with Ubuntu 22.04 LTS and nginx pre-configured as a reverse proxy. The nginx instance includes a circuit breaker pattern for high availability with automatic failover.

#### Key Features

- Ubuntu 22.04 LTS VM instances
- Pre-configured nginx reverse proxy with circuit breaker pattern
- Automatic health check endpoint setup
- Configurable SSH keys
- Static external IP support

#### Basic Usage Example

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

#### Documentation

See [modules/cloud-engine/README.md](modules/cloud-engine/README.md) for detailed documentation.

### Load Balancer Module

The `modules/load-balancer` module provides a reusable HTTP(S) global load balancer with health checks, backend services, and optional SSL certificate support for high-availability setups.

#### Key Features

- Global HTTP(S) load balancer
- Optional HTTPS support with SSL certificates
- Automatic HTTP to HTTPS redirect (when SSL configured)
- Health checks with configurable path and port
- Multiple backend instance groups support
- Utilization-based load balancing

#### Basic Usage Example

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

#### Documentation

See [modules/load-balancer/README.md](modules/load-balancer/README.md) for detailed documentation.

## Extending the Infrastructure

This is a base configuration. You can extend it by adding:

- Cloud Functions (using the provided module)
- Compute Engine instances
- Cloud SQL databases
- Cloud Load Balancers
- Cloud Storage buckets
- IAM roles and policies
- Kubernetes Engine clusters
- And much more!

## Best Practices

- ✅ Use remote state backends for production
- ✅ Enable versioning on your state bucket
- ✅ Use separate workspaces for different environments
- ✅ Store sensitive variables using environment variables or secret managers
- ✅ Review and understand changes before applying
- ✅ Use infrastructure as code validation tools

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources created by this configuration.
