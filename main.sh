#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

GO_PACKAGES=(
  "github.com/x-motemen/gore/cmd/gore@v0.6.1"
  "github.com/cirocosta/asciinema-edit@latest"  # No version tags available
)

NPM_PACKAGES=(
  "@anthropic-ai/claude-code@2.0.8"
)

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
    asdf global "$language" "$version"
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

# Download file if not exists
# Usage: download_if_missing "path/to/file" "url"
download_if_missing() {
  local file_path="$1"
  local url="$2"

  if [ ! -f "$file_path" ]; then
    mkdir -p "$(dirname "$file_path")"
    curl -sL -o "$file_path" "$url"
  fi
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# homebrew
if ! command -v brew >/dev/null 2>&1; then
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

# prezto
if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
  zsh << 'EOF'
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
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
stow -d "$DOTFILES_DIR" -t "$HOME" --restow $(find "$DOTFILES_DIR" -maxdepth 1 -type d -not -path '*/.*' -exec basename {} \; | grep -v dotfiles)

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
download_if_missing "$HOME/.kubectl_aliases" "https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases"

# whisper model
download_if_missing "$HOME/.local/share/whisper/ggml-base.en.bin" "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"

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
