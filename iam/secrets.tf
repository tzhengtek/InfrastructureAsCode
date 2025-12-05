data "google_secret_manager_secret_version" "github_token" {
  secret  = var.github_token_secret_name
  version = "1"
}
