
module "cluster" {
  source = "./modules/cluster"

  cluster_name         = var.cluster_name
  runner_pool_name     = var.runner_pool_name
  project_id           = var.project_id
  region               = var.region
  zone                 = var.zone
  runner_pool_sa       = var.runner_pool_sa
  runner_pool_sa_roles = var.runner_pool_sa_roles
  deletion_protection  = var.deletion_protection
}

module "runners" {
  source = "./modules/runners"

  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  github_config_url = var.github_config_url
  arc_runner_name   = var.arc_runner_name
  runner_image_url  = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.runners.repository_id}/runner:latest"

  depends_on = [module.cluster, google_artifact_registry_repository.runners]
}

module "database" {
  source = "./modules/database"

  db_name = var.db_name
  region  = var.region

  private_vpc_connection = google_service_networking_connection.private_vpc_connection
  vpc                    = google_compute_network.vpc
  deletion_protection    = var.deletion_protection
  depends_on             = [google_service_networking_connection.private_vpc_connection]
}
