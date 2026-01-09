// GCP Variables
variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
}

variable "zone" {
  type        = string
  description = "Zone for resources"
}

// Cluster Variable

variable "cluster_name" {
  description = "Runner Kubernetes cluster"
  type        = string
}

variable "runner_pool_name" {
  description = "Runner Pool name"
  type        = string
}
