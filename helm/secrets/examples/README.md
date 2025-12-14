# Examples Directory

This directory contains template files for secrets configuration. These are committed to git as examples.

## Files

- **pihole.yaml.example** - Template for Pi-hole Helm values overrides
- **externaldns.yaml.example** - Template for ExternalDNS configuration
- **homepage.env.example** - Template for Homepage environment variables

## Usage

Copy these files to the parent `secrets/` directory (without the `.example` extension) and fill in your actual values:

```bash
cd ~/homelab/helm/values/secrets

# Copy templates
cp examples/pihole.yaml.example pihole.yaml
cp examples/externaldns.yaml.example externaldns.yaml
cp examples/homepage.env.example homepage.env

# Edit with your actual secrets
vi pihole.yaml externaldns.yaml homepage.env
```

The parent directory files (without `.example`) are gitignored and will not be committed.

## Adding New Services

When adding a new service that requires secrets:

1. Create a template file here: `servicename.env.example` or `servicename.yaml.example`
2. Document the required variables/fields in the template
3. Commit the template to git
4. Users copy and fill in actual values in parent directory

## Per-Service Strategy

We use **one file per service** (not one monolithic file) for:
- Better organization
- Clear separation of concerns  
- Easier maintenance
- Security scoping
