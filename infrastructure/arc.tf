# --- Variables ---


# --- GCP Secret Manager Data Sources ---
# These secrets must be pre-created in GCP Secret Manager
data "google_secret_manager_secret_version" "github_app_id" {
  secret = "github-app-id"
}

data "google_secret_manager_secret_version" "github_app_installation_id" {
  secret = "github-app-installation-id"
}

data "google_secret_manager_secret_version" "github_app_private_key" {
  secret = "github-app-private-key"
}

# # --- Namespace ---
# resource "kubernetes_namespace_v1" "arc_system" {
#   metadata {
#     name = "arc-system"
#   }
#   depends_on = [google_container_cluster.primary, google_container_node_pool.primary_nodes]
# }

# resource "kubernetes_namespace_v1" "arc_runners" {
#   metadata {
#     name = "arc-runners"
#   }
#   depends_on = [google_container_cluster.primary, google_container_node_pool.primary_nodes]
# }
# resource "kubernetes_secret_v1" "github_creds" {
#   metadata {
#     name      = "github-app-creds"
#     namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
#   }

#   data = {
#     github_app_id              = data.google_secret_manager_secret_version.github_app_id.secret_data
#     github_app_installation_id = data.google_secret_manager_secret_version.github_app_installation_id.secret_data
#     github_app_private_key     = data.google_secret_manager_secret_version.github_app_private_key.secret_data
#   }

#   type = "Opaque"
# }

# # --- ARC Controller ---
# resource "helm_release" "arc_controller" {
#   name       = "arc-controller"
#   repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
#   chart      = "gha-runner-scale-set-controller"
#   version    = "0.9.3"
#   namespace  = kubernetes_namespace_v1.arc_system.metadata[0].name
# }

# --- Runner Scale Set ---
resource "helm_release" "arc_runner_set" {
  name       = var.arc_runner_name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = "0.9.3"
  namespace  = kubernetes_namespace_v1.arc_runners.metadata[0].name

  set = [
    {
      name  = "githubConfigSecret"
      value = kubernetes_secret_v1.github_creds.metadata[0].name
    },
    {
      name  = "githubConfigUrl"
      value = var.github_config_url
    }
  ]

  depends_on = [
    google_container_node_pool.primary_nodes,
    google_service_account.default,
    helm_release.arc_controller
  ]
}
