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


// OIDC GITHUB  //

variable "github_url" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}

variable "github_project_id" {
  type        = string
  description = "Github Project ID"
}

variable "github_org" {
  type        = string
  description = "GitHub organization allowed to authenticate"
}
