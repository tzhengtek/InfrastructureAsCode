resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
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
  instance = google_sql_database_instance.database_instance.name
  password = var.db_pwd
}

resource "google_secret_manager_secret_version" "db_connection" {
  secret = google_secret_manager_secret.db_connection.id
  secret_data = jsonencode({
    host            = google_sql_database_instance.database_instance.private_ip_address
    port            = 5432
    database        = google_sql_database.database.name
    username        = var.db_user
    password        = var.db_pwd
    connection_name = google_sql_database_instance.database_instance.connection_name
  })
}
