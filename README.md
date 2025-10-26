# Terraform Infrastructure for GCP

A base Terraform repository for Google Cloud Platform (GCP) infrastructure provisioning.

## Features

- ✅ VPC network with custom subnet configuration
- ✅ Firewall rules for SSH, HTTP, and HTTPS
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

2. **Configure your variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Review the execution plan**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **View outputs**:
   ```bash
   terraform output
   ```

## Configuration

### Required Variables

- `project_id`: Your GCP project ID

### Optional Variables

- `project_name`: Prefix for resource names (default: "tf-infra")
- `region`: GCP region (default: "us-central1")
- `subnet_cidr`: Subnet CIDR block (default: "10.0.1.0/24")

## Remote State Backend

To use Google Cloud Storage (GCS) as the backend for remote state:

1. Create a GCS bucket (if you don't have one):
   ```bash
   gsutil mb -p <PROJECT_ID> -l us-central1 gs://<BUCKET_NAME>
   ```

2. Update the backend configuration in `main.tf`:
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "your-terraform-state-bucket"
       prefix = "terraform/state"
     }
   }
   ```

3. Re-initialize Terraform:
   ```bash
   terraform init -migrate-state
   ```

## Resources Created

- **VPC Network**: Custom VPC with manual subnet creation
- **Subnet**: Regional subnet within the VPC
- **Firewall Rules**:
  - SSH access (port 22) from anywhere
  - HTTP/HTTPS access (ports 80, 443) from anywhere

## Modules

This repository includes reusable modules for common infrastructure patterns.

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
