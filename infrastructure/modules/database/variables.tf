// DATABASE //
variable "region" {
  type        = string
  description = "Region for resources"
}

variable "db_name" {
  type        = string
  description = "Name of the database"
  default     = "app-db"
}

variable "private_vpc_connection" {
  description = "Gcp Network connection"
  type        = any
}

variable "vpc" {
  description = "VPC value"
  type        = any
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

