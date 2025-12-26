# Cloudflare Tunnel - Secret Management

## Overview

This directory contains the Cloudflare Tunnel configuration split into two files for security.

---

## Files

### `tunnel.yaml` (SAFE FOR GITHUB ✅)

**Contains**:
-Namespace
- Secret definition with PLACEHOLDER token
- Deployment configuration
- No sensitive data

**Purpose**: Provides the infrastructure-as-code structure for the tunnel

**Commit**: ✅ YES - Safe to commit to GitHub

---

### `tunnel-secret.yaml` (GITIGNORED ❌)

**Contains**:
- Namespace
- Secret with ACTUAL tunnel token from Cloudflare

**Purpose**: Stores the sensitive token locally only

**Commit**: ❌ NO - Gitignored, never commit this file!

---

## Deployment

### Initial Setup

1. **Create tunnel in Cloudflare** (if not done):
   - Go to: https://one.dash.cloudflare.com
   - Networks → Tunnels → Create tunnel
   - Copy the tunnel token

2. **Update tunnel-secret.yaml**:
   ```yaml
   stringData:
     token: "YOUR_ACTUAL_TOKEN_HERE"
   ```

3. **Apply the secret**:
   ```bash
   kubectl apply -f tunnel-secret.yaml
   ```

4. **Apply the deployment**:
   ```bash
   kubectl apply -f tunnel.yaml
   ```

---

### Updating from Git (New Machine)

When cloning the repo on a new machine:

1. **Clone the repo**:
   ```bash
   git clone <repo-url>
   ```

2. **Create tunnel-secret.yaml**:
   ```bash
   cd manifests/cloudflare-tunnel
   cp tunnel.yaml tunnel-secret.yaml
   ```

3. **Edit tunnel-secret.yaml**:
   - Replace `YOUR_TUNNEL_TOKEN_HERE` with actual token from Cloudflare dashboard

4. **Apply**:
   ```bash
   kubectl apply -f tunnel-secret.yaml
   kubectl apply -f tunnel.yaml
   ```

---

## Security

### What's Protected

- ✅ `tunnel-secret.yaml` is gitignored
- ✅ Actual token never committed to GitHub
- ✅ `tunnel.yaml` only has placeholder

### What's in GitHub

- ✅ `tunnel.yaml` - Infrastructure structure (safe)
- ✅ `README.md` - This documentation
- ❌ `tunnel-secret.yaml` - NOT in GitHub (gitignored)

---

## Verification

### Check tunnel is working

```bash
# Check pods running
kubectl get pods -n cloudflare-system

# Check logs for successful connection
kubectl logs -n cloudflare-system -l app=cloudflared --tail=20

# Should see:
# INF Registered tunnel connection connIndex=0
# INF Registered tunnel connection connIndex=1
```

### Test internet access

```bash
curl https://n8n.arjunreddie.com
curl https://homepage.arjunreddie.com
```

---

## Troubleshooting

### Issue: Pods CrashLoopBackOff

**Cause**: Invalid or missing token

**Fix**:
```bash
# Verify secret exists
kubectl get secret tunnel-token -n cloudflare-system

# Check secret content (base64 encoded)
kubectl get secret tunnel-token -n cloudflare-system -o yaml

# If missing, apply tunnel-secret.yaml
kubectl apply -f tunnel-secret.yaml
```

### Issue: Token exposed in git

**Immediately**:
1. Go to Cloudflare dashboard
2. Delete the exposed tunnel
3. Create a new tunnel with new token
4. Update `tunnel-secret.yaml` with new token
5. Reapply: `kubectl apply -f tunnel-secret.yaml`

---

## Rotation (Security Best Practice)

Should rotate tunnel token if:
- Token was accidentally committed to git
- Token was shared with someone/something
- Periodic security rotation (every 6-12 months)

**Steps**:
1. Cloudflare dashboard → Delete old tunnel
2. Create new tunnel → Copy new token
3. Update `tunnel-secret.yaml` with new token
4. Apply: `kubectl apply -f tunnel-secret.yaml`
5. Restart pods: `kubectl rollout restart deployment/cloudflared -n cloudflare-system`

---

## Summary

**tunnel.yaml**: Structure only, safe for GitHub ✅  
**tunnel-secret.yaml**: Actual token, gitignored ❌  
**Deployment**: Apply secret first, then deployment
