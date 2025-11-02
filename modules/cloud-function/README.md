# Cloud Function Module

> **Note**: This repository is not open to contributions. Please do not submit pull requests.

This module creates a Google Cloud Function (2nd gen) with HTTP trigger and configurable options.

## Features

- ✅ HTTP-triggered Cloud Function
- ✅ Configurable runtime (Node.js, Python, Go, Java, etc.)
- ✅ Environment variables support
- ✅ VPC connector integration
- ✅ Configurable memory and timeout
- ✅ Min/max instance scaling
- ✅ IAM access control
- ✅ Labels and custom service accounts

## Usage

### Basic Example

```hcl
module "hello_function" {
  source = "./modules/cloud-function"

  function_name          = "hello-world"
  runtime                = "python39"
  entry_point            = "hello"
  source_archive_bucket  = "my-function-bucket"
  source_archive_object  = "functions/hello.zip"
  
  project_id = var.project_id
  region     = var.region
}
```

### Advanced Example

```hcl
module "api_function" {
  source = "./modules/cloud-function"

  function_name         = "api-handler"
  description           = "Handles API requests"
  runtime               = "python39"
  entry_point           = "main"
  source_archive_bucket = "my-bucket"
  source_archive_object = "functions/api.zip"
  
  available_memory_mb   = 512
  timeout               = 120
  
  environment_variables = {
    API_KEY    = "secret-key"
    DEBUG_MODE = "true"
  }
  
  labels = {
    environment = "production"
    team        = "backend"
  }
  
  service_account_email = "my-function@project.iam.gserviceaccount.com"
  
  max_instances = 10
  min_instances = 1
  
  allow_unauthenticated_invocations = true
  
  project_id = var.project_id
  region     = var.region
}
```

### With VPC Connector

```hcl
module "vpc_function" {
  source = "./modules/cloud-function"

  function_name         = "vpc-connected-function"
  runtime               = "python39"
  entry_point           = "handler"
  source_archive_bucket = "my-bucket"
  source_archive_object = "functions/vpc.zip"
  
  vpc_connector_name            = "my-vpc-connector"
  vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
  
  project_id = var.project_id
  region     = var.region
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
| function_name | The name of the Cloud Function | `string` | n/a | yes |
| entry_point | The name of the function (as defined in source code) | `string` | n/a | yes |
| source_archive_bucket | The GCS bucket name containing the zip archive | `string` | n/a | yes |
| source_archive_object | The source archive object (file) in archive bucket | `string` | n/a | yes |
| project_id | The GCP project ID | `string` | n/a | yes |
| region | Region where function will be deployed | `string` | n/a | yes |
| description | Description of the Cloud Function | `string` | `null` | no |
| runtime | The runtime in which the function will run | `string` | `"go125"` | no |
| available_memory_mb | Memory (in MB) available to the function | `number` | `256` | no |
| timeout | Timeout (in seconds) for the function | `number` | `60` | no |
| environment_variables | A set of key/value environment variable pairs | `map(string)` | `{}` | no |
| labels | A set of key/value label pairs | `map(string)` | `{}` | no |
| service_account_email | Service account email | `string` | `null` | no |
| allow_unauthenticated_invocations | Whether to allow unauthenticated invocations | `bool` | `false` | no |
| security_level | The security level for the function | `string` | `"SECURE_ALWAYS"` | no |
| vpc_connector_name | The VPC Network Connector name | `string` | `null` | no |
| vpc_connector_egress_settings | The egress settings for the connector | `string` | `null` | no |
| max_instances | Limit on the maximum number of function instances | `number` | `null` | no |
| min_instances | The limit on the minimum number of function instances | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| function_name | The name of the Cloud Function |
| function_id | An identifier for the resource |
| function_url | The URL of the Cloud Function |
| function_service_account_email | The service account email for the function |
| function_runtime | The runtime of the Cloud Function |
| function_available_memory_mb | The amount of memory available to the function |

## Preparing Your Function Code

### For Python

1. Create a `main.py` file:
```python
def hello(request):
    return f'Hello World!'
```

2. Create a `requirements.txt` file (optional):
```
flask==2.0.0
requests==2.28.0
```

3. Package your function:
```bash
zip -r function.zip main.py requirements.txt
gsutil cp function.zip gs://your-bucket/functions/
```

### For Node.js

1. Create an `index.js` file:
```javascript
exports.hello = (req, res) => {
  res.send('Hello World!');
};
```

2. Create a `package.json` file:
```json
{
  "name": "hello-world",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

3. Package your function:
```bash
npm install
zip -r function.zip *
gsutil cp function.zip gs://your-bucket/functions/
```

## Notes

- Ensure you have the necessary APIs enabled:
  - Cloud Functions API
  - Cloud Build API
  - Artifact Registry API (for 2nd gen functions)

- To enable APIs:
```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```
