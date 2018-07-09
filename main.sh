# abort if something fails
set -e

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git
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
git --git-dir=$HOME/.cfg/ --work-tree=$HOME reset --hard

# console tools
brew install ag
brew tap aykamko/tag-ag
brew install tag-ag
brew install rg
# fzf
brew install fzf
$(brew --prefix)/opt/fzf/install
brew install ssh-copy-id
brew install fortune
brew install tcptraceroute
brew install watch
brew install pv
brew cask install ngrok
brew install nmap
brew install pgp2
brew install unrar
brew cask install wireshark
brew install postgresql
# docker
brew cask install virtualbox
brew install docker docker-compose boot2docker

# vim+tmux
brew install neovim
brew cask install seil
brew cask install karabiner
brew install ctags-exuberant
brew install rainbarf
brew install urlview

# terminal app
brew cask install iterm2

# evernote
brew cask install evernote
pip install git+https://github.com/jeffkowalski/geeknote

# window management
brew cask install hammerspoon

# apps
brew install flux
brew cask install firefoxdeveloperedition
brew cask install google-chrome-aurora
