# Secrets Management Guide

## Overview
This repository uses multiple secret management strategies depending on the component:

### Ansible Secrets
**Location:** `ansible/inventory/group_vars/all/secrets.yml`
**Type:** Encrypted variables
**Security:** ✅ .gitignored
**Usage:** User passwords, SSH keys, K3s tokens

### Kubernetes Secrets
**Method:** Imperative kubectl commands
**Storage:** In cluster, not in Git
**Security:** ✅ Not committed

#### Current K8s Secrets:
- `pihole-password` (pihole-system namespace)

### Secret Creation Commands:
```bash
# Pi-hole password
kubectl create secret generic pihole-password \
  --from-literal=password='homelab123' \
  -n pihole-system
```

## Security Best Practices

### ✅ Good Practices (Currently Using):
1. `.gitignore` for sensitive files
2. Secrets not in values files
3. Example files for reference

### ⚠️ Future Improvements:
1. **Sealed Secrets** - Encrypt secrets in Git
2. **External Secrets Operator** - Pull from Vault
3. **SOPS** - Encrypt YAML files with age/GPG

## Files with Secrets

### Gitignored (Safe):
- `ansible/inventory/group_vars/all/secrets.yml`
- `kustomize/secrets/*.yaml`

### NOT Gitignored (Already Fixed):
- ~~`helm/values/pihole.values.yaml`~~ ← Removed password

## Recreating Secrets (Disaster Recovery)

If cluster is destroyed, recreate with:

```bash
# Pi-hole
kubectl create secret generic pihole-password \
  --from-literal=password='YOUR_PASSWORD' \
  -n pihole-system
```

Store actual passwords in password manager (1Password, BitWarden, etc.)
