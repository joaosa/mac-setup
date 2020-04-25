# abort if something fails
set -ef

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git+zsh
brew install \
 git \
 git-flow-avh \
 git-extras \
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
DOTFILES_REPO=joaosa/dotfiles
DOTFILES_DIR=~/.dotfiles
brew install stow
rm -rf $DOTFILES_DIR
git clone "https://github.com/$DOTFILES_REPO" "$DOTFILES_DIR"
cd $DOTFILES_DIR
# use ssh auth
git remote set-url origin "git@github.com:$DOTFILES_REPO.git"
git push -u origin master
for s in nvim tmux zsh karabiner git hammerspoon alacritty; do
 stow $s
done
cd -

# git
git config --global core.excludesfile ~/.gitignore_global

# vim support
# node
NODE_VERSION=10
brew install "node@$NODE_VERSION"
# node for vim support
npm i -g neovim

# python
# https://github.com/neovim/neovim/issues/9050#issuecomment-424441062
export MACOSX_DEPLOYMENT_TARGET=10.14
brew install \
 zlib pyenv \
 pyenv-virtualenv
# python for vim support
PYTHON2=2.7.16
PYTHON3=3.6.1
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
brew tap homebrew/cask-fonts && brew cask install font-saucecodepro-nerd-font
# console tools
brew install rg -- --with-pcre2
brew tap aykamko/tag-ag && brew install tag-ag
brew install slhck/moreutils/moreutils --without-parallel
brew install parallel --force
brew install \
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
 shellcheck \
 pv \
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
 kafkacat \
 vault \
 terragrunt \
 terraform \
 postgresql \
 mysql@5.7 \
 youtube-dl \
 go golang-migrate \
 rustup \
 exercism

# go
GO111MODULE=off go get -u github.com/motemen/gore/cmd/gore
GO111MODULE=off go get -u github.com/mdempsky/gocode
GO111MODULE=off go get -u github.com/swaggo/swag/cmd/swag

# docker
brew cask install virtualbox
brew install --HEAD xhyve
brew install docker docker-compose docker-machine docker-machine-driver-xhyve
sudo chown root:wheel "$(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve"
sudo chmod u+s "$(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve"
docker-machine ls -q | grep '^default$' || docker-machine create default --driver xhyve

# k8s
brew install \
 fluxctl \
 kubernetes-helm \
 kubectl \
 kubectx \
 minikube \
 derailed/k9s/k9s
curl -s https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases > ~/.kubectl_aliases

# aws
pip3 install awscli

# latex and writing tools
brew install adr-tools
brew cask install basictex
zsh << EOF
 if ! ls /Users/$USER/Library/texmf/tlpkg/texlive.tlpdb > /dev/null; then tlmgr init-usertree; fi
 sudo tlmgr update --self
 sudo tlmgr install latexmk
EOF

# base apps
brew install Rigellute/tap/spotify-tui
brew cask install \
 karabiner-elements \
 alacritty \
 wireshark \
 ngrok \
 evernote \
 hammerspoon \
 flux \
 slack \
 tunnelblick \
 vlc \
 caffeine \
 spotify
brew tap homebrew/cask-versions && brew cask install firefox-developer-edition google-chrome-canary
