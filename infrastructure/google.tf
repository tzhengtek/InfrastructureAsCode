resource "google_iam_workload_identity_pool" "gitlab-pool" {
  workload_identity_pool_id = "github-action-pool"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "github-provider-oidc" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  project                            = var.project_id
  attribute_condition                = "assertion.repository_owner == '${var.github_org}'"
  attribute_mapping = {
    "google.subject"             = "assertion.sub", # Required
    "attribute.aud"              = "assertion.aud",
    "attribute.repo"             = "assertion.repository"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    #
    "attribute.project_path"   = "assertion.project_path",
    "attribute.project_id"     = "assertion.project_id",
    "attribute.namespace_id"   = "assertion.namespace_id",
    "attribute.namespace_path" = "assertion.namespace_path",
    "attribute.user_email"     = "assertion.user_email",
    "attribute.ref"            = "assertion.ref",
    "attribute.ref_type"       = "assertion.ref_type",
  }
  oidc {
    issuer_uri        = var.github_url
    allowed_audiences = [var.github_url]
  }
}

resource "google_service_account" "github_action" {
  account_id   = "github-action-sa"
  display_name = "GitHub Actions Service Account"
}


resource "google_service_account_iam_binding" "github_action_binding" {
  service_account_id = google_service_account.github_action.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab-pool.name}/attribute.repository_owner/${var.github_org}"
  ]
}
