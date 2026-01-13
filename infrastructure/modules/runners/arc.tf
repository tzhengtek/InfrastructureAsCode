
resource "kubernetes_namespace_v1" "arc_runners" {
  metadata {
    name = "arc-runners"
  }
}

# USE GOOGLE SECRET
# data "google_secret_manager_secret_version" "github_repo_token" {
#   secret  = var.github_repo_token
#   version = "latest"
# }

resource "helm_release" "arc_controller" {
  name             = "arc-system"
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = "0.9.0"
  namespace        = "arc-systems"
  create_namespace = true

}

# USE GOOGLE SECRET
# data "google_secret_manager_secret_version" "github_repo_token" {
#   secret  = var.github_repo_token
#   version = "latest"
# }

resource "kubernetes_secret_v1" "github_secret" {
  metadata {
    name      = "github-secret"
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
  }

  data = {
    github_token = var.github_repo_token
  }
}

resource "helm_release" "arc_runner_set" {
  name       = "self-hosted-runner"
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
    name  = "template.spec.containers[0].name"
    value = "runner"
  }

  set {
    name  = "template.spec.containers[0].command[0]"
    value = "/home/runner/run.sh"
  }

  set {
    name  = "githubConfigSecret"
    value = kubernetes_secret_v1.github_secret.metadata[0].name
  }
  # 1. Point to your Custom Image in Artifact Registry
  set {
    name  = "template.spec.containers[0].image"
    value = var.runner_image_url
  }

  set {
    name  = "template.spec.containers[0].imagePullPolicy"
    value = "Always"
  }
}
