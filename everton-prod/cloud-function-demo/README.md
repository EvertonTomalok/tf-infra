# Cloud Function Demo Example

This example demonstrates how to use the Cloud Function module to deploy multiple serverless functions.

## Prerequisites

1. A GCP project with billing enabled
2. Cloud Functions API enabled:
   ```bash
   gcloud services enable cloudfunctions.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   ```
3. A GCS bucket to store function source archives
4. Function source code packaged as zip files

## Preparing Function Code

### For the Hello World function

Create a `hello-world` directory with:

**main.py:**
```python
def hello_world(request):
    """
    HTTP Cloud Function.
    Args:
        request (flask.Request): The request object.
        Returns:
            The response text, or any set of values that can be turned into a
            Response object using `make_response`
    """
    return f'Hello World! Environment: {os.environ.get("MESSAGE", "default")}'
```

**requirements.txt:**
```
functions-framework==3.2.0
```

Package it:
```bash
cd hello-world
zip -r ../hello-world.zip .
cd ..
gsutil cp hello-world.zip gs://YOUR-BUCKET-NAME/hello-world.zip
```

### For the API Handler function

Create an `api-handler` directory with similar structure.

## Usage

1. **Configure variables:**

Create a `terraform.tfvars` file:
```hcl
project_id     = "your-project-id"
project_name   = "demo"
region         = "us-central1"
function_bucket = "your-bucket-name"
```

2. **Initialize Terraform:**
```bash
terraform init
```

3. **Review the plan:**
```bash
terraform plan
```

4. **Apply the configuration:**
```bash
terraform apply
```

5. **Test the functions:**
```bash
# Get the function URLs
terraform output

# Test the Hello World function
curl $(terraform output -raw hello_function_url)
```

## What Gets Created

- **hello_function**: A simple Cloud Function with 256MB memory, 60s timeout, allowing unauthenticated invocations
- **api_function**: A more robust Cloud Function with 512MB memory, 5min timeout, requiring authentication

## Features Demonstrated

- Multiple function deployments
- Different configurations (memory, timeout, scaling)
- Environment variables
- Labels and organization
- Public vs private access
- Autoscaling (min/max instances)

## Cleanup

To destroy all resources:
```bash
terraform destroy
```
