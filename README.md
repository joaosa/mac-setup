# mac-setup

Automated macOS development environment setup with security best practices.

## ⚠️ Security Considerations

This script installs software and modifies your system. Before running:

1. **Review the code** - Read [`main.sh`](./main.sh) and [`Brewfile`](./Brewfile) to understand what will be installed
2. **Verify integrity** - The script includes SHA256 checksums for downloaded files
3. **Preview changes** - Use dry-run mode to see what would be installed

## Installation

### Recommended: Review First

```bash
# Download and review the script
curl -fsSL https://raw.githubusercontent.com/joaosa/mac-setup/master/main.sh -o mac-setup.sh

# Review the contents
cat mac-setup.sh

# Run in dry-run mode to preview changes
DRY_RUN=true bash mac-setup.sh

# Execute if satisfied
bash mac-setup.sh
```

### Quick Install (Less Secure)

⚠️ Only use if you trust this repository completely:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/joaosa/mac-setup/master/main.sh)"
```

## Security Features

- ✅ SHA256 checksum verification for downloaded files
- ✅ Version pinning for all packages (Go, npm, asdf)
- ✅ Git clones pinned to specific commit hashes
- ✅ Homebrew packages pinned to prevent auto-updates
- ✅ DRY_RUN mode to preview changes
- ✅ Idempotent - safe to run multiple times

## What Gets Installed

See [`Brewfile`](./Brewfile) for the complete list of packages and applications.
