# abort if something fails
set -ef

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git
git config --global core.excludesfile ~/.gitignore_global
brew install git-flow-avh
brew install git-extras
brew install hub

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
rm -rf ~/.cfg
git clone --bare https://github.com/joaosa/dotfiles ~/.cfg
git --git-dir=$HOME/.cfg/ --work-tree=$HOME config --local status.showUntrackedFiles no
git --git-dir=$HOME/.cfg/ --work-tree=$HOME reset --hard
# use ssh auth
sed -i -e "s/https:\/\/github.com\//git@github.com:/" ~/.cfg/config
git --git-dir=$HOME/.cfg/ --work-tree=$HOME push -u origin master

# console tools
brew install neofetch
brew tap aykamko/tag-ag && brew install tag-ag
brew install rg -- --with-pcre2
brew install gnu-units
brew install slhck/moreutils/moreutils -- --without-parallel
brew install gnu-tee
brew install parallel
brew install ssh-copy-id
brew install pwgen
brew install direnv && echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
brew install fortune
brew install wget
brew install tcptraceroute
brew install watch
brew install jq python-yq
brew install httpie
brew install pv
brew cask install ngrok
brew install nmap
brew install gnupg
brew install unrar
brew cask install wireshark
brew install postgresql
# video
brew cask install vlc
brew install youtube-dl
# kafka
brew install kafkacat
# terraform
brew install terraform
# docker
brew install --HEAD xhyve
brew install docker docker-compose docker-machine docker-machine-driver-xhyve
sudo chown root:wheel $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
sudo chmod u+s $(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
docker-machine ls -q | grep '^default$' || docker-machine create default --driver xhyve

# vpn
brew install openvpn
brewk cask install tunnelblick

# go
brew install go
brew tap alecthomas/homebrew-tap
brew install gometaliner

# node
brew install node@8
echo 'export PATH="/usr/local/opt/node@8/bin:$PATH"' >> ~/.zshrc

# python
brew install pyenv
brew install pyenv-virtualenv
brew install pyflake
# python for vim support
pyenv install 2.7.15 --skip-existing
pyenv virtualenv 2.7.15 neovim-python2 --force
pyenv install 3.5.2 --skip-existing
pyenv virtualenv 3.5.2 neovim-python3 --force
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

# virtualbox
brew cask install virtualbox

# latex
brew cask install basictex
zsh << EOF
 if ! ls /Users/$USER/Library/texmf/tlpkg/texlive.tlpdb > /dev/null; then tlmgr init-usertree; fi
 sudo tlmgr update --self
 sudo tlmgr install latexmk
EOF

# vim+tmux
brew install neovim
# vim-plugged
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
nvim -c ":PlugInstall | :qa"
brew install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
brew cask install karabiner-elements
brew install ctags-exuberant
brew install rainbarf
brew install urlview
# tmux clipboard macOS shizzle
brew install reattach-to-user-namespace
# enable deoplete
nvim -c ":UpdateRemotePlugins | :qa"

# terminal app
brew cask install iterm2
# fonts
brew tap caskroom/fonts
brew cask install font-sourcecodepro-nerd-font

# evernote
brew cask install evernote

# window management
brew cask install hammerspoon

# apps
brew cask install flux
brew tap caskroom/versions
brew cask install firefox-developer-edition
brew cask install google-chrome-canary
brew cask install slack
brew cask install caffeine
brew cask install spotify
brew cask install spotifree
