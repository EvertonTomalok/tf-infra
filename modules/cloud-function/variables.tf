variable "function_name" {
  description = "The name of the Cloud Function"
  type        = string
}

variable "description" {
  description = "Description of the Cloud Function"
  type        = string
  default     = null
}

variable "runtime" {
  description = "The runtime in which the function is going to run. Examples: nodejs10, python39, go111"
  type        = string
  default     = "go125"
}

variable "entry_point" {
  description = "The name of the function (as defined in source code) that will be executed"
  type        = string
}

variable "source_archive_bucket" {
  description = "The GCS bucket name containing the zip archive which contains the function"
  type        = string
}

variable "source_archive_object" {
  description = "The source archive object (file) in archive bucket"
  type        = string
}

variable "available_memory_mb" {
  description = "Memory (in MB), available to the function. Defaults to 256"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Timeout (in seconds) for the function. Defaults to 60"
  type        = number
  default     = 60
}

variable "environment_variables" {
  description = "A set of key/value environment variable pairs to assign to the function"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the Cloud Function"
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Service account email. If empty, defaults to Compute Engine default service account"
  type        = string
  default     = null
}

variable "allow_unauthenticated_invocations" {
  description = "Whether to allow unauthenticated invocations of the function"
  type        = bool
  default     = false
}

variable "security_level" {
  description = "The security level for the function. Can be either SECURE_ALWAYS, SECURE_OPTIONAL, or INSECURE."
  type        = string
  default     = "SECURE_ALWAYS"
}

variable "vpc_connector_name" {
  description = "The VPC Network Connector that this cloud function can connect to"
  type        = string
  default     = null
}

variable "vpc_connector_egress_settings" {
  description = "The egress settings for the connector. Possible values: ALL_TRAFFIC, PRIVATE_RANGES_ONLY"
  type        = string
  default     = null
}

variable "max_instances" {
  description = "Limit on the maximum number of function instances that may coexist at a given time"
  type        = number
  default     = null
}

variable "min_instances" {
  description = "The limit on the minimum number of function instances that may coexist at a given time"
  type        = number
  default     = null
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "Region where function will be deployed"
  type        = string
}
