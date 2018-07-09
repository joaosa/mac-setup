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
