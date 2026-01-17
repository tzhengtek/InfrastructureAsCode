resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  network    = var.vpc_name
  subnetwork = var.subnet_name

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = var.deletion_protection

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = ""
    services_secondary_range_name = ""
  }
}
