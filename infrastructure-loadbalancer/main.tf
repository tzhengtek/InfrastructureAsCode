terraform {
  backend "gcs" {
    bucket = "iac-epitech-storage"
    prefix = "dev/terraform/loadbalancer"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
