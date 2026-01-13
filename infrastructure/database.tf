resource "random_id" "db_postgree" {
  byte_length = 4
}

resource "google_sql_database_instance" "database_instance" {
  name             = "${var.db_name}-${random_id.db_postgree.hex}"
  database_version = "POSTGRES_15"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]
  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 2
      backup_retention_settings {
        retained_backups = 2
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.database_instance.name
}

# Create database user
resource "google_sql_user" "database_user" {
  name     = var.db_user
  instance = google_sql_database_instance.database_instance.name
  password = var.db_pwd
}

# Output for connection string
output "database_instance_connection_name" {
  value       = google_sql_database_instance.database_instance.connection_name
  description = "Connection name for Cloud SQL (for Cloud SQL Proxy)"
}

output "database_name" {
  value       = google_sql_database.database.name
  description = "Name of the database"
}

output "database_user" {
  value       = google_sql_user.database_user.name
  description = "Database user name"
}

output "database_password" {
  value       = google_sql_user.database_user.password
  description = "Database user password"
  sensitive   = true
}


