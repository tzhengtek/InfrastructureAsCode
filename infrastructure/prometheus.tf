resource "google_project_service" "monitoring" {
  project = var.project_id
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_container_cluster" "gke" {
  name               = "observability-cluster"
  location           = var.region
  initial_node_count = 1
  deletion_protection = false
  node_config {
    disk_size_gb = 50
    disk_type    = "pd-standard"
  }

  monitoring_config {
    managed_prometheus {
      enabled = true
    }
  }
}
