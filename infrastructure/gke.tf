# 1. The Cluster Control Plane
resource "google_container_cluster" "primary" {
  name     = "github-runner-cluster"
  location = var.region


  # We delete the default node pool to use a custom managed one below
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false
}

# 2. The Worker Node Pool (Where runners live)
resource "google_container_node_pool" "primary_nodes" {
  name       = "runner-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    # Scopes needed fo the nodes to function
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
