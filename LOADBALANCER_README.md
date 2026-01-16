# Load Balancer Implementation - Technical Guide

## Table of Contents
1. [Quick Start for Teammates](#quick-start-for-teammates)
2. [Overview](#overview)
3. [Architecture](#architecture)
4. [How It Works](#how-it-works)
5. [Testing Guide](#testing-guide)
6. [Updating the Application](#updating-the-application)
7. [File Structure](#file-structure)
8. [Key Concepts](#key-concepts)
9. [Defense Preparation](#defense-preparation)
10. [Commands Reference](#commands-reference)
11. [Troubleshooting](#troubleshooting)

---

## Quick Start for Teammates

### Prerequisites

```bash
# Install required tools
brew install kubectl google-cloud-sdk hey

# Authenticate to GCP
gcloud auth login
gcloud config set project iac-epitech-dev

# Connect to the GKE cluster
gcloud container clusters get-credentials perth-gke-cluster --region europe-west1
```

### Verify Everything Works

```bash
# Check you're connected to the right cluster
kubectl config current-context
# Should show: gke_iac-epitech-dev_europe-west1_perth-gke-cluster

# Check pods are running
kubectl get pods
# Should show 2-5 pods with STATUS: Running

# Test the endpoints
curl http://api.iac-epitech.com/health
curl https://api.iac-epitech.com/health
```

### Live URLs

| Type | URL | Status |
|------|-----|--------|
| HTTP | http://api.iac-epitech.com/health | Working |
| HTTPS | https://api.iac-epitech.com/health | Working |
| Static IP | 136.110.177.86 | Working |

---

## Overview

This branch implements a **production-ready load balancer** with **autoscaling** using GKE (Google Kubernetes Engine).

### What This Branch Provides

| Component | Description |
|-----------|-------------|
| **GKE Cluster** | Kubernetes cluster with autoscaling nodes (1-5 VMs) |
| **Load Balancer** | Google Cloud HTTP(S) Load Balancer via Kubernetes Ingress |
| **HPA** | Horizontal Pod Autoscaler - scales pods based on CPU (2-10 pods) |
| **SSL/HTTPS** | Google-managed certificate for api.iac-epitech.com |
| **DNS** | Cloud DNS A record pointing to static IP |
| **Artifact Registry** | Docker image storage at `europe-west1-docker.pkg.dev/iac-epitech-dev/perth-repo/` |

### Infrastructure Resources (Terraform)

| Resource | Name | File |
|----------|------|------|
| GKE Cluster | `perth-gke-cluster` | `infrastructure-loadbalancer/gke.tf` |
| Node Pool | `perth-node-pool` | `infrastructure-loadbalancer/gke.tf` |
| Static IP | `task-manager-static-ip` | `infrastructure-loadbalancer/loadbalancer.tf` |
| SSL Cert | `task-manager-ssl-cert` | `infrastructure-loadbalancer/loadbalancer.tf` |
| Artifact Registry | `perth-repo` | `infrastructure-loadbalancer/artifact_registry.tf` |

### Kubernetes Resources

| Resource | Name | File |
|----------|------|------|
| Deployment | `task-manager-deployment` | `k8s/deployment.yaml` |
| Service | `task-manager-service` | `k8s/service.yaml` |
| Ingress | `task-manager-ingress` | `k8s/ingress.yaml` |
| HPA | `task-manager-hpa` | `k8s/hpa.yaml` |

---

## Architecture

### High-Level View

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
│                            │                                     │
│                            ▼                                     │
│                 api.iac-epitech.com (DNS)                       │
│                            │                                     │
│                            ▼                                     │
│                    136.110.177.86                                │
│                     (Static IP)                                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              GOOGLE CLOUD LOAD BALANCER                          │
│                    (Created by Ingress)                          │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Features:                                                │   │
│  │ • SSL termination (HTTPS)                               │   │
│  │ • Health checks                                          │   │
│  │ • Global load balancing                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GKE CLUSTER                                   │
│                 (perth-gke-cluster)                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    SERVICE                                │  │
│  │              (task-manager-service)                       │  │
│  │           ClusterIP - Internal only                       │  │
│  │              Port 80 → Port 8080                         │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                           │                                     │
│              ┌────────────┼────────────┐                       │
│              │            │            │                        │
│              ▼            ▼            ▼                        │
│         ┌────────┐   ┌────────┐   ┌────────┐                   │
│         │ POD 1  │   │ POD 2  │   │ POD N  │  ← HPA scales     │
│         │ Flask  │   │ Flask  │   │ Flask  │    2-10 pods      │
│         │ :8080  │   │ :8080  │   │ :8080  │                   │
│         └────────┘   └────────┘   └────────┘                   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    NODE POOL                              │  │
│  │    1-5 e2-small VMs (Cluster Autoscaler manages)         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUD SQL                                     │
│                 (PostgreSQL Database)                            │
│                   Private IP only                                │
└─────────────────────────────────────────────────────────────────┘
```

### Request Flow

```
1. User visits: https://api.iac-epitech.com/tasks
                    │
2. DNS Resolution:  │ api.iac-epitech.com → 136.110.177.86
                    ▼
3. Load Balancer:   Receives request, terminates SSL
                    │
4. Ingress:         Routes to Service based on host/path
                    │
5. Service:         Picks a healthy Pod (round-robin)
                    │
6. Pod:             Flask app processes request
                    │
7. Response:        Travels back through same path
```

---

## How It Works

### 1. Load Balancing

**What:** Distributes incoming traffic across multiple pods.

**How:**
- Ingress creates a Google Cloud Load Balancer
- Service distributes traffic to pods
- Each request can go to any healthy pod

**Why:**
- No single point of failure
- Better performance
- Can handle more users

```
Request 1 ──→ Pod 1
Request 2 ──→ Pod 2
Request 3 ──→ Pod 1
Request 4 ──→ Pod 2
```

### 2. Horizontal Pod Autoscaler (HPA)

**What:** Automatically adds/removes pods based on CPU usage.

**How:**
- Monitors CPU usage across all pods
- Target: 70% CPU utilization
- Scales between 2-10 pods

**Example:**
```
Low traffic:    2 pods @ 20% CPU  → Stays at 2
Medium traffic: 2 pods @ 80% CPU  → Scales to 4 pods
High traffic:   4 pods @ 85% CPU  → Scales to 8 pods
Traffic drops:  8 pods @ 30% CPU  → Scales back to 2 (after 5 min)
```

### 3. Cluster Autoscaler

**What:** Automatically adds/removes nodes (VMs) when pods need more resources.

**How:**
- If pods can't be scheduled (no room) → Add node
- If nodes are underutilized → Remove node
- Scales between 1-5 nodes

**Example:**
```
2 pods on 1 node   → HPA scales to 6 pods
6 pods don't fit   → Cluster Autoscaler adds 2 more nodes
Now: 6 pods on 3 nodes
```

### 4. SSL/HTTPS

**What:** Encrypts traffic between users and the load balancer.

**How:**
- Google-managed certificate (auto-renewed)
- SSL termination at load balancer
- Internal traffic (LB → Pods) is HTTP

**Why:**
- Security (data encryption)
- Trust (browser padlock icon)
- Required for production

---

## Testing Guide

### 1. Basic Health Check

```bash
# Test HTTP
curl http://api.iac-epitech.com/health
# Expected: {"status": "healthy"} or similar

# Test HTTPS
curl https://api.iac-epitech.com/health
```

### 2. Check Current State

```bash
# See all running pods
kubectl get pods
# Expected: 2+ pods with STATUS: Running, READY: 1/1

# Check HPA status
kubectl get hpa
# Shows: MINPODS, MAXPODS, REPLICAS, CPU%

# Check ingress (should have IP assigned)
kubectl get ingress
# ADDRESS should be: 136.110.177.86
```

### 3. Load Testing (Autoscaling Demo)

This demonstrates that autoscaling works. Run this to generate traffic and watch pods scale up.

**Terminal 1 - Watch pods:**
```bash
kubectl get pods --watch
```

**Terminal 2 - Watch HPA:**
```bash
kubectl get hpa --watch
```

**Terminal 3 - Generate load:**
```bash
# Install hey if needed: brew install hey

# Send 5000 requests with 100 concurrent connections
hey -n 5000 -c 100 http://api.iac-epitech.com/health
```

**Expected behavior:**
1. CPU% in HPA increases above 70%
2. REPLICAS increases from 2 to 3, 4, 5...
3. New pods appear in `kubectl get pods --watch`
4. After load stops, wait 5 minutes, pods scale back down

### 4. Test Pod Resilience

```bash
# Delete a pod manually
kubectl delete pod <pod-name>

# Watch it get recreated automatically
kubectl get pods --watch
# Kubernetes immediately creates a replacement
```

### 5. Check Logs

```bash
# All pods combined
kubectl logs -l app=task-manager --tail=50

# Specific pod
kubectl logs <pod-name>

# Follow logs live
kubectl logs -l app=task-manager -f
```

### 6. Describe Resources (Debugging)

```bash
# Detailed pod info (events, errors)
kubectl describe pod <pod-name>

# Detailed ingress info
kubectl describe ingress task-manager-ingress

# Detailed HPA info
kubectl describe hpa task-manager-hpa
```

---

## Updating the Application

When your friend merges their app code, follow these steps to deploy the new version.

### Step 1: Rebase/Merge the Branch

```bash
# Fetch latest changes
git fetch origin

# Rebase from your friend's branch
git rebase origin/<his-branch-name>
# OR merge
git merge origin/<his-branch-name>

# Resolve any conflicts if needed
```

### Step 2: Check What Changed

Look at these files that might affect deployment:

| File | What to Check |
|------|---------------|
| `app/requirements.txt` | New Python dependencies? |
| `app/Dockerfile` | Build process changes? |
| `k8s/deployment.yaml` | New env vars? Different port? |

### Step 3: Rebuild and Push Docker Image

```bash
cd app/

# Build for linux/amd64 (GKE requires this)
docker buildx build --platform linux/amd64 \
  -t europe-west1-docker.pkg.dev/iac-epitech-dev/perth-repo/task-manager:latest \
  --push .
```

### Step 4: Deploy to Kubernetes

```bash
# Restart deployment to pull new image
kubectl rollout restart deployment task-manager-deployment

# Watch the rollout
kubectl rollout status deployment task-manager-deployment

# Verify pods are running
kubectl get pods
```

### Step 5: Verify Deployment

```bash
# Test the endpoints
curl https://api.iac-epitech.com/health

# Check logs for errors
kubectl logs -l app=task-manager --tail=50
```

### Common Issues When Updating

**Image pull error (403 Forbidden):**
```bash
# Grant permission to GKE service account
gcloud projects add-iam-policy-binding iac-epitech-dev \
  --member="serviceAccount:gke-node-sa@iac-epitech-dev.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

**Pod crash (CrashLoopBackOff):**
```bash
# Check logs for error
kubectl logs <pod-name>

# Common causes:
# - Missing environment variables in deployment.yaml
# - Missing Python dependencies in requirements.txt
# - App listening on wrong port (must be 8080)
```

**Wrong architecture (exec format error):**
```bash
# You built for ARM instead of AMD64
# Rebuild with --platform linux/amd64
docker buildx build --platform linux/amd64 ...
```

### Rollback If Something Breaks

```bash
# Rollback to previous version
kubectl rollout undo deployment task-manager-deployment

# Check rollback status
kubectl rollout status deployment task-manager-deployment
```

---

## File Structure

```
perth/
├── infrastructure-loadbalancer/     # NEW: Load balancer Terraform
│   ├── main.tf                      # Backend config (GCS state)
│   ├── provider.tf                  # Google provider
│   ├── variables.tf                 # Input variables
│   ├── gke.tf                       # GKE cluster + node pool
│   ├── artifact_registry.tf         # Docker image storage
│   ├── loadbalancer.tf              # Static IP + SSL cert
│   └── dns.tf                       # Cloud DNS zone
│
├── k8s/                             # NEW: Kubernetes manifests
│   ├── deployment.yaml              # Pod configuration
│   ├── service.yaml                 # Internal load balancer
│   ├── ingress.yaml                 # External load balancer
│   └── hpa.yaml                     # Autoscaler config
│
├── app/                             # Application code
│   ├── Dockerfile                   # NEW: Container build recipe
│   ├── requirements.txt             # UPDATED: Added python-dotenv
│   └── ... (Flask app files)
│
├── infrastructure/                  # EXISTING: Shared infrastructure
│   └── ... (VPC, Database, Secrets)
│
├── LOADBALANCER_README.md           # This file
├── LOADBALANCER_SETUP.md            # Step-by-step setup guide
└── QUICK_REFERENCE.md               # Quick commands
```

### Why Two Infrastructure Directories?

| Directory | Purpose | Terraform State |
|-----------|---------|-----------------|
| `infrastructure/` | Shared resources (VPC, DB, CI/CD) | `gs://.../infrastructure` |
| `infrastructure-loadbalancer/` | App platform (GKE, LB, DNS) | `gs://.../loadbalancer` |

**Benefits:**
1. **Blast radius reduction** - Mistake in one won't affect the other
2. **Independent lifecycle** - Deploy separately
3. **Team collaboration** - Work in parallel without conflicts
4. **Cleaner ownership** - Clear separation of concerns

---

## Key Concepts

### Kubernetes Architecture

| Component | What It Does | Our Resource |
|-----------|--------------|--------------|
| **Pod** | Smallest deployable unit, runs one container instance | `task-manager-deployment` creates these |
| **Deployment** | Manages pod replicas, handles updates/rollbacks | `task-manager-deployment` (2-10 replicas) |
| **Service** | Internal DNS + load balancing between pods | `task-manager-service` (ClusterIP) |
| **Ingress** | Exposes HTTP/HTTPS routes externally | `task-manager-ingress` |
| **HPA** | Scales pods based on metrics | `task-manager-hpa` (CPU target: 70%) |

### How Components Connect

```
Internet → Ingress → Service → Pods
           (L7 LB)   (L4 LB)   (containers)
```

- **Ingress** creates a Google Cloud HTTP(S) Load Balancer (Layer 7)
- **Service** does internal load balancing (Layer 4, round-robin)
- **Pods** run the actual Flask application

### The Three Required Annotations (k8s/ingress.yaml)

```yaml
annotations:
  # Links to our reserved static IP
  kubernetes.io/ingress.global-static-ip-name: "task-manager-static-ip"

  # Links to Google-managed SSL certificate
  networking.gke.io/managed-certificates: "task-manager-ssl-cert"

  # Alternative way to specify SSL certificate
  ingress.gcp.kubernetes.io/pre-shared-cert: "task-manager-ssl-cert"
```

These annotations connect Kubernetes Ingress to GCP resources created by Terraform.

### Resource Mapping

| Kubernetes | GCP Resource Created | Terraform File |
|------------|---------------------|----------------|
| Ingress | HTTP(S) Load Balancer | Auto-created by GKE |
| `global-static-ip-name` annotation | `google_compute_global_address` | `loadbalancer.tf` |
| `managed-certificates` annotation | `google_compute_managed_ssl_certificate` | `loadbalancer.tf` |
| Node Pool | Compute Engine VMs | `gke.tf` |

---

## Defense Preparation

### Questions the Teacher Might Ask

#### Q1: "Why did you choose Kubernetes-native load balancing instead of cloud-managed?"

**Answer:**
> "We used Kubernetes Ingress which automatically creates a Google Cloud Load Balancer. This gives us the best of both worlds:
> - **Kubernetes-native**: Declarative config in YAML, version controlled
> - **Cloud-managed**: Google manages the actual load balancer infrastructure
>
> The three required annotations connect our Ingress to GCP resources:
> - `kubernetes.io/ingress.global-static-ip-name` - Uses our reserved static IP
> - `networking.gke.io/managed-certificates` - Uses Google-managed SSL
> - `ingress.gcp.kubernetes.io/pre-shared-cert` - Alternative cert specification"

#### Q2: "How does autoscaling work?"

**Answer:**
> "We have two levels of autoscaling:
>
> 1. **Horizontal Pod Autoscaler (HPA)**: Monitors CPU usage across pods. When average CPU exceeds 70%, it adds more pods (up to 10). When it drops, it removes pods (minimum 2). This happens within seconds.
>
> 2. **Cluster Autoscaler**: If HPA wants to add pods but there's no room on existing nodes, Cluster Autoscaler adds more nodes (up to 5). This takes 2-3 minutes.
>
> We scale UP fast (immediately) and scale DOWN slow (5-minute stabilization window) to avoid thrashing."

#### Q3: "Why 70% CPU target?"

**Answer:**
> "70% is a balanced choice:
> - **Too low (30%)**: Wastes resources, over-provisioned
> - **Too high (90%)**: No headroom for traffic spikes, slow response
> - **70%**: Efficient resource usage while leaving 30% headroom for sudden spikes
>
> This is a common industry practice recommended by Google and Kubernetes documentation."

#### Q4: "Why separate infrastructure directories?"

**Answer:**
> "We separated `infrastructure-loadbalancer/` from `infrastructure/` following the **blast radius reduction** pattern:
>
> 1. **Safety**: A Terraform mistake in load balancer config won't destroy the database
> 2. **Speed**: Smaller state files = faster `terraform plan`
> 3. **Independence**: Can deploy load balancer without touching shared resources
> 4. **Team collaboration**: Different team members can work simultaneously
>
> This is a recommended pattern from Terraform and Google Cloud best practices for production environments."

#### Q5: "How would you handle a traffic spike?"

**Answer:**
> "When traffic increases:
> 1. Load balancer distributes traffic across existing pods
> 2. CPU usage increases above 70%
> 3. HPA immediately adds more pods (2 → 4 → 6...)
> 4. If nodes are full, Cluster Autoscaler adds nodes (1 → 2 → 3...)
> 5. New pods start handling traffic within seconds
>
> During scaling, we return HTTP 503 (Service Unavailable) briefly, which is expected behavior. The load balancer health checks ensure traffic only goes to healthy pods."

#### Q6: "What happens if a pod crashes?"

**Answer:**
> "Kubernetes handles this automatically:
> 1. **Liveness probe** detects the pod is unhealthy
> 2. Kubernetes restarts the pod
> 3. **Readiness probe** ensures traffic only goes to healthy pods
> 4. Load balancer removes unhealthy pod from rotation
> 5. Other pods handle traffic during recovery
>
> With minimum 2 replicas, we always have at least one healthy pod."

### Live Demonstration Commands

```bash
# 1. Show current status
kubectl get pods
kubectl get hpa
kubectl get ingress

# 2. Test the application
curl http://api.iac-epitech.com/health

# 3. Generate load (install 'hey' first: brew install hey)
hey -n 1000 -c 50 http://api.iac-epitech.com/health

# 4. Watch autoscaling in action (run in separate terminal)
kubectl get hpa --watch
kubectl get pods --watch

# 5. Show pod distribution
kubectl get pods -o wide

# 6. Show logs
kubectl logs -l app=task-manager --tail=20
```

### Demo Script for Presentation

1. **Show architecture diagram** (from this README)

2. **Show current state:**
   ```bash
   kubectl get all
   ```

3. **Test the app works:**
   ```bash
   curl http://api.iac-epitech.com/health
   ```

4. **Start load test in background:**
   ```bash
   hey -n 5000 -c 100 http://api.iac-epitech.com/health &
   ```

5. **Watch HPA scale up:**
   ```bash
   kubectl get hpa --watch
   # CPU will increase, REPLICAS will increase
   ```

6. **Show new pods:**
   ```bash
   kubectl get pods
   # More pods than before!
   ```

7. **Stop load, wait 5 min, show scale down**

---

## Commands Reference

### Check Status

```bash
# All resources
kubectl get all

# Pods status
kubectl get pods

# HPA status (shows CPU and replica count)
kubectl get hpa

# Ingress (shows IP address)
kubectl get ingress

# Detailed pod info
kubectl describe pod <pod-name>
```

### Logs

```bash
# All pods logs
kubectl logs -l app=task-manager --tail=50

# Specific pod logs
kubectl logs <pod-name>

# Follow logs (live)
kubectl logs -l app=task-manager -f
```

### Scaling

```bash
# Manual scale (for testing)
kubectl scale deployment task-manager-deployment --replicas=5

# Check HPA
kubectl describe hpa task-manager-hpa
```

### Debugging

```bash
# Pod events
kubectl describe pod <pod-name>

# Cluster events
kubectl get events --sort-by='.lastTimestamp'

# Check ingress
kubectl describe ingress task-manager-ingress
```

### Terraform

```bash
# Navigate to loadbalancer infrastructure
cd infrastructure-loadbalancer/

# Check current state
terraform show

# Plan changes
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output
```

---

## Troubleshooting

### Pod won't start (CrashLoopBackOff)

```bash
# Check logs
kubectl logs <pod-name>

# Common causes:
# - Missing environment variables
# - Wrong Docker image
# - Application error
```

### Can't access via domain

```bash
# Check DNS
nslookup api.iac-epitech.com

# Check ingress has IP
kubectl get ingress

# Check SSL status
gcloud compute ssl-certificates describe task-manager-ssl-cert
```

### HPA shows <unknown> for CPU

```bash
# Check metrics-server
kubectl get deployment metrics-server -n kube-system

# Check resource requests are set in deployment.yaml
```

### SSL certificate stuck in PROVISIONING

```bash
# Check status
gcloud compute ssl-certificates describe task-manager-ssl-cert

# Common causes:
# - DNS not configured correctly
# - DNS propagation not complete (wait 1 hour)
# - Domain ownership verification failed
```

---

## Summary

### Configuration Values

| Parameter | Value | File |
|-----------|-------|------|
| Min Pods | 2 | `k8s/hpa.yaml` |
| Max Pods | 10 | `k8s/hpa.yaml` |
| Min Nodes | 1 | `infrastructure-loadbalancer/gke.tf` |
| Max Nodes | 5 | `infrastructure-loadbalancer/gke.tf` |
| CPU Target | 70% | `k8s/hpa.yaml` |
| App Port | 8080 | `k8s/deployment.yaml` |
| Static IP | 136.110.177.86 | `infrastructure-loadbalancer/loadbalancer.tf` |
| Domain | api.iac-epitech.com | `infrastructure-loadbalancer/dns.tf` |
| Docker Image | `europe-west1-docker.pkg.dev/iac-epitech-dev/perth-repo/task-manager:latest` | `k8s/deployment.yaml` |

### TL;DR Cheat Sheet

```bash
# Connect to cluster
gcloud container clusters get-credentials perth-gke-cluster --region europe-west1

# Check everything
kubectl get pods && kubectl get hpa && kubectl get ingress

# Deploy new app version
cd app && docker buildx build --platform linux/amd64 -t europe-west1-docker.pkg.dev/iac-epitech-dev/perth-repo/task-manager:latest --push .
kubectl rollout restart deployment task-manager-deployment

# Test
curl https://api.iac-epitech.com/health

# Load test
hey -n 5000 -c 100 http://api.iac-epitech.com/health

# Watch scaling
kubectl get hpa --watch

# Rollback
kubectl rollout undo deployment task-manager-deployment

# Logs
kubectl logs -l app=task-manager --tail=50
```

---

*Last updated: January 2026*
*Branch: Antonyjin/loadbalancer-setup*
*PR: https://github.com/tzhengtek/InfrastructureAsCode/pull/5*
