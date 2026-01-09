# Runner Node Pool - For GitHub Actions runners (autoscaling)
resource "google_container_node_pool" "runner_pool" {
  name       = var.runner_pool_name
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true # Preemptible for cost savings
    machine_type = "n1-standard-1"

    labels = {
      workload-type = "runner"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  depends_on = [google_container_cluster.primary]
}
