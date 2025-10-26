# Example: Deploying a Cloud Function using the module
# This example demonstrates how to use the cloud-function module

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Example Cloud Function - Hello World
module "hello_function" {
  source = "../../modules/cloud-function"

  function_name         = "${var.project_name}-hello-world"
  description           = "Simple Hello World Cloud Function"
  runtime               = "python39"
  entry_point           = "hello_world"
  source_archive_bucket = var.function_bucket
  source_archive_object = "hello-world.zip"

  available_memory_mb = 256
  timeout             = 60

  environment_variables = {
    ENVIRONMENT = "demo"
    MESSAGE     = "Hello from Cloud Function!"
  }

  labels = {
    environment = "demo"
    managed-by  = "terraform"
  }

  allow_unauthenticated_invocations = true
  min_instances                     = 0
  max_instances                     = 5

  project_id = var.project_id
  region     = var.region
}

# Example Cloud Function - API Handler with more resources
module "api_function" {
  source = "../../modules/cloud-function"

  function_name         = "${var.project_name}-api-handler"
  description           = "API handler with more memory and timeout"
  runtime               = "python39"
  entry_point           = "main"
  source_archive_bucket = var.function_bucket
  source_archive_object = "api-handler.zip"

  available_memory_mb = 512
  timeout             = 300 # 5 minutes

  environment_variables = {
    ENV          = "production"
    API_VERSION  = "v1"
    DB_HOST      = "example.com"
    LOG_LEVEL    = "INFO"
  }

  labels = {
    environment = "production"
    component   = "api"
    managed-by  = "terraform"
  }

  allow_unauthenticated_invocations = false
  min_instances                     = 1
  max_instances                     = 10

  project_id = var.project_id
  region     = var.region
}
