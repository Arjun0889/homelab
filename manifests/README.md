# Kubernetes Manifests

This directory contains raw Kubernetes manifests for infrastructure components that don't need Helm charts.

## Directory Structure

```
manifests/
├── metallb/              # MetalLB IP pool configuration
│   └── pool.yaml         # Defines available IPs for LoadBalancer services
├── ingress-welcome/      # Landing page for bare Ingress IP
│   ├── landing-page.yaml # Complete deployment (ConfigMap, Pod, Service, Ingress)
│   └── README.md         # Detailed explanation
└── README.md             # This file
```

## Why Not Helm?

These components are simple, infrastructure-level resources that don't benefit from Helm's features:

### MetalLB Pool (`metallb/pool.yaml`)
- **What**: Defines IP range `10.0.0.249-254` for LoadBalancer services
- **Why raw manifest**: Simple CRD, no templating needed
- **Deployed once**: Rarely changes after initial setup

### Ingress Welcome Page (`ingress-welcome/`)
- **What**: Service directory shown at `http://10.0.0.249`
- **Why raw manifest**: Static HTML, no complex configuration
- **Simple**: Just nginx serving from ConfigMap

## Deployment

### MetalLB Pool
```bash
# Initial setup (already done via Ansible)
kubectl apply -f manifests/metallb/pool.yaml

# Verify
kubectl get ipaddresspools -n metallb-system
```

### Ingress Welcome Page
```bash
# Deploy
kubectl apply -f manifests/ingress-welcome/landing-page.yaml

# Verify
curl http://10.0.0.249
```

## vs Helm Directory

**Use `helm/`** for:
- ✅ Packaged applications (Pi-hole, Homepage, Longhorn)
- ✅ Complex deployments with many resources
- ✅ Services needing version management
- ✅ Configurations that vary between environments

**Use `manifests/`** for:
- ✅ Simple infrastructure config
- ✅ Cluster-level settings (IP pools, storage classes)
- ✅ Static content services
- ✅ One-off custom resources

## The Complete Picture

```
homelab/
├── ansible/           # Server provisioning
├── helm/              # Application deployments
│   ├── helmfile.yaml
│   └── values/
└── manifests/         # Infrastructure config
    ├── metallb/       # IP management
    └── ingress-welcome/  # Welcome page
```

**Clean separation of concerns!** 🎯
