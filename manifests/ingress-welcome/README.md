# Landing Page Service

## Overview

The landing page service displays a service directory when accessing the bare Ingress IP (`http://10.0.0.249`) instead of showing a 404 error.

## Architecture

```
http://10.0.0.249 (no Host header)
        ↓
Nginx Ingress Controller (10.0.0.249)
        ↓
Checks Ingress rules:
  - host: homepage.home  ❌ No match
  - host: pihole.home    ❌ No match
  - host: ""             ✅ MATCH! (catch-all)
        ↓
Routes to landing-page Service
        ↓
Landing-page Pod (nginx:alpine)
        ↓
Serves HTML from ConfigMap
        ↓
Shows service directory page
```

## Deployment Method

**Pure Kubernetes manifests** (not Helm) for maximum simplicity and reliability.

Location: `kustomize/landing-page.yaml`

### Why Not Helm?

1. **Simplicity**: Static HTML doesn't need complex chart logic
2. **Reliability**: Official nginx:alpine image is battle-tested
3. **Transparency**: Easy to see exactly what's being deployed
4. **No dependencies**: No chart repos to maintain

## How It Works

### 1. ConfigMap (HTML Storage)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: landing-html
  namespace: landing-system
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <!-- Beautiful service directory page -->
    </html>
```

**Purpose**: Store the HTML file as Kubernetes config  
**Why ConfigMap?**: Perfect for small, read-only configuration files

### 2. Deployment (nginx Pod)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: landing-page
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html  # nginx default doc root
          readOnly: true
      volumes:
      - name: html
        configMap:
          name: landing-html
```

**What this does**:
- Runs 1 pod with nginx:alpine (super lightweight ~8MB)
- Mounts ConfigMap at `/usr/share/nginx/html`
- Nginx automatically serves `index.html` from this directory

**Resources**:
- Requests: 16Mi RAM, 25m CPU (minimal!)
- Limits: 32Mi RAM, 50m CPU

### 3. Service (Networking)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: landing-page
spec:
  selector:
    app: landing-page
  ports:
  - port: 80
    targetPort: 80
```

**Purpose**: Creates stable ClusterIP for the pod  
**DNS name**: `landing-page.landing-system.svc.cluster.local`

### 4. Ingress (The Magic!)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: landing-page
spec:
  ingressClassName: nginx-internal
  rules:
  - http:  # ← NO HOST SPECIFIED!
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: landing-page
            port:
              number: 80
```

**Critical detail**: No `host:` field = **catch-all rule**

**Ingress priority (Nginx processes in order)**:
1. Specific hosts first (`homepage.home`, `pihole.home`)
2. Empty host last (catch-all for `10.0.0.249`)

## Deployment

```bash
# Deploy
kubectl apply -f kustomize/landing-page.yaml

# Verify
kubectl get all -n landing-system
kubectl get ingress -n landing-system

# Test
curl http://10.0.0.249
# or open in browser: http://10.0.0.249
```

Your browser shows:
```
🏠 Arjun's Homelab
Available Services

Homepage Dashboard → homepage.home
Pi-hole → pihole.home

Nginx Ingress ✓ Online
IP: 10.0.0.249 | K3s Cluster
```

## Adding New Services

When you deploy new services, update the HTML:

```bash
# Edit the ConfigMap
kubectl edit configmap landing-html -n landing-system

# Add new service block:
<div class="service" onclick="window.location.href='http://grafana.home'">
    <h2>Grafana</h2>
    <p>Metrics and monitoring dashboards</p>
    <a href="http://grafana.home">grafana.home</a>
</div>

# Restart nginx to pick up changes
kubectl rollout restart deployment/landing-page -n landing-system
```

**Or** edit `kustomize/landing-page.yaml` and re-apply.

## The Declarative Flow

```
kustomize/landing-page.yaml (single file)
        ↓
kubectl apply (idempotent)
        ↓
Kubernetes creates:
  - Namespace
  - ConfigMap (HTML)
  - Deployment (nginx pod)
  - Service (ClusterIP)
  - Ingress (catch-all rule)
        ↓
Nginx Ingress Controller picks up new rule
        ↓
Requests to 10.0.0.249 → landing page ✅
```

**Benefits**:
- ✅ Single command deployment
- ✅ Version controlled (git)
- ✅ Declarative (describe desired state)
- ✅ Repeatable (delete and recreate anytime)

## Comparison: Named Hosts vs Bare IP

### Named host (homepage.home)
```http
GET / HTTP/1.1
Host: homepage.home    ← Nginx matches this
```
✅ Routes to Homepage pods

### Bare IP (10.0.0.249)
```http
GET / HTTP/1.1
Host: 10.0.0.249       ← Nginx checks all rules
```
✅ No specific match → Falls back to catch-all → Landing page

## Why This Matters

**User experience**:
- ❌ Before: 404 Not Found (confusing)
- ✅ After: Service directory (helpful!)

**Debugging aid**:
- Quickly verify Ingress is working
- See all available services at a glance
- Professional homelab presentation

## Summary

**Simple, declarative, reliable**:
- Raw Kubernetes manifests (no Helm complexity)
- Official nginx image (widely used, trusted)
- ConfigMap for HTML (easy to update)
- Catch-all Ingress (smart fallback)

This is infrastructure as code at its finest! 🎯
