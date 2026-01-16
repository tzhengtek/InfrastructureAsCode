# ==============================================================================
# LOAD BALANCER CONFIGURATION
# ==============================================================================
# This file creates:
# 1. A static IP address (doesn't change)
# 2. An SSL certificate (for HTTPS)
# Think of it as:
# - Static IP = Your restaurant's permanent street address
# - SSL Certificate = Security guard checking IDs at the door
# ==============================================================================

# ------------------------------------------------------------------------------
# GLOBAL STATIC IP ADDRESS
# ------------------------------------------------------------------------------
# This reserves a permanent IP address for your application
# Without this, your IP could change every time you redeploy
resource "google_compute_global_address" "task_manager_ip" {
  name        = "task-manager-static-ip"
  description = "Static IP address for Task Manager load balancer"

  # Global address type - works across all regions
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# ------------------------------------------------------------------------------
# MANAGED SSL CERTIFICATE
# ------------------------------------------------------------------------------
# This creates an SSL certificate for HTTPS (secure connection)
# Google manages it automatically - renews before expiration
resource "google_compute_managed_ssl_certificate" "task_manager_cert" {
  name = "task-manager-ssl-cert"

  managed {
    # IMPORTANT: Replace this with your actual domain after you buy it
    # Example: ["api.yourdomain.com"] or ["taskmanager.yourdomain.com"]
    domains = [var.domain_name]
  }

  # Note: Certificate provisioning takes 10-60 minutes after DNS is configured
  # Google needs to verify you own the domain by checking DNS records
}

# ==============================================================================
# OUTPUTS
# ==============================================================================
# These values are used by Kubernetes Ingress

output "static_ip_address" {
  description = "The static IP address reserved for the load balancer"
  value       = google_compute_global_address.task_manager_ip.address
}

output "static_ip_name" {
  description = "Name of the static IP (used in Ingress annotation)"
  value       = google_compute_global_address.task_manager_ip.name
}

output "ssl_cert_name" {
  description = "Name of the managed SSL certificate (used in Ingress annotation)"
  value       = google_compute_managed_ssl_certificate.task_manager_cert.name
}
