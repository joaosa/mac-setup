#!/usr/bin/env bash

# abort if something fails
set -ef

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git+zsh
brew install \
 git \
 stow \
 ghq \
 zsh

# prezto
zsh << EOF
# copy the base config over and overwrite if needed
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
chsh -s /bin/zsh
EOF

# dotfiles
DOTFILES_DIR=~/ghq/github.com/joaosa/dotfiles
rm -rf "$DOTFILES_DIR"
ghq get -p https://github.com/joaosa/dotfiles
cd "$DOTFILES_DIR"
stow -t "$HOME" $(ls -d */)
cd -

# git
git config --global core.excludesfile ~/.gitignore_global

# vim+tmux
brew install \
 neovim \
 tmux
# vim-plugged
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim -c ":PlugInstall | :qa"
tmux plugin manager
TPM_PATH=~/.tmux/plugins/tpm
if [ -z "$(ls -A $TPM_PATH)" ]; then
 git clone https://github.com/tmux-plugins/tpm $TPM_PATH
fi

# terminal app fonts
brew tap homebrew/cask-fonts && brew install --cask font-saucecodepro-nerd-font
# console tools
brew install parallel --force
brew install \
 coreutils findutils \
 asdf \
 direnv \
 hub gh git-extras git-delta git-secret git-crypt gitmux lazygit \
 htop bottom \
 jq python-yq jless \
 urlview \
 pv \
 watch watchman \
 fasd zoxide fpp \
 imagemagick pngquant \
 starship ripgrep fd bat dust procs \
 iftop tcptraceroute mtr telnet nmap \
 hyperfine gnu-units \
 ykman gnupg ssh-copy-id esolitos/ipa/sshpass pwgen \
 fortune \
 awscli aws-vault docker-credential-helper-ecr \
 dive \
 ansible \
 golang rustup \
 asciinema agg \
 sqlfluff \
 bambu-studio \
 kubernetes-helm kubectl kubeseal kubectx k3d derailed/k9s/k9s

# golang
go install \
 github.com/x-motemen/gore/cmd/gore@latest \
 github.com/go-delve/delve/cmd/dlv@latest \
 github.com/cirocosta/asciinema-edit@latest

# k8s
curl -s https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases > ~/.kubectl_aliases

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

cargo install sniffnet

# base apps
brew install --cask \
 karabiner-elements \
 alacritty \
 docker \
 fly \
 ngrok \
 obsidian \
 hammerspoon \
 utm \
 flux \
 slack \
 signal \
 mullvadvpn \
 caffeine \
 spotify \
 discord \
 ipfs \
 google-chrome
brew tap homebrew/cask-versions && brew install --cask firefox-developer-edition
