# Understanding pool.yaml and the manifests/ Directory

## What is `pool.yaml`?

**File**: `manifests/metallb/pool.yaml`  
**Purpose**: Configures MetalLB to provide LoadBalancer IPs for your homelab

### The Problem It Solves

In cloud environments (AWS, GCP, Azure), when you create a LoadBalancer service, the cloud provider automatically assigns an external IP. But in bare-metal/homelab setups, **you don't have a cloud provider!**

**Without MetalLB:**
```bash
$ kubectl get svc nginx-ingress
NAME            TYPE           EXTERNAL-IP   PORT(S)
nginx-ingress   LoadBalancer   <pending>     80:30123/TCP
                                ↑
                      Stuck forever!
```

**With MetalLB + pool.yaml:**
```bash
$ kubectl get svc nginx-ingress
NAME            TYPE           EXTERNAL-IP    PORT(S)
nginx-ingress   LoadBalancer   10.0.0.249     80:30123/TCP
                                ↑
                        Assigned from pool!
```

### How It Works

```yaml
# IPAddressPool - Define available IPs
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: homelab-pool
  namespace: metallb-system
spec:
  addresses:
    - 10.0.0.249-10.0.0.254  # 6 IPs available
```

**What this does:**
- Reserves IPs `10.0.0.249` through `10.0.0.254` (6 total)
- MetalLB watches for `type: LoadBalancer` services  
- Assigns IPs from this pool on-demand

```yaml
# L2Advertisement - Announce IPs on your network
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: homelab-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - homelab-pool  # Use IPs from above pool
```

**What this does:**
- Uses Layer 2 (ARP) to announce IPs on your network
- When device asks "who has 10.0.0.249?", MetalLB responds
- Makes the IP reachable from your LAN

### Current IP Usage

| IP | Assigned To | Service |
|----|-------------|---------|
| 10.0.0.249 | Nginx Ingress Controller | HTTP/HTTPS for all apps |
| 10.0.0.250 | Pi-hole | DNS (53/UDP, 53/TCP) + Web UI |
| 10.0.0.251-254 | **Available** | Future services |

### The Flow

```
1. You deploy Nginx Ingress with type: LoadBalancer
        ↓
2. Kubernetes sees: "Need external IP for LoadBalancer"
        ↓
3. MetalLB sees: "New LoadBalancer service!"
        ↓
4. Checks pool.yaml: "I have 10.0.0.249-254 available"
        ↓
5. Assigns 10.0.0.249 (first available IP)
        ↓
6. Announces via ARP: "10.0.0.249 is at homelab0's MAC address"
        ↓
7. Your router/devices can now route to 10.0.0.249 ✅
```

---

## Why NOT Move to Helmfile?

### Option 1: Keep in `manifests/` (Current - Recommended ✅)

**Pros:**
- ✅ Clear separation: Infrastructure config vs Applications
- ✅ Simple deployment: `kubectl apply -f manifests/metallb/pool.yaml`
- ✅ No Helm complexity for a 10-line file
- ✅ Easy to see what's deployed: `kubectl get ipaddresspools -n metallb-system`

**Cons:**
- Different deployment method than applications

### Option 2: Move to Helmfile

You COULD add it to helmfile:

```yaml
# helmfile.yaml
releases:
  - name: metallb-config
    chart: ./charts/raw  # Use a "raw" chart that just applies manifests
    namespace: metallb-system
    values:
      - manifests:
          - pool.yaml
```

**Pros:**
- ✅ Everything in one place (helmfile)
- ✅ Single deployment command

**Cons:**
- ❌ Adds complexity for no real benefit
- ❌ Still need the YAML file somewhere
- ❌ MetalLB pool rarely changes (set once and forget)
- ❌ Harder to quickly view/edit

### Our Decision: Keep Separate ✅

**Philosophy:**
- **Helm/Helmfile** = Application lifecycle management (install, upgrade, rollback)
- **Raw manifests** = Infrastructure configuration (one-time setup)

MetalLB pool is **infrastructure**, not an application!

---

## The `manifests/` Directory Purpose

**Name**: Changed from `kustomize/` → `manifests/` for clarity

**Purpose**: Raw Kubernetes YAML files for infrastructure components

### What Goes Here

| Component | Why Not Helm? |
|-----------|---------------|
| **MetalLB IP Pool** | Simple CRD, set once, no templating needed |
| **Ingress Welcome Page** | Static HTML + nginx, no complex chart logic |
| *Future: Storage Classes* | Cluster-level config, rarely changes |
| *Future: Network Policies* | Security rules, simple YAML |

### What Goes in `helm/`

| Component | Why Helm? |
|-----------|-----------|
| **Pi-hole** | Complex app with many options, needs version management |
| **Homepage** | ConfigMap templating, secret management, upgrades |
| **Longhorn** | Distributed system, many CRDs, frequent updates |
| **Nginx Ingress** | Complex configuration, needs lifecycle management |

---

## Deployment Workflow

### Infrastructure Setup (One-time)

```bash
# 1. MetalLB IP pool
kubectl apply -f manifests/metallb/pool.yaml

# 2. Ingress welcome page
kubectl apply -f manifests/ingress-welcome/landing-page.yaml

# Verify
kubectl get ipaddresspools -n metallb-system
curl http://10.0.0.249
```

### Application Deployments (Managed)

```bash
cd helm
helmfile apply

# This deploys:
# - MetalLB controller (but pool config is separate!)
# - Longhorn
# - Nginx Ingress
# - External DNS
# - Pi-hole
# - Homepage
```

---

## Directory Structure (Final)

```
homelab/
├── ansible/                 # Server provisioning (OS level)
│   └── playbook.yaml
│
├── manifests/               # Infrastructure config (Kubernetes level)
│   ├── README.md
│   ├── metallb/
│   │   └── pool.yaml       # IP pool for LoadBalancer services
│   └── ingress-welcome/
│       ├── landing-page.yaml  # Welcome page at 10.0.0.249
│       └── README.md
│
├── helm/                    # Application deployments
│   ├── helmfile.yaml        # Orchestrates all apps
│   ├── values/              # Per-app configuration
│   │   ├── pihole.values.yaml
│   │   ├── homepage.values.yaml
│   │   └── ...
│   └── secrets/             # Gitignored secrets
│       ├── pihole.yaml
│       └── homepage.yaml
│
└── kustomize/               # (Legacy - will be removed)
    └── README.md            # Points to new location
```

---

## Summary

### `pool.yaml` Purpose
✅ Defines IP range for MetalLB LoadBalancer services  
✅ Simple, infrastructure-level config  
✅ Set once, rarely modified  

### Why Separate from Helmfile
✅ Infrastructure vs application lifecycle  
✅ No need for Helm's templating/versioning  
✅ Clearer organization  

### The `manifests/` Directory
✅ Home for raw Kubernetes config  
✅ Infrastructure settings, not applications  
✅ Simple `kubectl apply` deploy

ment  

**Clean, declarative, organized!** 🎯
