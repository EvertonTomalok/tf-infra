variable "project_name" {
  description = "the ngnix project name"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "network" {
  description = "network ip"
  type        = string
}

variable "subnetwork" {
  description = "subnetwork"
  type        = string
}

variable "nat_ip" {
  description = "nat ip"
  type        = string
}