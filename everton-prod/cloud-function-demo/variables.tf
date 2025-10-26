variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "demo"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "function_bucket" {
  description = "GCS bucket where function source archives are stored"
  type        = string
}
