# ==============================================================================
# GKE CLUSTER CONFIGURATION
# ==============================================================================
# This file creates a Kubernetes cluster on Google Cloud (GKE)
# Think of it as building the "restaurant building" where your app will run
# ==============================================================================

# ------------------------------------------------------------------------------
# GKE CLUSTER
# ------------------------------------------------------------------------------
# This is the main Kubernetes cluster - the foundation for everything
resource "google_container_cluster" "primary" {
  name     = "perth-gke-cluster"  # Name of your cluster
  location = var.region            # Where it's deployed (europe-west1)

  # Start with 1 node, we'll add a proper node pool below
  # This is just to initialize the cluster
  initial_node_count       = 1
  remove_default_node_pool = true  # We'll create our own node pool

  # Network configuration - connect to your existing VPC
  network    = var.vpc_name                    # Your VPC: "vpc"
  subnetwork = "${var.vpc_name}-subnet"        # Your subnet: "vpc-subnet"

  # Release channel - gets automatic updates (stable version)
  release_channel {
    channel = "REGULAR"  # Balanced between new features and stability
  }

  # Enable workload identity (secure way for pods to access GCP services)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable cluster autoscaling - adds/removes nodes automatically
  cluster_autoscaling {
    enabled = true

    # Resource limits for the entire cluster
    resource_limits {
      resource_type = "cpu"
      minimum       = 1   # At least 1 CPU
      maximum       = 10  # Max 10 CPUs across all nodes
    }

    resource_limits {
      resource_type = "memory"
      minimum       = 1   # At least 1GB RAM
      maximum       = 20  # Max 20GB RAM across all nodes
    }
  }

  # Maintenance window - when GKE can perform updates
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"  # 3 AM (low traffic time)
    }
  }
}

# ------------------------------------------------------------------------------
# NODE POOL
# ------------------------------------------------------------------------------
# This defines the "worker computers" that run your application
# Think of these as the kitchen staff in the restaurant
resource "google_container_node_pool" "primary_nodes" {
  name       = "perth-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name

  # Start with 1 node, autoscaler will add more as needed
  initial_node_count = 1

  # Autoscaling configuration - automatically add/remove nodes
  autoscaling {
    min_node_count = 1   # Always keep at least 1 node running
    max_node_count = 5   # Never go above 5 nodes (cost control)
  }

  # Node configuration - specs for each worker computer
  node_config {
    # Machine type - small instance for cost efficiency
    # e2-small = 2 vCPUs, 2GB RAM
    # Teacher's advice: small nodes + more of them = better scaling
    machine_type = "e2-small"

    # Disk configuration
    disk_size_gb = 20        # 20GB storage per node
    disk_type    = "pd-standard"  # Standard persistent disk (cheaper)

    # Service account - permissions for nodes
    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity - secure authentication
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Labels for organization
    labels = {
      environment = "dev"
      managed_by  = "terraform"
    }

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  # Management configuration
  management {
    auto_repair  = true  # Automatically fix unhealthy nodes
    auto_upgrade = true  # Automatically upgrade nodes
  }
}

# ------------------------------------------------------------------------------
# SERVICE ACCOUNT FOR GKE NODES
# ------------------------------------------------------------------------------
# This is the "identity" for your nodes - what permissions they have
resource "google_service_account" "gke_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
  description  = "Service account for GKE nodes to access GCP resources"
}

# Give the service account permission to pull Docker images
resource "google_project_iam_member" "gke_sa_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Give the service account permission to write logs
resource "google_project_iam_member" "gke_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Give the service account permission to write metrics
resource "google_project_iam_member" "gke_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# ==============================================================================
# OUTPUTS
# ==============================================================================
# These values can be used by other parts of your infrastructure

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint to access the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate for the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}
