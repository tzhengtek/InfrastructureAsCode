project_id        = "iac-epitech-dev"
region            = "europe-west1"
zone              = "europe-west1-b"
vpc_name          = "vpc"
cidr_block        = "10.0.0.0/16"
cluster_name      = "iac-runner-dev"
github_config_url = "https://github.com/tzhengtek/InfrastructureAsCode"
runner_pool_name  = "iac-runner-pool"
arc_runner_name   = "self-hosted-runner"
runner_pool_sa    = "runner-pool-sa"
runner_pool_sa_roles = [
  "roles/artifactregistry.reader",
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter"
]
