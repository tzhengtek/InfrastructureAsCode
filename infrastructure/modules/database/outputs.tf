output "db_instance" {
  value       = google_sql_database_instance.database_instance
  description = "Database instance name"
}

output "google_sql_database" {
  value       = google_sql_database.database
  description = "Google SQL database"
}
