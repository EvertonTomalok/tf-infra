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

variable "instance_group_a_id" {
  description = "ID of the first instance group (server_a)"
  type        = string
}

variable "instance_group_b_id" {
  description = "ID of the second instance group (server_b)"
  type        = string
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

