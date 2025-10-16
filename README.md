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

# Run in dry-run mode to preview changes (with color-coded progress)
DRY_RUN=true bash mac-setup.sh

# Execute if satisfied (shows real-time progress and summary)
bash mac-setup.sh
```

### Quick Install (Less Secure)

⚠️ Only use if you trust this repository completely:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/joaosa/mac-setup/master/main.sh)"
```

## Features

### Security

- ✅ SHA256 checksum verification for downloaded files
- ✅ Version pinning for all packages (Go, npm, asdf)
- ✅ Git clones pinned to specific commit hashes
- ✅ Homebrew packages pinned to prevent auto-updates
- ✅ DRY_RUN mode to preview changes without making changes

### Performance & UX

- ✅ Fast idempotent execution - only installs what's missing
- ✅ Color-coded progress indicators with section headers
- ✅ Real-time statistics tracking (installed/skipped/failed)
- ✅ Execution time summary
- ✅ Optimized Homebrew operations (pre-checks to skip unnecessary work)

### Version Management

- ✅ Uses `.tool-versions` for asdf-managed languages (nodejs, golang)
- ✅ Single source of truth for language versions
- ✅ Easy to update - just edit `.tool-versions`

## What Gets Installed

See [`Brewfile`](./Brewfile) for packages and [`.tool-versions`](./.tool-versions) for language versions.

## Repository Management

This setup uses [ghq](https://github.com/x-motemen/ghq) for organized repository management. By default, ghq clones repositories into a structured directory hierarchy:

```
~/ghq/github.com/<owner>/<repo>
```

For example:
```bash
# Clone a repository with ghq
ghq get github.com/joaosa/dotfiles

# Repository will be at: ~/ghq/github.com/joaosa/dotfiles
```

This structure keeps all your repositories organized by hosting service and owner, making them easy to find and manage.

## Prerequisites

### SSH Key Setup

This repository uses SSH-based authentication for Git operations. Before running the setup script, ensure you have:

1. **Generated an SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Added your SSH key to GitHub**:
   - Copy your public key: `cat ~/.ssh/id_ed25519.pub`
   - Go to [GitHub SSH Keys Settings](https://github.com/settings/keys)
   - Click "New SSH key" and paste your public key

3. **Test your connection**:
   ```bash
   ssh -T git@github.com
   ```

   You should see: `Hi username! You've successfully authenticated...`

Without SSH access configured, git clone operations in the script will fail.
