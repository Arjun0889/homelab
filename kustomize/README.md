# Kustomize Configuration

This directory contains Kustomize configurations for infrastructure setup.

## Current Contents

- `pool.yaml` - MetalLB IP address pool configuration
- `kustomization.yaml` - Main kustomization file for infrastructure

## Note on Secrets

**All secrets are managed via Helm values files**, not Kustomize.

See `helm/values/*.secrets.yaml` for password management approach.
