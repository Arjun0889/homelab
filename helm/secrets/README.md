# Helm Secrets

This folder contains sensitive configuration files that are **gitignored** and must be created locally.

## Folder Structure

```
secrets/
├── examples/              # Templates (committed to git)
│   ├── pihole.yaml.example
│   ├── externaldns.yaml.example
│   └── homepage.yaml.example
├── pihole.yaml           # Actual secrets (gitignored)
├── externaldns.yaml      # Actual secrets (gitignored)
├── homepage.yaml         # Actual secrets (gitignored)
└── README.md             # This file
```

## Setup Instructions

For each file in `examples/`, copy it to create the actual secret file:

```bash
# Copy and edit pihole secrets
cp examples/pihole.yaml.example pihole.yaml
# Edit pihole.yaml and replace CHANGEME with your actual password

# Copy and edit external-dns secrets
cp examples/externaldns.yaml.example externaldns.yaml
# Edit externaldns.yaml and replace CHANGEME with your actual password

# Copy and edit Homepage secrets
cp examples/homepage.yaml.example homepage.yaml
# Edit homepage.yaml and add your actual API keys (especially Pi-hole API key)
```

**Then deploy with helmfile**:
```bash
cd ~/homelab/helm
helmfile apply
```

All secrets are managed declaratively through Helm - no manual scripts needed!

## Files

| File/Directory | Status | Purpose |
|----------------|--------|----------|
| `examples/` | ✅ Committed to git | Template files showing required structure |
| `*.yaml` (root) | 🔒 Gitignored | Helm values overrides with secrets (local only) |

## Declarative Approach

All secrets are managed through **Helmfile + Helm values**:
- Secrets defined in YAML format (same as pihole, externaldns)
- Helm creates Kubernetes Secrets automatically
- No manual scripts needed
- Fully declarative workflow: `helmfile apply`

## Referenced By

These secret files are loaded by `helmfile.yaml`:

- `pihole.yaml` → Used by `pihole` release
- `externaldns.yaml` → Used by `externaldns-pihole` release
- `homepage.yaml` → Used by `homepage` release

See parent `helmfile.yaml` for how these are referenced.
