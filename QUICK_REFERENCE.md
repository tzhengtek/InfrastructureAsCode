# Quick Reference - Load Balancer Project

## 🎯 What Each File Does (Simple Explanation)

### Terraform Files (infrastructure/)

| File | What It Creates | Why You Need It |
|------|-----------------|-----------------|
| **gke.tf** | Kubernetes cluster + worker computers | Where your app runs |
| **artifact_registry.tf** | Storage for Docker images | Where app "recipe books" live |
| **loadbalancer.tf** | Permanent IP address + HTTPS certificate | So people can reach your app securely |
| **dns.tf** | Domain name → IP mapping | So people can type a domain instead of IP |
| **variables.tf** | Configuration settings | Stores your domain name and other settings |

### Kubernetes Files (k8s/)

| File | What It Creates | Why You Need It |
|------|-----------------|-----------------|
| **deployment.yaml** | Copies of your app (pods) | Runs 2-10 copies of your Flask app |
| **service.yaml** | Internal "door" to reach pods | Routes traffic to available pods |
| **ingress.yaml** | External load balancer | Routes internet traffic to your app |
| **hpa.yaml** | Auto-scaler for pods | Adds/removes pods based on CPU |

### Application Files

| File | What It Does | Why You Need It |
|------|--------------|-----------------|
| **Dockerfile** | Recipe to package your app | Tells Docker how to build a container |

---

## 🔄 How Everything Works Together

```
1. User types: https://api.yourdomain.com
        ↓
2. DNS (dns.tf) says: "That's IP 34.123.45.67"
        ↓
3. Load Balancer (ingress.yaml) receives request
        ↓
4. SSL Certificate (loadbalancer.tf) encrypts connection
        ↓
5. Service (service.yaml) picks an available pod
        ↓
6. Pod (deployment.yaml) processes request
        ↓
7. Response travels back the same way
```

---

## 🚀 Quick Deployment Commands

### 1. Deploy Infrastructure
```bash
cd infrastructure/
terraform init
terraform apply
# Note the static IP and nameservers!
```

### 2. Build & Push Docker Image
```bash
cd app/
gcloud auth configure-docker europe-west1-docker.pkg.dev
docker build -t task-manager:v1.0 .
docker tag task-manager:v1.0 europe-west1-docker.pkg.dev/iac-epitech-dev/perth-app-repo/task-manager:v1.0
docker push europe-west1-docker.pkg.dev/iac-epitech-dev/perth-app-repo/task-manager:v1.0
```

### 3. Connect to Cluster
```bash
gcloud container clusters get-credentials perth-gke-cluster --region europe-west1
```

### 4. Create Secrets
```bash
kubectl create secret generic app-secrets \
  --from-literal=db_connection_string="YOUR_DB_STRING" \
  --from-literal=jwt_secret="YOUR_JWT_SECRET"
```

### 5. Deploy to Kubernetes
```bash
cd k8s/
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

---

## 🔍 Useful Monitoring Commands

### Check Everything
```bash
kubectl get all                    # All resources
kubectl get ingress                # Load balancer status
kubectl get hpa                    # Autoscaler status
kubectl top pods                   # CPU/memory usage
```

### Watch Autoscaling
```bash
kubectl get hpa --watch            # Watch HPA in real-time
kubectl get pods --watch           # Watch pods scaling
kubectl get nodes --watch          # Watch nodes scaling
```

### Debugging
```bash
kubectl logs -l app=task-manager --tail=50   # View logs
kubectl describe pod POD_NAME                # Pod details
kubectl describe ingress task-manager-ingress # Ingress details
```

---

## 🧪 Test Autoscaling

### Generate Load
```bash
# Install load testing tool
brew install httpd                 # macOS
apt-get install apache2-utils      # Linux

# Generate traffic
ab -n 1000 -c 10 https://api.yourdomain.com/tasks

# Watch pods scale up
kubectl get hpa --watch
```

---

## ⚙️ What You MUST Change

Before deploying, replace these placeholders:

1. **infrastructure/variables.tf**
   ```hcl
   default = "api.YOUR-ACTUAL-DOMAIN.com"  # ← Change this
   ```

2. **k8s/ingress.yaml**
   ```yaml
   - host: api.YOUR-ACTUAL-DOMAIN.com      # ← Change this
   ```

3. **k8s/deployment.yaml**
   ```yaml
   image: europe-west1-docker.pkg.dev/iac-epitech-dev/perth-app-repo/task-manager:v1.0
   # ↑ Update after building your image
   ```

---

## 📊 Project Requirements (from PDF)

| Requirement | File | Status |
|-------------|------|--------|
| ✅ External Load Balancer | ingress.yaml | Creates Google Cloud LB |
| ✅ Horizontal Pod Autoscaler | hpa.yaml | Scales pods (2-10) based on CPU |
| ✅ Cluster Autoscaler | gke.tf | Scales nodes (1-5) automatically |
| ✅ Health Checks | deployment.yaml | Liveness + readiness probes |
| ✅ HTTPS/SSL | loadbalancer.tf | Managed certificate |
| ✅ DNS | dns.tf | Cloud DNS integration |

---

## 🎓 Key Concepts to Explain (for Defense)

### Load Balancer Types
- **Service type: LoadBalancer** = Network LB (Layer 4)
- **Ingress** = Application LB (Layer 7) ← What we use
- **Why Ingress?** More features (SSL, routing, etc.)

### Autoscaling Levels
1. **HPA (Horizontal Pod Autoscaler)** - Scales pods (2-10)
2. **Cluster Autoscaler** - Scales nodes (1-5)
3. Both work together automatically

### Why 70% CPU Target?
- Too low (30%) = wasting resources
- Too high (90%) = no room for spikes
- 70% = balanced (efficient + responsive)

### Why Small Nodes?
- Better scaling granularity
- 1-2 pods per node
- Can add nodes quickly

---

## 🐛 Common Issues

| Problem | Solution |
|---------|----------|
| SSL cert not working | Wait 10-60 min, check DNS |
| Ingress no IP | Wait 5-10 min for provisioning |
| Pods not scaling | Check `kubectl top pods` works |
| Can't reach app | Check `kubectl get ingress` shows IP |
| Database connection fails | Check Kubernetes secret exists |

---

## 💡 Pro Tips

1. **Always check status before assuming failure**
   - SSL takes 10-60 minutes
   - Load balancer takes 5-10 minutes
   - DNS propagation takes 10-60 minutes

2. **Use `--watch` to see changes in real-time**
   ```bash
   kubectl get pods --watch
   ```

3. **Check events for errors**
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

4. **Scale manually for testing**
   ```bash
   kubectl scale deployment task-manager-deployment --replicas=5
   ```

---

## 📞 Getting Help

If stuck:
1. Read `LOADBALANCER_SETUP.md` (detailed guide)
2. Check logs: `kubectl logs -l app=task-manager`
3. Check events: `kubectl get events`
4. Ask your teacher
5. Check GCP Console for errors

---

## 🎯 Success Checklist

Before your defense, verify:

- [ ] Can access via HTTPS: `https://api.yourdomain.com/health`
- [ ] Multiple pods running: `kubectl get pods` shows 2+
- [ ] HPA is active: `kubectl get hpa` shows metrics
- [ ] Load balancer has IP: `kubectl get ingress` shows address
- [ ] SSL certificate is active: Check browser padlock icon
- [ ] Can demonstrate autoscaling with load test
- [ ] Understand what each file does

---

Good luck with your project! 🚀
