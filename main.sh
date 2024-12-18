#!/usr/bin/env bash
set -ufo pipefail

# homebrew + brew cask
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
 ansible delve rustup sqlfluff \
 asciinema agg \
 helm kubectl kubeseal kubectx k3d derailed/k9s/k9s

# prezto
zsh << EOF
# copy the base config over and overwrite if needed
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -sf "\$rcfile" "${ZDOTDIR:-$HOME}/.\${rcfile:t}"
done
EOF

# dotfiles
unlink ~/.zpreztorc 
unlink ~/.zprofile
unlink ~/.zshrc
DOTFILES_DIR=~/ghq/github.com/joaosa/dotfiles
ghq get -u https://github.com/joaosa/dotfiles
stow -d "$DOTFILES_DIR" -t "$HOME" $(find "$DOTFILES_DIR" -maxdepth 1 -type d -not -path '*/.*' -exec basename {} \; | grep -v dotfiles)

# fzf
$(brew --prefix)/opt/fzf/install

# git
git config --global core.excludesfile ~/.gitignore_global

# parallel
yes 'will cite' | parallel --citation

# vim-plug
curl -sfLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim -c ":PlugInstall | :qa"
# tmux package manager
tmux plugin manager
TPM_PATH=~/.tmux/plugins/tpm
if [ -z "$(ls -A $TPM_PATH)" ]; then
 git clone https://github.com/tmux-plugins/tpm $TPM_PATH
fi

# rust
rustup install stable \
 && rustup default stable \
 && echo 1 | rustup-init

# node
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
 && asdf install nodejs 22.9.0 \
 && asdf global nodejs 22.9.0

# golang
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git \
 && asdf install golang 1.23.2 \
 && asdf global golang 1.23.2
go install \
 github.com/x-motemen/gore/cmd/gore@latest \
 github.com/cirocosta/asciinema-edit@latest

# k8s
curl -s https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases > ~/.kubectl_aliases

# terminal app fonts & base apps
brew install --cask \
 font-sauce-code-pro-nerd-font \
 karabiner-elements hammerspoon \
 alacritty \
 obsidian \
 flux \
 slack signal discord \
 mullvadvpn \
 orcaslicer \
 spotify \
 docker \
 ipfs \
 firefox@developer-edition \
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
