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

# --- Namespace ---
resource "kubernetes_namespace_v1" "arc_system" {
  metadata {
    name = "arc-system"
  }
}

resource "kubernetes_namespace_v1" "arc_runners" {
  metadata {
    name = "arc-runners"
  }
}

# --- Kubernetes Secret for GitHub Auth (populated from GCP Secret Manager) ---
resource "kubernetes_secret_v1" "github_creds" {
  metadata {
    name      = "github-app-creds"
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
  }

  data = {
    github_app_id              = data.google_secret_manager_secret_version.github_app_id.secret_data
    github_app_installation_id = data.google_secret_manager_secret_version.github_app_installation_id.secret_data
    github_app_private_key     = data.google_secret_manager_secret_version.github_app_private_key.secret_data
  }

  type = "Opaque"
}

# --- ARC Controller ---
resource "helm_release" "arc_controller" {
  name       = "arc-controller"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = "0.9.3"
  namespace  = kubernetes_namespace_v1.arc_system.metadata[0].name
}

# --- Runner Scale Set ---
resource "helm_release" "arc_runner_set" {
  name       = var.arc_runner_name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = "0.9.3"
  namespace  = kubernetes_namespace_v1.arc_runners.metadata[0].name

  # Point to the secret we created above
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


  # Optional: Configure the runner specs (image, dind, etc.)
  # This enables Docker-in-Docker so you can run 'docker' commands in your CI
  # set {
  #   name  = "containerMode.type"
  #   value = "dind"
  # }

  depends_on = [helm_release.arc_controller]
}
