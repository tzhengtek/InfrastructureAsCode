resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "jwt-secret-id"

  replication {
    auto {}
  }
  labels = {
    managed_by = "terraform"
    source     = "github-secrets"
    app        = "backend"
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = var.jwt_secret
}


resource "google_secret_manager_secret" "ssl_cert" {
  secret_id = "ssl-cert-id"

  replication {
    auto {}
  }
  labels = {
    managed_by = "terraform"
    source     = "github-secrets"
    app        = "backend"
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "ssl_cert" {
  secret      = google_secret_manager_secret.ssl_cert.id
  secret_data = var.ssl_cert
}


resource "google_secret_manager_secret" "ssl_key" {
  secret_id = "ssl-key-id"

  replication {
    auto {}
  }
  labels = {
    managed_by = "terraform"
    source     = "github-secrets"
    app        = "backend"
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "ssl_key" {
  secret      = google_secret_manager_secret.ssl_key.id
  secret_data = var.ssl_key
}


// DATABASE //

resource "google_secret_manager_secret" "db_connection" {
  secret_id = "${var.project_id}-db-connection"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = module.database.db_instance.name
  password = var.db_pwd
}

resource "google_secret_manager_secret_version" "db_connection" {
  secret = google_secret_manager_secret.db_connection.id
  secret_data = jsonencode({
    host            = module.database.db_instance.private_ip_address
    port            = 5432
    database        = module.database.google_sql_database.name
    username        = var.db_user
    password        = var.db_pwd
    connection_name = module.database.db_instance.connection_name
  })
}
resource "google_secret_manager_secret" "github_repo_token" {
  secret_id = "github-repo-token"

  replication {
    auto {}
  }
  labels = {
    managed_by = "terraform"
    source     = "github-secrets"
    app        = "backend"
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "github_repo_token" {
  secret      = google_secret_manager_secret.github_repo_token.id
  secret_data = var.github_repo_token
}
