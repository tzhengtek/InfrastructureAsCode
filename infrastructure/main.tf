terraform {
  backend "gcs" {
  }
}

# resource "google_compute_network" "main" {
#   name                    = var.vpc_name
#   auto_create_subnetworks = false
# }

# resource "google_compute_subnetwork" "main" {
#   name          = "${var.vpc_name}-subnet"
#   ip_cidr_range = "10.0.1.0/24"
#   region        = var.region
#   network       = google_compute_network.main.id
# }


# output "vpc_id" {
#   value       = google_compute_network.main.id
#   description = "The ID of the created VPC"
# }

# // --------------------------------------
