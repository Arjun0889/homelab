# Helm Secrets

This folder contains sensitive configuration files that are **gitignored** and must be created locally.

## Setup Instructions

For each `.example` file, copy it to create the actual secret file:

```bash
# Copy and edit pihole secrets
cp pihole.yaml.example pihole.yaml
# Edit pihole.yaml and replace CHANGEME with your actual password

# Copy and edit external-dns secrets
cp externaldns.yaml.example externaldns.yaml
# Edit externaldns.yaml and replace CHANGEME with your actual password
```

## Files

| File | Status | Purpose |
|------|--------|---------|
| `*.example` | ✅ Committed to git | Templates showing required structure |
| `*.yaml` (actual) | 🔒 Gitignored | Contains real passwords (local only) |

## Referenced By

These secret files are loaded by `helmfile.yaml`:

- `pihole.yaml` → Used by `pihole` release
- `externaldns.yaml` → Used by `externaldns-pihole` release

See parent `helmfile.yaml` for how these are referenced.
