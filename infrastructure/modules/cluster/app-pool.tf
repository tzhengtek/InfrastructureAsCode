# Optional: General Purpose Node Pool
resource "google_container_node_pool" "application_pool" {
  name     = "application-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  autoscaling {
    min_node_count  = 1
    max_node_count  = 10
    location_policy = "BALANCED"
  }

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    labels = {
      workload-type = "application"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enable Workload Identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  depends_on = [google_container_cluster.primary]
}
