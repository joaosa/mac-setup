# abort if something fails
set -ef

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git
git config --global core.excludesfile ~/.gitignore_global
brew install git-flow-avh git-extras hub

# zsh
brew install zsh
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
brew install fasd

# dotfiles
DOTFILES_DIR=~/.dotfiles
brew install stow
rm -rf $DOTFILES_DIR
git clone https://github.com/joaosa/dotfiles $DOTFILES_DIR
# use ssh auth
sed -i -e "s/https:\/\/github.com\//git@github.com:/" $DOTFILES_DIR
git --git-dir=$DOTFILES_DIR --work-tree=$DOTFILES_DIR push -u origin master
cd $DOTFILES_DIR
for s in nvim tmux zsh karabiner git hammerspoon iterm2; do
 stow $s
done
cd -

# console tools
brew install rg -- --with-pcre2
brew tap aykamko/tag-ag && brew install tag-ag
brew install slhck/moreutils/moreutils -- --without-parallel
brew install direnv && echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
brew install \
 neofetch \
 fd bat \
 gnu-units \
 gnu-tee \
 parallel \
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
 tcptraceroute mtr \
 kafkacat \
 vault \
 terraform \
 postgresql \
 mysql@5.7
brew cask install \
 wireshark \
 ngrok

# docker
brew cask install virtualbox
brew install --HEAD xhyve
brew install docker docker-compose docker-machine docker-machine-driver-xhyve
sudo chown root:wheel "$(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve"
sudo chmod u+s "$(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve"
docker-machine ls -q | grep '^default$' || docker-machine create default --driver xhyve

# k8s
brew install fluxctl kubernetes-helm kubectl kubectx minikube derailed/k9s/k9s
curl -s https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases > ~/.kubectl_aliases

# go
brew install go
brew tap alecthomas/homebrew-tap && brew install gometaliner
go get -u github.com/motemen/gore/cmd/gore
go get -u github.com/mdempsky/gocode

# node
NODE_VERSION=10
brew install "node@$NODE_VERSION"
# node for vim support
npm i -g neovim
echo "export PATH="/usr/local/opt/node@$NODE_VERSION/bin:\$PATH"" >> ~/.zshrc

# python
# https://github.com/pyenv/pyenv/wiki/common-build-problems
sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
brew install \
 zlib pyenv \
 pyenv-virtualenv \
 pyflake
# python for vim support
PYTHON2=2.7.16
PYTHON3=3.6.1
pyenv install $PYTHON2 --skip-existing
pyenv virtualenv $PYTHON2 neovim-python2 --force
pyenv install $PYTHON3 --skip-existing
pyenv virtualenv $PYTHON3 neovim-python3 --force
zsh << EOF
eval $(pyenv init -)
eval $(pyenv virtualenv-init -)
pyenv activate neovim-python2
pip install neovim flake8
pyenv activate neovim-python3
pip install neovim flake8
pyenv activate --unset
EOF

# aws
pip install awscli
# this is mostly for k8s
brew install aws-iam-authenticator

# puppet
gem install --user-install hiera-eyaml

# latex
brew cask install basictex
zsh << EOF
 if ! ls /Users/$USER/Library/texmf/tlpkg/texlive.tlpdb > /dev/null; then tlmgr init-usertree; fi
 sudo tlmgr update --self
 sudo tlmgr install latexmk
EOF

# terminal app fonts
brew tap caskroom/fonts && brew cask install font-sourcecodepro-nerd-font

# vim+tmux
brew install \
 neovim \
 tmux \
 # tmux clipboard macOS shizzle
 reattach-to-user-namespace
# vim-plugged
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim -c ":PlugInstall | :qa"
# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
brew install \
 ctags-exuberant \
 rainbarf \
 urlview

# vpn
brew install openvpn
brewk cask install tunnelblick

# video
brew cask install vlc
brew install youtube-dl

# base misc apps
brew cask install \
 karabiner-elements \
 iterm2 \
 evernote \
 hammerspoon \
 flux \
 slack \
 caffeine \
 spotify \
 spotifree
brew tap caskroom/versions && brew cask install firefox-developer-edition google-chrome-canary
