resource "google_iam_workload_identity_pool" "github-action-pool" {
  workload_identity_pool_id = "github-action-pool"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github-provider-oidc" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-action-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  project                            = var.project_id
  attribute_condition                = "assertion.repository_owner == '${var.github_org}'"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.aud"        = "assertion.aud"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
  }
  oidc {
    issuer_uri = var.github_url
    # allowed_audiences = [var.github_url]
  }
}

resource "google_service_account" "github_action" {
  account_id   = "github-action-sa"
  display_name = "GitHub Actions Service Account"
  project      = var.project_id
}


resource "google_service_account_iam_binding" "github_action_workload_identity" {
  service_account_id = google_service_account.github_action.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-action-pool.name}/attribute.repository_owner/${var.github_org}"
  ]
}
resource "google_service_account_iam_binding" "github_action_admin" {
  service_account_id = google_service_account.github_action.name
  role               = "roles/iam.serviceAccountAdmin"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-action-pool.name}/attribute.repository_owner/${var.github_org}"
  ]
}
resource "google_storage_bucket_iam_member" "terraform_state_access" {
  bucket = "iac-epitech-storage"
  role   = "roles/storage.objectAdmin"
  member = "user:${google_service_account.github_action.account_id}@${var.project_id}.iam.gserviceaccount.com"
}
