resource "google_service_account" "gke_nodes" {
  account_id   = var.runner_pool_sa
  display_name = "GKE Nodes Service Account"
  description  = "Service account for GKE runner nodes to pull images and write logs"
}

resource "google_project_iam_member" "github_action_sa_roles" {
  for_each = toset(var.runner_pool_sa_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.gke_nodes.email}"
}
resource "google_container_node_pool" "runner_pool" {
  name       = var.runner_pool_name
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true # Preemptible for cost savings
    machine_type = "n1-standard-1"


    service_account = google_service_account.gke_nodes.email
    labels = {
      workload-type = "runner"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  depends_on = [google_container_cluster.primary]
}
