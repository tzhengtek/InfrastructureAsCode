# ==============================================================================
# CLOUD DNS CONFIGURATION
# ==============================================================================
# This file creates your DNS (Domain Name System) configuration
# Think of it as creating a phonebook entry:
# - "api.yourdomain.com" → points to your static IP (34.123.45.67)
# ==============================================================================

# ------------------------------------------------------------------------------
# DNS ZONE
# ------------------------------------------------------------------------------
# This creates a DNS zone - a container for your DNS records
# You only need to set up nameservers ONCE after creating this
resource "google_dns_managed_zone" "perth_zone" {
  name        = "perth-zone"
  dns_name    = "${var.domain_name}."  # Note: ends with a dot (DNS requirement)
  description = "DNS zone for Perth Task Manager application"

  # Public zone - accessible from internet
  visibility = "public"

  # DNSSEC - extra security for DNS (prevents hijacking)
  dnssec_config {
    state = "on"
  }
}

# ------------------------------------------------------------------------------
# A RECORD - Points your domain to the static IP
# ------------------------------------------------------------------------------
# This is the actual DNS record that says:
# "When someone types api.yourdomain.com, send them to this IP address"
resource "google_dns_record_set" "a_record" {
  name         = google_dns_managed_zone.perth_zone.dns_name
  managed_zone = google_dns_managed_zone.perth_zone.name
  type         = "A"      # A record = Address record (for IPv4)
  ttl          = 300      # Time to live = 5 minutes (how long to cache)

  # This points to your static IP created in loadbalancer.tf
  rrdatas = [google_compute_global_address.task_manager_ip.address]
}

# ==============================================================================
# OUTPUTS
# ==============================================================================
# Important information you'll need

output "dns_zone_name" {
  description = "Name of the DNS zone"
  value       = google_dns_managed_zone.perth_zone.name
}

output "dns_zone_nameservers" {
  description = "Nameservers for your domain (configure these at your registrar)"
  value       = google_dns_managed_zone.perth_zone.name_servers
}

output "domain_name" {
  description = "Full domain name"
  value       = trimsuffix(google_dns_managed_zone.perth_zone.dns_name, ".")
}
