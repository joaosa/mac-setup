#!/usr/bin/env bash
set -ufo pipefail

# homebrew + brew cask
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# git+zsh, vim+tmux, and console tools
brew tap arl/arl
brew install \
 git ghq stow zsh \
 neovim tmux \
 parallel coreutils findutils grep gnu-sed \
 asdf \
 direnv \
 hub gh git-extras git-delta git-secret git-crypt gitmux lazygit \
 htop bottom \
 jq python-yq jless miller jd \
 urlview \
 pv \
 watch watchexec watchman fswatch \
 zoxide fzf \
 imagemagick pngquant \
 starship ripgrep fd bat dust procs \
 iftop tcptraceroute mtr telnet nmap \
 hyperfine gnu-units \
 ykman gnupg esolitos/ipa/sshpass pwgen \
 fortune \
 dive \
 ansible delve luarocks rustup \
 asciinema agg \
 sox whisper-cpp \
 helm kubectl kubeseal kubectx k3d derailed/k9s/k9s

# prezto
if [ ! -d "${ZDOTDIR:-$HOME}/.zprezto" ]; then
  zsh << EOF
# copy the base config over and overwrite if needed
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -sf "\$rcfile" "${ZDOTDIR:-$HOME}/.\${rcfile:t}"
done
EOF
fi

# dotfiles
DOTFILES_DIR=~/ghq/github.com/joaosa/dotfiles
if [ ! -d "$DOTFILES_DIR" ]; then
  ghq get -u https://github.com/joaosa/dotfiles
fi
[ -L ~/.zpreztorc ] && unlink ~/.zpreztorc
[ -L ~/.zprofile ] && unlink ~/.zprofile
[ -L ~/.zshrc ] && unlink ~/.zshrc
stow -d "$DOTFILES_DIR" -t "$HOME" $(find "$DOTFILES_DIR" -maxdepth 1 -type d -not -path '*/.*' -exec basename {} \; | grep -v dotfiles)

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

# rust
if ! command -v rustc >/dev/null 2>&1; then
  rustup install stable \
   && rustup default stable \
   && echo 1 | rustup-init
fi

# node
if ! asdf plugin list | grep -q nodejs; then
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
fi
if ! asdf list nodejs | grep -q 22.9.0; then
  asdf install nodejs 22.9.0
fi
if [ "$(asdf current nodejs | awk '{print $2}')" != "22.9.0" ]; then
  asdf global nodejs 22.9.0
fi

# vim
if ! npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
  npm install -g @anthropic-ai/claude-code
fi

# golang
if ! asdf plugin list | grep -q golang; then
  asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
fi
if ! asdf list golang | grep -q 1.23.2; then
  asdf install golang 1.23.2
fi
if [ "$(asdf current golang | awk '{print $2}')" != "1.23.2" ]; then
  asdf global golang 1.23.2
fi
if ! command -v gore >/dev/null 2>&1; then
  go install github.com/x-motemen/gore/cmd/gore@latest
fi
if ! command -v asciinema-edit >/dev/null 2>&1; then
  go install github.com/cirocosta/asciinema-edit@latest
fi

# k8s
if [ ! -f ~/.kubectl_aliases ]; then
  curl -s https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases > ~/.kubectl_aliases
fi

# whisper model
if [ ! -f ~/.local/share/whisper/ggml-base.en.bin ]; then
  mkdir -p ~/.local/share/whisper
  curl -L -o ~/.local/share/whisper/ggml-base.en.bin \
    https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
fi

# terminal app fonts & base apps
brew install --cask \
 font-sauce-code-pro-nerd-font \
 karabiner-elements hammerspoon \
 alacritty \
 obsidian \
 slack signal discord \
 mullvadvpn \
 orcaslicer \
 spotify \
 docker \
 ipfs \
 firefox@developer-edition \
 syncthing \
 google-drive

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
