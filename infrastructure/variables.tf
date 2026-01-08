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

// VPC //
variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

// DATABASE //
variable "db_name" {
  type        = string
  description = "Name of the database"
  default     = "app-db"
}

variable "db_user" {
  type        = string
  description = "Database user name"
  sensitive   = true
}

variable "db_pwd" {
  type        = string
  description = "Database user name"
  sensitive   = true
}

// 

variable "github_config_url" {
  type        = string
  description = "URL of the repo or org: https://github.com/my-org/my-repo"
}

// //
// APP SECRET //

variable "jwt_secret" {
  type        = string
  description = "JWT Secret for token generation"
  sensitive   = true
}
variable "ssl_cert" {
  type        = string
  description = "ssl certificate"
  sensitive   = true
}
variable "ssl_key" {
  type        = string
  description = "ssl certificate"
  sensitive   = true
}
variable "app_id" {
  type        = string
  description = "github app id"
  sensitive   = true
}

variable "app_installation_id" {
  type        = string
  description = "github installation id"
  sensitive   = true
}

variable "app_private_key" {
  type        = string
  description = "github private key"
  sensitive   = true
}

// REPO GITHUB

variable "github_repo_token" {
  type        = string
  description = "github repo token"
  sensitive   = true
}


// CLUSTER 


variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

variable "cluster_name" {
  default     = "self-hosted"
  description = "Runner Kubernetes cluster"
}

variable "arc_runner_name" {
  default     = "self-hosted"
  description = "Runner Kubernetes cluster"
}
