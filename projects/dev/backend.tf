# Configure backend for state management
# Uncomment to use GCS backend
terraform {
  backend "gcs" {
    bucket = "everton_infra"
    prefix = "terraform/state/projects/dev"
  }
}