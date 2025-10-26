# Terraform Modules

This repository follows a modular architecture to promote code reusability and maintainability.

## Structure

```
.
├── main.tf                    # Root module configuration
├── variables.tf               # Root module variables
├── outputs.tf                 # Root module outputs
├── modules/                   # Reusable modules
│   └── cloud-function/        # Cloud Function module
│       ├── main.tf           # Module resources
│       ├── variables.tf      # Module variables
│       ├── outputs.tf        # Module outputs
│       └── README.md         # Module documentation
└── examples/                  # Example usage
    └── cloud-function-demo/  # Complete example
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
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

#### Example

See [examples/cloud-function-demo/](examples/cloud-function-demo/) for a complete working example that demonstrates:

- Deploying multiple functions
- Different configuration patterns
- Environment variables and labels
- Public vs private access
- Autoscaling configuration

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
- Load Balancer module
- Kubernetes module
- IAM module
- Monitoring module
