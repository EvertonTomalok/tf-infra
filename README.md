# Terraform Infrastructure for GCP

A base Terraform repository for Google Cloud Platform (GCP) infrastructure provisioning.

## Features

- ✅ VPC network with custom subnet configuration
- ✅ Firewall rules for SSH, HTTP, and HTTPS
- ✅ Nginx reverse proxy server with auto-configuration
- ✅ Cloud Functions module for serverless deployments
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

8. **Access your nginx server**:
   ```bash
   curl http://$(terraform output -raw nginx_server_external_ip)
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
- **Static External IP**: Reserved public IP for the nginx server
- **Nginx VM Instance**: Ubuntu 22.04 VM with nginx configured as a reverse proxy to httpbin.org/anything

## Modules

This repository includes reusable modules for common infrastructure patterns.

### Cloud Function Module

The `modules/cloud-function` module provides a reusable way to deploy Google Cloud Functions with configurable options.

See [modules/cloud-function/README.md](modules/cloud-function/README.md) for detailed documentation.

## Nginx Proxy Server

The dev environment includes an nginx reverse proxy server that forwards all HTTP traffic to `https://httpbin.org/anything`. This is useful for testing HTTP clients and inspecting request details.

For detailed information about the nginx configuration, see [projects/dev/NGINX_PROXY.md](projects/dev/NGINX_PROXY.md).

### Cloud Function Module Usage

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

## Project Structure

```
tf-infra/
├── modules/              # Reusable Terraform modules
│   └── cloud-function/  # Cloud Function module
├── projects/            # Project-specific configurations
│   └── dev/            # Development environment
│       ├── main.tf     # Main infrastructure configuration
│       ├── backend.tf  # Remote state backend configuration
│       ├── variables.tf # Variable definitions
│       ├── outputs.tf  # Output values
│       └── NGINX_PROXY.md # Nginx proxy documentation
└── README.md           # This file
```

## Extending the Infrastructure

This is a base configuration. You can extend it by adding:

- Additional Compute Engine instances
- Cloud SQL databases
- Cloud Load Balancers
- Cloud Storage buckets
- IAM roles and policies
- Kubernetes Engine clusters
- Custom Cloud Functions (using the provided module)
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
cd projects/dev
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources created by this configuration, including:
- The VPC network and subnet
- Firewall rules
- The nginx VM instance
- The static external IP address
