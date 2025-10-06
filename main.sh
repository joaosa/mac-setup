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

# Install asdf language with version
# Usage: install_asdf_language "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git" "22.9.0"
install_asdf_language() {
  local language="$1"
  local repo="$2"
  local version="$3"

  # Add plugin if not present
  if ! asdf plugin list | grep -q "^${language}$"; then
    asdf plugin add "$language" "$repo"
  fi

  # Install version if not present
  if ! asdf list "$language" 2>/dev/null | grep -q "$version"; then
    asdf install "$language" "$version"
  fi

  # Set as global version
  if [ "$(asdf current "$language" 2>/dev/null | awk '{print $2}')" != "$version" ]; then
    asdf set "$language" "$version"
  fi
}

# Install go packages from array
# Usage: install_go_packages
install_go_packages() {
  for package in "${GO_PACKAGES[@]}"; do
    local binary_name=$(echo "$package" | awk -F'/' '{print $NF}' | awk -F'@' '{print $1}')
    if ! command -v "$binary_name" >/dev/null 2>&1; then
      go install "$package"
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
      npm install -g "$package"
    fi
  done
}

# Pin all homebrew packages to prevent auto-updates
# Usage: pin_brew_packages
pin_brew_packages() {
  # Pin all installed formulae
  for package in $(brew list --formula); do
    if ! brew list --pinned | grep -q "^${package}$"; then
      echo "Pinning $package to current version"
      brew pin "$package"
    fi
  done
}

# Download file if not exists with SHA256 checksum verification
# Usage: download_if_missing "path/to/file" "url" "expected_sha256"
download_if_missing() {
  local file_path="$1"
  local url="$2"
  local expected_sha256="$3"

  # If file exists and checksum matches, skip download
  if [ -f "$file_path" ]; then
    if [ -n "$expected_sha256" ]; then
      local actual_sha256=$(shasum -a 256 "$file_path" | awk '{print $1}')
      if [ "$actual_sha256" = "$expected_sha256" ]; then
        return 0
      else
        echo "Warning: Existing file has incorrect checksum, re-downloading..."
        [ "$DRY_RUN" = "false" ] && rm -f "$file_path"
      fi
    else
      return 0
    fi
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY RUN] Would download: $url -> $file_path"
    return 0
  fi

  # Download file
  mkdir -p "$(dirname "$file_path")"
  local temp_file="${file_path}.tmp"

  if ! curl -fsSL -o "$temp_file" "$url"; then
    rm -f "$temp_file"
    echo "Error: Failed to download $url"
    return 1
  fi

  # Verify checksum if provided
  if [ -n "$expected_sha256" ]; then
    local actual_sha256=$(shasum -a 256 "$temp_file" | awk '{print $1}')
    if [ "$actual_sha256" != "$expected_sha256" ]; then
      rm -f "$temp_file"
      echo "Error: Checksum verification failed for $url"
      echo "Expected: $expected_sha256"
      echo "Got:      $actual_sha256"
      return 1
    fi
  fi

  mv "$temp_file" "$file_path"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# homebrew
# Note: Homebrew's official installer uses curl | bash pattern. While not ideal from a
# security perspective, this is the official installation method. For enhanced security,
# you can download the script first, review it, then execute manually.
# See: https://github.com/Homebrew/install
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to PATH (Apple Silicon uses /opt/homebrew, Intel uses /usr/local)
  export PATH="${PATH:+$PATH:}/opt/homebrew/bin:/usr/local/bin"
fi

# ============================================================================
# HOMEBREW PACKAGES & CASKS
# ============================================================================

# Install from Brewfile
brew bundle --file=Brewfile

# Pin packages to prevent auto-updates
pin_brew_packages

# Clean up packages not in Brewfile
brew bundle cleanup --force --file=Brewfile

# ============================================================================
# SHELL & DOTFILES
# ============================================================================

# prezto - pinned to specific commit for security
PREZTO_COMMIT="56669270988c5e32422643ec9e0562d1f3c6a0b8"
if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
  echo "Installing Prezto (commit: ${PREZTO_COMMIT:0:8})..."
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
fi

# dotfiles
DOTFILES_DIR=~/ghq/github.com/joaosa/dotfiles
if [ ! -d "$DOTFILES_DIR" ]; then
  ghq get -u https://github.com/joaosa/dotfiles
else
  git -C "$DOTFILES_DIR" pull --quiet || true
fi

# Stow dotfiles (restow to ensure idempotency)
# Use array to properly handle directory names with spaces
mapfile -t stow_dirs < <(find "$DOTFILES_DIR" -maxdepth 1 -type d -not -path '*/.*' -exec basename {} \; | grep -v dotfiles)
stow -d "$DOTFILES_DIR" -t "$HOME" --restow "${stow_dirs[@]}"

# fzf
if [ ! -f ~/.fzf.bash ] && [ ! -f ~/.fzf.zsh ]; then
  $(brew --prefix)/opt/fzf/install --all
fi

# git
if [ -f ~/.gitignore_global ] && [ "$(git config --global --get core.excludesfile)" != "$HOME/.gitignore_global" ]; then
  git config --global core.excludesfile ~/.gitignore_global
fi

# parallel
if [ ! -f ~/.parallel/will-cite ]; then
  yes 'will cite' | parallel --citation
fi

# ============================================================================
# LANGUAGE RUNTIMES
# ============================================================================

# rust
if ! command -v rustc >/dev/null 2>&1; then
  echo 1 | rustup-init -y --default-toolchain stable
else
  rustup toolchain list | grep -q stable || rustup install stable
  rustup default stable >/dev/null 2>&1 || true
fi

# node
install_asdf_language "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git" "22.9.0"

# npm packages
install_npm_packages

# golang
install_asdf_language "golang" "https://github.com/asdf-community/asdf-golang.git" "1.23.2"

# go packages
install_go_packages

# ============================================================================
# CONFIGURATION FILES
# ============================================================================

# kubectl aliases
download_if_missing "$HOME/.kubectl_aliases" "$KUBECTL_ALIASES_URL" "$KUBECTL_ALIASES_SHA256"

# whisper model
download_if_missing "$HOME/.local/share/whisper/ggml-base.en.bin" "$WHISPER_MODEL_URL" "$WHISPER_MODEL_SHA256"

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
