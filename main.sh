#!/usr/bin/env bash
set -euo pipefail

# DRY_RUN mode: Set to "true" to preview changes without executing them
DRY_RUN="${DRY_RUN:-false}"

if [ "$DRY_RUN" = "true" ]; then
  echo "=== DRY RUN MODE ==="
  echo "No changes will be made to the system."
  echo "To execute for real, run: DRY_RUN=false $0"
  echo ""
fi

# ============================================================================
# LOGGING & PROGRESS TRACKING
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Tracking variables
START_TIME=$(date +%s)
ITEMS_INSTALLED=0
ITEMS_SKIPPED=0
ITEMS_FAILED=0

# Logging functions
log_info() {
  echo -e "${BLUE}ℹ${RESET}  $*"
}

log_success() {
  echo -e "${GREEN}✓${RESET}  $*"
  ((ITEMS_INSTALLED++)) || true
}

log_skip() {
  echo -e "${YELLOW}⊘${RESET}  $*"
  ((ITEMS_SKIPPED++)) || true
}

log_warn() {
  echo -e "${YELLOW}⚠${RESET}  $*"
}

log_error() {
  echo -e "${RED}✗${RESET}  $*" >&2
  ((ITEMS_FAILED++)) || true
}

# Section header
# Usage: log_section "1" "5" "INITIALIZATION"
log_section() {
  local current="$1"
  local total="$2"
  local name="$3"
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}[$current/$total] $name${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# ============================================================================
# CONFIGURATION
# ============================================================================

GO_PACKAGES=(
  "github.com/x-motemen/gore/cmd/gore@v0.6.1"
  "github.com/cirocosta/asciinema-edit@v0.2.0"
)

NPM_PACKAGES=(
  "@anthropic-ai/claude-code@2.0.8"
)

# File downloads with integrity verification
# To regenerate checksums: curl -fsSL <URL> | shasum -a 256
KUBECTL_ALIASES_URL="https://raw.githubusercontent.com/ahmetb/kubectl-aliases/7549fa45bbde7499b927c74cae13bfb9169c9497/.kubectl_aliases"
KUBECTL_ALIASES_SHA256="2aa6fa924d84663a17e797e566a8ae3512c94037c2d973203be177b720849ea9"

WHISPER_MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/80da2d8bfee42b0e836fc3a9890373e5defc00a6/ggml-base.en.bin"
WHISPER_MODEL_SHA256="a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get version from .tool-versions file
# Usage: get_tool_version "nodejs"
get_tool_version() {
  local tool="$1"
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local tool_versions_file="$script_dir/.tool-versions"

  if [ -f "$tool_versions_file" ]; then
    grep "^${tool} " "$tool_versions_file" | awk '{print $2}'
  else
    echo ""
  fi
}

# Install asdf language with version
# Usage: install_asdf_language "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git"
install_asdf_language() {
  local language="$1"
  local repo="$2"
  local version="${3:-$(get_tool_version "$language")}"

  if [ -z "$version" ]; then
    log_error "No version found for $language"
    return 1
  fi

  # Add plugin if not present
  if ! asdf plugin list | grep -q "^${language}$"; then
    log_info "Adding asdf plugin: $language"
    asdf plugin add "$language" "$repo"
    log_success "Added asdf plugin: $language"
  else
    log_skip "asdf plugin already exists: $language"
  fi

  # Install version if not present
  if ! asdf list "$language" 2>/dev/null | grep -q "$version"; then
    log_info "Installing $language $version..."
    asdf install "$language" "$version"
    log_success "Installed $language $version"
  else
    log_skip "$language $version already installed"
  fi
}

# Install go packages from array
# Usage: install_go_packages
install_go_packages() {
  for package in "${GO_PACKAGES[@]}"; do
    local binary_name=$(echo "$package" | awk -F'/' '{print $NF}' | awk -F'@' '{print $1}')
    if ! command -v "$binary_name" >/dev/null 2>&1; then
      log_info "Installing Go package: $package"
      go install "$package"
      log_success "Installed Go package: $binary_name"
    else
      log_skip "Go package already installed: $binary_name"
    fi
  done
}

# Install npm packages from array with version locking
# Usage: install_npm_packages
install_npm_packages() {
  for package in "${NPM_PACKAGES[@]}"; do
    local package_name=$(echo "$package" | awk -F'@' '{print $1}')
    local package_version=$(echo "$package" | awk -F'@' '{print $2}')

    # Check if package is installed with correct version
    if ! npm list -g "$package_name@$package_version" --depth=0 >/dev/null 2>&1; then
      log_info "Installing npm package: $package"
      npm install -g "$package"
      log_success "Installed npm package: $package_name@$package_version"
    else
      log_skip "npm package already installed: $package_name@$package_version"
    fi
  done
}

# Pin all homebrew packages to prevent auto-updates
# Usage: pin_brew_packages
pin_brew_packages() {
  # Get list of already pinned packages once (not in loop for performance)
  local pinned_packages=$(brew list --pinned)

  # Pin all installed formulae
  for package in $(brew list --formula); do
    if ! echo "$pinned_packages" | grep -q "^${package}$"; then
      brew pin "$package" >/dev/null 2>&1
      log_success "Pinned: $package"
    else
      log_skip "Already pinned: $package"
    fi
  done
}

# Download file if not exists with SHA256 checksum verification
# Usage: download_if_missing "path/to/file" "url" "expected_sha256"
download_if_missing() {
  local file_path="$1"
  local url="$2"
  local expected_sha256="$3"
  local filename=$(basename "$file_path")

  # If file exists and checksum matches, skip download
  if [ -f "$file_path" ]; then
    if [ -n "$expected_sha256" ]; then
      local actual_sha256=$(shasum -a 256 "$file_path" | awk '{print $1}')
      if [ "$actual_sha256" = "$expected_sha256" ]; then
        log_skip "$filename (checksum verified)"
        return 0
      else
        log_warn "Existing file has incorrect checksum, re-downloading..."
        [ "$DRY_RUN" = "false" ] && rm -f "$file_path"
      fi
    else
      log_skip "$filename (already exists)"
      return 0
    fi
  fi

  if [ "$DRY_RUN" = "true" ]; then
    log_info "[DRY RUN] Would download: $filename"
    return 0
  fi

  # Download file
  log_info "Downloading: $filename"
  mkdir -p "$(dirname "$file_path")"
  local temp_file="${file_path}.tmp"

  if ! curl -fsSL -o "$temp_file" "$url"; then
    rm -f "$temp_file"
    log_error "Failed to download $filename"
    return 1
  fi

  # Verify checksum if provided
  if [ -n "$expected_sha256" ]; then
    local actual_sha256=$(shasum -a 256 "$temp_file" | awk '{print $1}')
    if [ "$actual_sha256" != "$expected_sha256" ]; then
      rm -f "$temp_file"
      log_error "Checksum verification failed for $filename"
      log_error "Expected: $expected_sha256"
      log_error "Got:      $actual_sha256"
      return 1
    fi
  fi

  mv "$temp_file" "$file_path"
  log_success "Downloaded: $filename"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

log_section "1" "5" "INITIALIZATION"

# homebrew
# Note: Homebrew's official installer uses curl | bash pattern. While not ideal from a
# security perspective, this is the official installation method. For enhanced security,
# you can download the script first, review it, then execute manually.
# See: https://github.com/Homebrew/install
if ! command -v brew >/dev/null 2>&1; then
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to PATH (Apple Silicon uses /opt/homebrew, Intel uses /usr/local)
  export PATH="${PATH:+$PATH:}/opt/homebrew/bin:/usr/local/bin"
  log_success "Installed Homebrew"
else
  log_skip "Homebrew already installed"
fi

# ============================================================================
# HOMEBREW PACKAGES & CASKS
# ============================================================================

log_section "2" "5" "HOMEBREW PACKAGES & CASKS"

# Install from Brewfile
log_info "Installing packages from Brewfile..."
brew bundle --file=Brewfile
log_success "Brewfile packages installed"

# Pin packages to prevent auto-updates
log_info "Pinning Homebrew packages..."
pin_brew_packages

# Clean up packages not in Brewfile
log_info "Cleaning up packages not in Brewfile..."
brew bundle cleanup --force --file=Brewfile
log_success "Cleanup complete"

# ============================================================================
# SHELL & DOTFILES
# ============================================================================

log_section "3" "5" "SHELL & DOTFILES"

# prezto - pinned to specific commit for security
PREZTO_COMMIT="56669270988c5e32422643ec9e0562d1f3c6a0b8"
if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
  log_info "Installing Prezto (commit: ${PREZTO_COMMIT:0:8})..."
  zsh << EOF
git clone --recursive https://github.com/sorin-ionescu/prezto.git "\${ZDOTDIR:-\$HOME}/.zprezto"
cd "\${ZDOTDIR:-\$HOME}/.zprezto"
git checkout "$PREZTO_COMMIT"
git submodule update --init --recursive
setopt EXTENDED_GLOB
for rcfile in "\${ZDOTDIR:-\$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -sf "\$rcfile" "\${ZDOTDIR:-\$HOME}/.\${rcfile:t}"
done
EOF
  log_success "Installed Prezto"
else
  log_skip "Prezto already installed"
fi

# dotfiles
DOTFILES_DIR=~/ghq/github.com/joaosa/dotfiles
if [ ! -d "$DOTFILES_DIR" ]; then
  log_info "Cloning dotfiles repository..."
  ghq get -u https://github.com/joaosa/dotfiles
  log_success "Cloned dotfiles"
else
  log_info "Updating dotfiles..."
  git -C "$DOTFILES_DIR" pull --quiet || true
  log_success "Updated dotfiles"
fi

# Stow dotfiles (restow to ensure idempotency)
# Use array to properly handle directory names with spaces
log_info "Installing dotfiles with stow..."
mapfile -t stow_dirs < <(find "$DOTFILES_DIR" -maxdepth 1 -type d -not -path '*/.*' -exec basename {} \; | grep -v dotfiles)
stow -d "$DOTFILES_DIR" -t "$HOME" --restow "${stow_dirs[@]}"
log_success "Installed dotfiles"

# fzf
if [ ! -f ~/.fzf.bash ] && [ ! -f ~/.fzf.zsh ]; then
  log_info "Installing fzf..."
  $(brew --prefix)/opt/fzf/install --all
  log_success "Installed fzf"
else
  log_skip "fzf already installed"
fi

# git
if [ -f ~/.gitignore_global ] && [ "$(git config --global --get core.excludesfile)" != "$HOME/.gitignore_global" ]; then
  git config --global core.excludesfile ~/.gitignore_global
  log_success "Configured global git excludes"
else
  log_skip "Global git excludes already configured"
fi

# parallel
if [ ! -f ~/.parallel/will-cite ]; then
  log_info "Configuring GNU parallel..."
  yes 'will cite' | parallel --citation
  log_success "Configured GNU parallel"
else
  log_skip "GNU parallel already configured"
fi

# ============================================================================
# LANGUAGE RUNTIMES
# ============================================================================

log_section "4" "5" "LANGUAGE RUNTIMES"

# rust
if ! command -v rustc >/dev/null 2>&1; then
  log_info "Installing Rust..."
  echo 1 | rustup-init -y --default-toolchain stable
  log_success "Installed Rust"
else
  rustup toolchain list | grep -q stable || rustup install stable
  rustup default stable >/dev/null 2>&1 || true
  log_skip "Rust already installed"
fi

# node
install_asdf_language "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git"

# npm packages
log_info "Installing npm packages..."
install_npm_packages

# golang
install_asdf_language "golang" "https://github.com/asdf-community/asdf-golang.git"

# go packages
log_info "Installing Go packages..."
install_go_packages

# ============================================================================
# CONFIGURATION FILES
# ============================================================================

log_section "5" "5" "CONFIGURATION FILES"

# kubectl aliases
download_if_missing "$HOME/.kubectl_aliases" "$KUBECTL_ALIASES_URL" "$KUBECTL_ALIASES_SHA256"

# whisper model
download_if_missing "$HOME/.local/share/whisper/ggml-base.en.bin" "$WHISPER_MODEL_URL" "$WHISPER_MODEL_SHA256"

# ============================================================================
# SUMMARY
# ============================================================================

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}✓ Setup Complete!${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${GREEN}✓${RESET} Installed: $ITEMS_INSTALLED"
echo -e "${YELLOW}⊘${RESET} Skipped:   $ITEMS_SKIPPED"
if [ "$ITEMS_FAILED" -gt 0 ]; then
  echo -e "${RED}✗${RESET} Failed:    $ITEMS_FAILED"
fi
echo ""
echo -e "⏱  Total time: ${MINUTES}m ${SECONDS}s"
echo ""

if false; then
 # latex and writing tools
 brew install adr-tools
 brew install --cask basictex
zsh << EOF
 if ! ls /Users/$USER/Library/texmf/tlpkg/texlive.tlpdb > /dev/null; then tlmgr init-usertree; fi
 sudo tlmgr update --self
 sudo tlmgr install latexmk
 sudo tlmgr install moderncv
 sudo tlmgt collection-latexextra
EOF
fi
