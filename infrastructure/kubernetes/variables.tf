variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

variable "cluster_name" {
  default     = "self-hosted"
  description = "Runner Kubernetes cluster"
}

variable "arc_runner_name" {
  default     = "self-hosted"
  description = "Runner Kubernetes cluster"
}
