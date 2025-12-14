# Arjun's Homelab

**Fully declarative Kubernetes homelab** running on bare-metal K3s with automated deployments.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│  Ansible (OS Bootstrap)                     │
│  Ubuntu → K3s Cluster                       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│  Infrastructure (Raw Manifests)             │
│  • MetalLB IP Pool                          │
│  • Landing Page                             │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│  Applications (Helm/Helmfile)               │
│  • Pi-hole (DNS + Ad Blocking)              │
│  • Homepage (Dashboard)                     │
│  • Nginx Ingress (Routing)                  │
│  • Longhorn (Storage)                       │
│  • ExternalDNS (Automation)                 │
└─────────────────────────────────────────────┘
```

## 📦 Repository Structure

```
homelab/
├── ansible/          # Server provisioning & K3s setup
├── helm/             # Application deployments (Helmfile)
│   ├── helmfile.yaml
│   ├── values/       # Public configuration
│   └── secrets/      # Private credentials (gitignored)
├── manifests/        # Infrastructure config (raw YAML)
│   ├── metallb/      # IP pool for LoadBalancers
│   └── ingress-welcome/  # Landing page
└── docs/             # Architecture & debugging guides
```

### What Goes Where?

| Directory | Purpose | Deployment |
|-----------|---------|------------|
| **ansible/** | OS-level provisioning | `ansible-playbook` |
| **helm/** | Complex apps (charts) | `helmfile apply` |
| **manifests/** | Simple infrastructure | `kubectl apply -f` |

## 🚀 Quick Start

### Prerequisites
- Ubuntu servers (bare-metal or VMs)
- Ansible installed on your machine

### 1. Bootstrap Cluster
```bash
cd ansible
ansible-playbook -i inventory.yaml playbook.yaml
```

### 2. Configure Infrastructure
```bash
# MetalLB IP pool
kubectl apply -f manifests/metallb/pool.yaml

# Landing page (optional)
kubectl apply -f manifests/ingress-welcome/landing-page.yaml
```

### 3. Setup Secrets
```bash
cd helm/secrets

# Copy templates
cp examples/pihole.yaml.example pihole.yaml
cp examples/homepage.yaml.example homepage.yaml
cp examples/externaldns.yaml.example externaldns.yaml

# Edit with your actual credentials
vim pihole.yaml homepage.yaml externaldns.yaml
```

### 4. Deploy Applications
```bash
cd helm
helmfile apply
```

### 5. Access Services
- **Landing Page**: http://10.0.0.249
- **Homepage**: http://homepage.home
- **Pi-hole**: http://pihole.home/admin

## 🔧 Services

| Service | Purpose | Access |
|---------|---------|--------|
| **Pi-hole** | Network-wide ad blocking + DNS | http://pihole.home/admin |
| **Homepage** | Unified dashboard | http://homepage.home |
| **Nginx Ingress** | HTTP routing (10.0.0.249) | Internal |
| **Longhorn** | Distributed storage | http://longhorn.home |
| **MetalLB** | LoadBalancer IPs | Internal |
| **ExternalDNS** | Auto DNS via Pi-hole | Internal |

## 🔐 Secrets Management

### Pattern: Base + Overrides

**Public config** (in git):
```yaml
# helm/values/pihole.values.yaml
ingress:
  hosts:
    - pihole.home
```

**Secrets** (gitignored):
```yaml
# helm/secrets/pihole.yaml
admin:
  password: "your_secret_password"
```

**Helmfile merges them**:
```yaml
# helm/helmfile.yaml
releases:
  - name: pihole
    values:
      - ./values/pihole.values.yaml  # Base
      - ./secrets/pihole.yaml         # Overrides
```

### Files Gitignored:
- `helm/secrets/*.yaml` (actual secrets)
- `helm/secrets/examples/` ✅ (templates committed)

## 🌐 Network Setup

### DNS Resolution

**macOS Configuration:**
```bash
# Create resolver for .home domains
sudo mkdir -p /etc/resolver
sudo bash -c 'echo "nameserver 10.0.0.250" > /etc/resolver/home'
```

**Why needed?** macOS treats `.home` as mDNS by default. This forces DNS queries through Pi-hole.

### IP Allocations

**MetalLB Pool**: `10.0.0.249-254` (6 IPs)

| IP | Service | Purpose |
|----|---------|---------|
| 10.0.0.249 | Nginx Ingress | HTTP/HTTPS for all apps |
| 10.0.0.250 | Pi-hole | DNS + Web UI |
| 10.0.0.251-254 | Available | Future services |

## 🎯 Architecture Decisions

### Helm vs Raw Manifests

**Use Helm (`helm/`) for:**
- ✅ Complex applications (Pi-hole, Homepage)
- ✅ Third-party charts
- ✅ Services needing templating
- ✅ Frequent updates/rollbacks

**Use Raw Manifests (`manifests/`) for:**
- ✅ Simple CRDs (MetalLB pool)
- ✅ Set-once configuration
- ✅ Static content (landing page)
- ✅ Infrastructure settings

### Controller + CRD Pattern

**Applications** (controllers):
- Deployed via Helm
- Can be upgraded independently
- Watch for custom resources

**Configuration** (CRDs):
- Simple YAML manifests
- Rarely change
- Tell controllers what to do

**Example**: MetalLB controller (Helm) + IPAddressPool (manifest)

## 📝 Common Tasks

### Deploy All Apps
```bash
cd helm
helmfile apply
```

### Update Single App
```bash
helmfile apply --selector name=homepage
```

### Check Cluster Health
```bash
kubectl get pods --all-namespaces
kubectl get svc --all-namespaces | grep LoadBalancer
kubectl get ipaddresspools -n metallb-system
```

### Flush DNS Cache (macOS)
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Debug Network Issues
See: `docs/network-dns-debugging-guide.md`

## 🔄 Disaster Recovery

**If cluster is destroyed:**

1. **Rebuild infrastructure**:
   ```bash
   cd ansible
   ansible-playbook -i inventory.yaml playbook.yaml
   ```

2. **Restore manifests**:
   ```bash
   kubectl apply -f manifests/metallb/pool.yaml
   kubectl apply -f manifests/ingress-welcome/landing-page.yaml
   ```

3. **Restore secrets** (from backup or password manager):
   ```bash
   cd helm/secrets
   # Recreate *.yaml files from examples
   ```

4. **Redeploy apps**:
   ```bash
   cd helm
   helmfile apply
   ```

## 📚 Documentation

- **Network Debugging**: `docs/network-dns-debugging-guide.md`
- **DNS Issue RCA**: `docs/RCA-pihole-home-dns-issue.md`
- **Homepage Deep Dive**: `notes/homepage-deployment-deep-dive.md`
- **Manifest Explanation**: `manifests/UNDERSTANDING.md`

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **OS** | Ubuntu 24.04 LTS |
| **K8s** | K3s (lightweight Kubernetes) |
| **Provisioning** | Ansible |
| **Package Manager** | Helm + Helmfile |
| **Ingress** | Nginx Ingress Controller |
| **LoadBalancer** | MetalLB |
| **Storage** | Longhorn |
| **DNS** | Pi-hole + ExternalDNS |
| **Dashboard** | Homepage |

## 🎓 Learning Resources

This homelab is designed for **learning Kubernetes concepts**:

- **Declarative Infrastructure**: Everything in git
- **Controller Pattern**: Apps watch CRDs
- **Secrets Management**: Gitignore + templates
- **Network Debugging**: DNS, Ingress, LoadBalancer
- **Helm Merging**: Values + secrets override

See `notes/` for detailed walkthroughs and explanations.

## 🚧 Future Enhancements

- [ ] GitOps (ArgoCD/Flux)
- [ ] Monitoring (Prometheus + Grafana)
- [ ] Logging (Loki + Promtail)
- [ ] Backups (Velero)
- [ ] Sealed Secrets (encrypted in git)
- [ ] Cert-manager (TLS certificates)

---

**Built with ❤️ for learning and homelab experimentation**
