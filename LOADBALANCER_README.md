# Load Balancer Implementation - Complete Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [What Was Built](#what-was-built)
3. [Architecture](#architecture)
4. [How It Works](#how-it-works)
5. [File Structure](#file-structure)
6. [Key Concepts Explained](#key-concepts-explained)
7. [Defense Preparation](#defense-preparation)
8. [Common Commands](#common-commands)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This implementation adds a **production-ready load balancer** with **autoscaling** for the Task Manager application. It fulfills the course requirements for:

- ✅ External Load Balancer (Google Cloud Load Balancer via Ingress)
- ✅ Horizontal Pod Autoscaler (HPA) - scales pods based on CPU
- ✅ Cluster Autoscaler - scales nodes when needed
- ✅ HTTPS with SSL certificate
- ✅ Custom DNS domain

### Live URLs

| Type | URL | Status |
|------|-----|--------|
| HTTP (IP) | http://136.110.177.86/health | ✅ Working |
| HTTP (Domain) | http://api.iac-epitech.com/health | ✅ Working |
| HTTPS (Domain) | https://api.iac-epitech.com/health | ⏳ SSL provisioning |

---

## What Was Built

### Infrastructure (Terraform)

| Resource | Name | Purpose |
|----------|------|---------|
| **GKE Cluster** | perth-gke-cluster | Kubernetes cluster to run the app |
| **Node Pool** | perth-node-pool | Worker machines (1-5 e2-small VMs) |
| **Static IP** | task-manager-static-ip | Permanent IP: 136.110.177.86 |
| **SSL Certificate** | task-manager-ssl-cert | HTTPS encryption |
| **DNS Zone** | perth-zone | DNS for api.iac-epitech.com |
| **Artifact Registry** | perth-app-repo | Docker image storage |

### Kubernetes Resources

| Resource | Name | Purpose |
|----------|------|---------|
| **Deployment** | task-manager-deployment | Runs 2-10 pods of Flask app |
| **Service** | task-manager-service | Internal load balancing |
| **Ingress** | task-manager-ingress | External load balancer |
| **HPA** | task-manager-hpa | Autoscales pods on CPU |

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

## Key Concepts Explained

### For Non-Technical Teammates

| Term | Simple Explanation |
|------|-------------------|
| **Load Balancer** | Traffic cop that directs visitors to available servers |
| **Pod** | One running copy of our app (like one chef in a kitchen) |
| **Node** | A computer that runs pods (like a kitchen workstation) |
| **HPA** | Manager that hires more chefs when restaurant is busy |
| **Cluster Autoscaler** | Manager that adds more workstations when needed |
| **Ingress** | The restaurant entrance that routes customers |
| **Service** | The kitchen door that connects waiters to chefs |
| **SSL Certificate** | Security badge that proves we're legitimate |

### For Technical Teammates

| Component | Kubernetes Resource | GCP Resource |
|-----------|--------------------| -------------|
| External LB | Ingress | HTTP(S) Load Balancer |
| Internal LB | Service (ClusterIP) | - |
| App instances | Deployment/Pods | - |
| Pod scaling | HPA | - |
| Node scaling | - | Cluster Autoscaler |
| SSL | Ingress annotation | Managed Certificate |
| Static IP | Ingress annotation | Global Address |
| DNS | - | Cloud DNS |

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

## Common Commands

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

### What We Built

✅ **Load Balancer** - Routes traffic from internet to our app
✅ **HPA** - Scales pods (2-10) based on CPU usage
✅ **Cluster Autoscaler** - Scales nodes (1-5) when needed
✅ **SSL Certificate** - HTTPS encryption
✅ **DNS** - Custom domain (api.iac-epitech.com)
✅ **Docker Image** - Containerized Flask app
✅ **Kubernetes Manifests** - Declarative infrastructure

### Key Numbers

| Metric | Value |
|--------|-------|
| Min Pods | 2 |
| Max Pods | 10 |
| Min Nodes | 1 |
| Max Nodes | 5 |
| CPU Target | 70% |
| Static IP | 136.110.177.86 |
| Domain | api.iac-epitech.com |

### Files Changed/Created

- 4 new Kubernetes manifests
- 6 new Terraform files
- 1 Dockerfile
- 3 documentation files
- 2 updated files (.gitignore, requirements.txt)

---

*Last updated: January 2026*
*Author: Antony Jin*
*Course: Epitech IAC C7*
