project_id          = "iac-epitech-dev"
region              = "europe-west1"
zone                = "europe-west1-b"
vpc_name            = "vpc"
cidr_block          = "10.0.0.0/16"
cluster_name        = "iac-cluster-dev"
github_config_url   = "https://github.com/tzhengtek/InfrastructureAsCode"
runner_pool_name    = "iac-runner-pool"
arc_runner_name     = "self-hosted-runner"
app_name            = "iac-app-dev"
deletion_protection = false // set to true for production
runner_pool_sa      = "runner-pool-sa"
runner_pool_sa_roles = [
  "roles/artifactregistry.reader",
  "roles/logging.logWriter",
  "roles/monitoring.metricWriter"
]

app_pool_sa = "app-pool-sa"
app_pool_sa_roles = [
  "roles/cloudsql.client",
  "roles/cloudsql.viewer",
  "roles/artifactregistry.reader"
]
