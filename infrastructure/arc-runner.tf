# 1. Create a namespace for the runners
resource "kubernetes_namespace_v1" "arc_runners" {
  metadata {
    name = "arc-runners"
  }
}

data "google_secret_manager_secret_version" "github_token" {
  secret  = var.github_repo_token
  version = "latest"
}

resource "kubernetes_secret_v1" "github_secret" {
  metadata {
    name      = "github-secret"
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
  }

  data = {
    github_token = google_secret_manager_secret_version.github_repo_token
  }
}

resource "helm_release" "arc_runner_set" {
  name       = "arc-runner-set"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = "0.9.0"
  namespace  = kubernetes_namespace_v1.arc_runners.metadata[0].name

  depends_on = [helm_release.arc_controller]

  set {
    name  = "githubConfigUrl"
    value = var.github_config_url
  }

  set {
    name  = "githubConfigSecret"
    value = kubernetes_secret_v1.github_secret.metadata[0].name
  }
}
