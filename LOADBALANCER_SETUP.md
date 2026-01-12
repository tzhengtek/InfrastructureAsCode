# Load Balancer & Autoscaling Setup Guide

## 📚 Overview

This guide explains how to deploy the Task Manager application with:
- **GKE Cluster** (Kubernetes on Google Cloud)
- **External Load Balancer** (routes internet traffic)
- **Horizontal Pod Autoscaler** (scales pods based on CPU)
- **Cluster Autoscaler** (scales nodes when needed)
- **HTTPS with SSL** (managed certificate)
- **Custom Domain** (via Cloud DNS)

---

## 🏗️ Architecture

```
Internet
    ↓
https://api.yourdomain.com (DNS)
    ↓
Static IP: 34.xxx.xxx.xxx
    ↓
┌─────────────────────────────────────┐
│ Google Cloud Load Balancer (Ingress) │
│ - HTTPS (SSL Certificate)            │
│ - Global Load Balancing               │
└──────────────┬──────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ GKE Cluster                          │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Service (ClusterIP)            │ │
│  │ - Internal load balancer       │ │
│  └────────────┬───────────────────┘ │
│               ↓                      │
│  ┌────────────────────────────────┐ │
│  │ Pods (2-10 replicas)           │ │
│  │ - Flask app on port 8080       │ │
│  │ - Autoscales on CPU (70%)      │ │
│  └────────────┬───────────────────┘ │
│               │                      │
│  ┌────────────────────────────────┐ │
│  │ Nodes (1-5 machines)           │ │
│  │ - e2-small instances           │ │
│  │ - Autoscales when pods need it │ │
│  └────────────────────────────────┘ │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ Cloud SQL PostgreSQL                 │
│ - Private IP (secure)                │
└──────────────────────────────────────┘
```

---

## 📋 Prerequisites

Before starting, you need:

1. **A domain name** - Buy from:
   - Google Cloud Domains (~$12/year) - Recommended
   - Namecheap, Cloudflare, etc.

2. **GCP Project** - Already set up: `iac-epitech-dev`

3. **Tools installed**:
   - Terraform
   - gcloud CLI
   - kubectl
   - Docker

4. **GCP APIs enabled**:
   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable container.googleapis.com
   gcloud services enable dns.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   ```

---

## 🚀 Step-by-Step Deployment

### Step 1: Buy a Domain

**Option A: Google Cloud Domains (Easiest)**
1. Go to: https://console.cloud.google.com/net-services/domains
2. Click "Register Domain"
3. Search for available domain (e.g., `perth-taskmanager.com`)
4. Complete purchase (~$12/year)
5. Note your domain name

**Option B: External Registrar**
1. Buy domain from Namecheap/Cloudflare
2. You'll need to configure nameservers later

---

### Step 2: Update Configuration Files

**2.1: Update `infrastructure/variables.tf`**
Change the domain variable:
```hcl
variable "domain_name" {
  type        = string
  description = "Domain name for the application"
  default     = "api.perth-taskmanager.com"  # ← Your actual domain
}
```

**2.2: Update `k8s/ingress.yaml`**
Replace the placeholder:
```yaml
rules:
- host: api.perth-taskmanager.com  # ← Your actual domain
```

**2.3: Update `k8s/deployment.yaml`**
Update the image path (after building Docker image):
```yaml
image: europe-west1-docker.pkg.dev/iac-epitech-dev/perth-app-repo/task-manager:v1.0
```

---

### Step 3: Deploy Infrastructure with Terraform

```bash
cd infrastructure/

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (creates GKE, load balancer, DNS, etc.)
terraform apply

# Note the outputs - you'll need these!
# - static_ip_address
# - dns_zone_nameservers
```

**Important outputs to save:**
```
static_ip_address = "34.123.45.67"
dns_zone_nameservers = [
  "ns-cloud-a1.googledomains.com",
  "ns-cloud-a2.googledomains.com",
  ...
]
```

---

### Step 4: Configure DNS Nameservers

**If you bought domain from Google Cloud Domains:**
- Skip this step! Nameservers are automatically configured.

**If you bought from external registrar:**
1. Go to your domain registrar's control panel
2. Find "Nameservers" or "DNS Settings"
3. Replace with Google Cloud nameservers from Step 3
4. Save changes
5. Wait 10-60 minutes for propagation

**Verify DNS is working:**
```bash
# Should return your static IP
nslookup api.yourdomain.com

# Or
dig api.yourdomain.com
```

---

### Step 5: Build and Push Docker Image

```bash
cd app/

# Authenticate with Artifact Registry
gcloud auth configure-docker europe-west1-docker.pkg.dev

# Build Docker image
docker build -t task-manager:v1.0 .

# Tag for Artifact Registry
docker tag task-manager:v1.0 \
  europe-west1-docker.pkg.dev/iac-epitech-dev/perth-app-repo/task-manager:v1.0

# Push to registry
docker push europe-west1-docker.pkg.dev/iac-epitech-dev/perth-app-repo/task-manager:v1.0
```

---

### Step 6: Connect to GKE Cluster

```bash
# Get cluster credentials
gcloud container clusters get-credentials perth-gke-cluster \
  --region europe-west1 \
  --project iac-epitech-dev

# Verify connection
kubectl get nodes
```

---

### Step 7: Create Kubernetes Secrets

Your app needs secrets (JWT, DB connection):

```bash
# Get DB connection string from Secret Manager
DB_CONN=$(gcloud secrets versions access latest --secret="db_connection_string")
JWT_SECRET=$(gcloud secrets versions access latest --secret="jwt_secret")

# Create Kubernetes secret
kubectl create secret generic app-secrets \
  --from-literal=db_connection_string="$DB_CONN" \
  --from-literal=jwt_secret="$JWT_SECRET"

# Verify
kubectl get secrets
```

---

### Step 8: Deploy Application to Kubernetes

```bash
cd k8s/

# Deploy in order:
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml

# Check status
kubectl get all
kubectl get ingress
```

**Expected output:**
```
NAME                    CLASS    HOSTS                     ADDRESS         PORTS     AGE
task-manager-ingress    <none>   api.yourdomain.com        34.123.45.67    80, 443   5m
```

---

### Step 9: Wait for SSL Certificate

The managed SSL certificate takes 10-60 minutes to provision:

```bash
# Check certificate status
gcloud compute ssl-certificates describe task-manager-ssl-cert

# When status shows "ACTIVE", you're ready
```

---

### Step 10: Test Your Application

```bash
# Test HTTP (should work immediately)
curl http://api.yourdomain.com/health

# Test HTTPS (works after SSL cert is active)
curl https://api.yourdomain.com/health

# Should return:
# {"status": "healthy"}
```

---

## 🧪 Testing Autoscaling

### Test Horizontal Pod Autoscaler (HPA)

```bash
# Watch HPA in action
kubectl get hpa task-manager-hpa --watch

# In another terminal, generate load
# Install Apache Bench (load testing tool)
apt-get install apache2-utils  # Ubuntu/Debian
brew install httpd              # macOS

# Generate load (1000 requests, 10 concurrent)
ab -n 1000 -c 10 https://api.yourdomain.com/tasks

# Watch pods scale up
kubectl get pods --watch
```

**What you should see:**
```
Initial: 2 pods
    ↓ (CPU increases above 70%)
HPA scales to: 4 pods
    ↓ (CPU still high)
HPA scales to: 6 pods
    ↓ (Load stops, CPU drops)
After 5 minutes: scales back down to 2 pods
```

### Test Cluster Autoscaler

```bash
# Scale to max pods (will need more nodes)
kubectl scale deployment task-manager-deployment --replicas=8

# Watch nodes scale up
kubectl get nodes --watch

# After a few minutes, should see new nodes added
```

---

## 📊 Monitoring

### View Load Balancer Metrics

1. Go to: https://console.cloud.google.com/net-services/loadbalancing/list
2. Click on your load balancer
3. View metrics:
   - Request rate
   - Latency
   - Backend health

### View Pod Metrics

```bash
# CPU and memory usage
kubectl top pods

# HPA status
kubectl describe hpa task-manager-hpa

# Pod logs
kubectl logs -l app=task-manager --tail=100
```

### View Node Metrics

```bash
# Node resource usage
kubectl top nodes

# Node details
kubectl describe nodes
```

---

## 🐛 Troubleshooting

### Issue: SSL Certificate Not Activating

**Symptoms:** `gcloud compute ssl-certificates describe` shows "PROVISIONING" for >1 hour

**Solutions:**
1. Verify DNS is correctly configured:
   ```bash
   nslookup api.yourdomain.com
   # Should return your static IP
   ```
2. Check domain in `loadbalancer.tf` matches DNS
3. Wait up to 24 hours (rare, but Google needs to verify ownership)

### Issue: Ingress Shows No Address

**Symptoms:** `kubectl get ingress` shows empty ADDRESS column

**Solutions:**
1. Wait 5-10 minutes (load balancer provisioning)
2. Check ingress events:
   ```bash
   kubectl describe ingress task-manager-ingress
   ```
3. Verify static IP exists:
   ```bash
   gcloud compute addresses describe task-manager-static-ip --global
   ```

### Issue: Pods Not Scaling

**Symptoms:** HPA shows `<unknown>` for metrics

**Solutions:**
1. Check metrics-server is installed:
   ```bash
   kubectl get deployment metrics-server -n kube-system
   ```
2. Verify resource requests are set in deployment.yaml
3. Check HPA events:
   ```bash
   kubectl describe hpa task-manager-hpa
   ```

### Issue: Cannot Connect to Database

**Symptoms:** Pods crash with database connection errors

**Solutions:**
1. Verify Kubernetes secret exists:
   ```bash
   kubectl get secret app-secrets
   ```
2. Check VPC connectivity (GKE to Cloud SQL)
3. Verify Cloud SQL is in same VPC as GKE

---

## 📝 Files Created

| File | Purpose |
|------|---------|
| `infrastructure/gke.tf` | GKE cluster with autoscaling |
| `infrastructure/artifact_registry.tf` | Docker image repository |
| `infrastructure/loadbalancer.tf` | Static IP + SSL certificate |
| `infrastructure/dns.tf` | Cloud DNS configuration |
| `infrastructure/variables.tf` | Updated with domain variable |
| `app/Dockerfile` | Container image definition |
| `k8s/deployment.yaml` | Pod specifications |
| `k8s/service.yaml` | Internal load balancer |
| `k8s/ingress.yaml` | External load balancer |
| `k8s/hpa.yaml` | Horizontal Pod Autoscaler |

---

## 🎯 Defense Preparation

For your project defense, be ready to:

1. **Explain the architecture**
   - How traffic flows from internet to your app
   - Role of each component (Ingress, Service, Deployment, HPA)

2. **Demonstrate load balancing**
   - Show multiple pods running
   - Show how traffic is distributed

3. **Demonstrate autoscaling**
   - Generate load with load testing tool
   - Show HPA scaling pods
   - Show Cluster Autoscaler adding nodes

4. **Explain trade-offs**
   - Why Kubernetes-native LoadBalancer vs Cloud-managed?
   - Why 70% CPU target?
   - Why scale up fast, scale down slow?

5. **Show monitoring**
   - Load balancer metrics in GCP Console
   - Pod metrics with `kubectl top`
   - Logs with `kubectl logs`

---

## 💰 Cost Estimates

Approximate monthly costs (development):
- GKE Cluster: ~$75/month (1-5 e2-small nodes)
- Load Balancer: ~$18/month
- Cloud SQL: ~$10/month (db-f1-micro)
- Artifact Registry: ~$0.10/month (storage)
- DNS: ~$0.20/month
- **Total: ~$103/month**

**Cost optimization tips:**
- Delete cluster when not testing
- Use Spot VMs for nodes (cheaper)
- Use smaller database tier

---

## 🔒 Security Notes

- Pods run as non-root user (UID 1000)
- Database is on private IP (not internet-accessible)
- HTTPS enforced with managed certificate
- Secrets stored in Kubernetes secrets (not hardcoded)
- Workload Identity enabled (secure GCP access)

---

## 📚 Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Your course PDF](/.context/attachments/)

---

## 🆘 Need Help?

If you encounter issues:
1. Check logs: `kubectl logs -l app=task-manager`
2. Check events: `kubectl get events --sort-by='.lastTimestamp'`
3. Ask your teacher
4. Refer to this guide's troubleshooting section
