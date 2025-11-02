# Terraform Modules

> **Note**: This repository is not open to contributions. Please do not submit pull requests.

This repository follows a modular architecture to promote code reusability and maintainability.

## Structure

```
.
├── projects/                  # Environment-specific configurations
├── modules/                   # Reusable modules
│   ├── cloud-function/        # Cloud Function module
│   ├── cloud-engine/         # Cloud Engine module
│   ├── load-balancer/        # Load Balancer module
│   └── ...
```

## Available Modules

### Cloud Function Module

The Cloud Function module (`modules/cloud-function`) provides a reusable way to deploy Google Cloud Functions with comprehensive configuration options.

#### Key Features

- HTTP-triggered Cloud Functions
- Configurable runtime (Python, Node.js, Go, Java, etc.)
- Environment variables support
- Custom memory and timeout settings
- Min/max instance scaling
- VPC connector integration
- IAM access control
- Labels and custom service accounts

#### Quick Start

```hcl
module "my_function" {
  source = "./modules/cloud-function"

  function_name         = "my-function"
  runtime               = "python39"
  entry_point           = "main"
  source_archive_bucket = "my-bucket"
  source_archive_object = "functions/my-function.zip"
  
  project_id = var.project_id
  region     = var.region
}
```

#### Documentation

See [modules/cloud-function/README.md](modules/cloud-function/README.md) for detailed documentation.

#### Example Usage

See `projects/dev/main.tf` for examples of module usage in a complete infrastructure setup.

### Cloud Engine Module

The Cloud Engine module (`modules/cloud-engine`) provides a reusable way to deploy Google Compute Engine VM instances with Ubuntu 22.04 LTS and pre-configured nginx as a reverse proxy. The nginx instance includes a circuit breaker pattern for high availability with automatic failover between primary and fallback backends.

#### Key Features

- Ubuntu 22.04 LTS VM instances
- Pre-configured nginx reverse proxy with circuit breaker pattern
- Automatic health check endpoint setup (`/health`)
- Customizable SSH keys
- Static external IP support
- VPC and subnet integration
- Startup script automation with comprehensive logging

#### Quick Start

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

The Load Balancer module (`modules/load-balancer`) provides a reusable HTTP(S) global load balancer with health checks, backend services, and optional SSL certificate support.

#### Key Features

- Global HTTP(S) load balancer
- Optional HTTPS support with SSL certificates
- Automatic HTTP to HTTPS redirect (when SSL configured)
- Health check configuration with configurable path and port
- Multi-backend support with multiple instance groups
- Utilization-based load balancing
- Path-based routing support
- Connection draining
- Configurable capacity scaling

#### Quick Start

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

## Creating New Modules

To create a new module:

1. Create a directory under `modules/your-module-name/`
2. Add the following files:
   - `main.tf` - Define the resources
   - `variables.tf` - Define input variables
   - `outputs.tf` - Define output values
   - `README.md` - Document the module
3. Follow the same structure and naming conventions as existing modules

## Module Best Practices

1. **Keep modules focused**: Each module should have a single, well-defined purpose
2. **Use descriptive names**: Module and resource names should clearly indicate their purpose
3. **Document thoroughly**: Include examples and clear descriptions
4. **Version appropriately**: Use version constraints in your root configurations
5. **Test with examples**: Create example configurations to demonstrate usage
6. **Use variables**: Make modules configurable but provide sensible defaults
7. **Output useful values**: Export values that consumers of the module might need

## Module Usage in Root Configuration

To use a module in your root configuration:

```hcl
module "resource_name" {
  source = "./modules/module_name"
  
  # Required variables
  required_var = "value"
  
  # Optional variables with defaults
  optional_var = "value"  # if you want to override the default
  
  # Connect to other resources
  dependency = google_resource.example.id
}
```

## Benefits of Modular Architecture

- **Reusability**: Write once, use many times
- **Maintainability**: Changes in one place affect all usages
- **Testability**: Test modules independently
- **Organization**: Clear structure and separation of concerns
- **Collaboration**: Teams can work on different modules
- **Best Practices**: Enforce consistent patterns across projects

## Future Modules

Potential modules to add in the future:

- Cloud SQL module
- Cloud Storage module
- Kubernetes module
- IAM module
- Monitoring module
