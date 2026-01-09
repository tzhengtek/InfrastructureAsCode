# resource "helm_release" "arc_controller" {
#   name             = "arc-system"
#   repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
#   chart            = "gha-runner-scale-set-controller"
#   version          = "0.9.0"
#   namespace        = "arc-systems"
#   create_namespace = true
# }
