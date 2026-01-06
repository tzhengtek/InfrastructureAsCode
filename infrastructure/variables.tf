variable "project_id" {
  type        = string
  description = "Cloud project ID"
}

variable "region" {
  type        = string
  description = "Region for resources"
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
variable "github_app_id" {
  type        = string
  description = "github app id"
  sensitive   = true
}

variable "github_installation_id" {
  type        = string
  description = "github installation id"
  sensitive   = true
}

variable "github_private_key" {
  type        = string
  description = "github installation id"
  sensitive   = true
}
