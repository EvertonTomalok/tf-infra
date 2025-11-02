variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "name" {
  description = "Name for the load balancer resources"
  type        = string
  default     = "lb"
}

variable "instance_groups" {
  description = "Map of instance groups to use as backends"
  type = map(object({
    group            = string
    balancing_mode   = string
    capacity_scaler  = number
    max_utilization  = number
  }))
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
}

variable "ssl_certificates" {
  description = "List of SSL certificate self links to use for HTTPS"
  type        = list(string)
  default     = []
}

variable "path_routes" {
  description = "Map of path patterns to backend services for path-based routing"
  type = map(object({
    service = string
  }))
  default = {}
}

