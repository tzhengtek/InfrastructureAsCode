# ==============================================================================
# ARTIFACT REGISTRY CONFIGURATION
# ==============================================================================
# This file creates a Docker image repository on Google Cloud
# Think of it as a "library" where you store your app's recipe books (Docker images)
# ==============================================================================

# ------------------------------------------------------------------------------
# ARTIFACT REGISTRY REPOSITORY
# ------------------------------------------------------------------------------
# This is where your Docker images (containerized app) will be stored
resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region       # europe-west1
  repository_id = "perth-app-repo" # Name of your repository
  description   = "Docker repository for Perth Task Manager application"
  format        = "DOCKER"         # We're storing Docker images

  # Labels for organization
  labels = {
    environment = "dev"
    managed_by  = "terraform"
    app         = "task-manager"
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================
# These values can be used to push/pull images

output "artifact_registry_repository" {
  description = "Full name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.app_repo.name
}

output "docker_image_path" {
  description = "Path where Docker images should be pushed"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app_repo.repository_id}"
}
