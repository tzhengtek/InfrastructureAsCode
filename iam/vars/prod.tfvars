project_id = "iac-epitech-prod"
region     = "europe-west1"

gcp_iam_members = {
  "jeremie@jjaouen.com"      = ["roles/reader", "roles/viewer"]
  "leosoidiki28@gmail.com"   = ["roles/admin"]
  "angeduhayonepi@gmail.com" = ["roles/admin"]
  "jinantony11@gmail.com"    = ["roles/admin"]
}

github_iam_members = {
  "Kloox"          = "read"
  "Dwozy"          = "admin"
  "AustralEpitech" = "admin"
  "Antonyjin"      = "admin"
}

github_token_secret_name = "github-token"
