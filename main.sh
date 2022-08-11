# abort if something fails
set -ef

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git+zsh
brew install \
 git \
 git-flow-avh \
 git-extras \
 git-delta \
 stow \
 hub \
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

# vim support
brew install node
# node for vim support
npm i -g neovim

# python
# https://github.com/neovim/neovim/issues/9050#issuecomment-424441062
export MACOSX_DEPLOYMENT_TARGET=10.14
brew install \
 zlib pyenv \
 pyenv-virtualenv
# python for vim support
PYTHON2=2.7.18
PYTHON3=3.9.13
PYTHON2_VENV="neovim-python2"
PYTHON3_VENV="neovim-python3"
zsh << EOF
eval $(pyenv init -)
eval $(pyenv virtualenv-init -)
pyenv install $PYTHON2 --skip-existing
pyenv virtualenv $PYTHON2 $PYTHON2_VENV --force
pyenv install $PYTHON3 --skip-existing
pyenv virtualenv $PYTHON3 $PYTHON3_VENV --force
pyenv activate $PYTHON2_VENV
pip install neovim
pyenv activate $PYTHON3_VENV
pip install neovim
pyenv activate --unset
EOF

# ruby for vim support
gem install --user-install neovim

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
go get -u github.com/arl/gitmux
brew install \
 rainbarf \
 urlview

# terminal app fonts
brew tap homebrew/cask-fonts && brew install --cask font-saucecodepro-nerd-font
# console tools
brew install rg -- --with-pcre2
brew tap aykamko/tag-ag && brew install tag-ag
brew install slhck/moreutils/moreutils --without-parallel
brew install parallel --force
brew install \
 coreutils \
 fasd \
 direnv \
 neofetch \
 fpp fd bat \
 gnu-units \
 ssh-copy-id \
 pwgen \
 fortune \
 wget httpie \
 htop watch \
 jq python-yq \
 hledger \
 entr \
 pv \
 telnet \
 nmap \
 gnupg \
 magic-wormhole \
 unrar \
 ncdu \
 iftop \
 tcptraceroute mtr \
 ykman \
 openvpn \
 aws-vault \
 aws-iam-authenticator \
 kafka \
 kcat \
 vault \
 tgenv \
 tfenv \
 postgresql \
 mysql@5.7 \
 minio \
 youtube-dl \
 golang golang-migrate graphviz \
 haskell-stack \
 rustup \
 exercism

# go
go install honnef.co/go/tools/cmd/struct-layout@latest
go install honnef.co/go/tools/cmd/struct-layout-optimize@latest
go install github.com/x-motemen/gore/cmd/gore@latest
go install github.com/go-delve/delve/cmd/dlv@latest
GO111MODULE=off go get -u github.com/mdempsky/gocode
GO111MODULE=off go get -u github.com/swaggo/swag/cmd/swag

# k8s
brew install \
 fluxctl \
 fluxcd/tap/flux
 kubernetes-helm \
 kubectl \
 kubeseal \
 kubectx \
 minikube \
 derailed/k9s/k9s
curl -s https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases > ~/.kubectl_aliases

# aws
pip3 install awscli

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

# base apps
brew install Rigellute/tap/spotify-tui
brew install --cask \
 karabiner-elements \
 alacritty \
 docker \
 syncthing \
 fly \
 ngrok \
 obsidian \
 hammerspoon \
 flux \
 slack \
 tunnelblick \
 signal \
 caffeine \
 spotify \
 discord \
 google-chrome
brew tap homebrew/cask-versions && brew install --cask firefox-developer-edition
