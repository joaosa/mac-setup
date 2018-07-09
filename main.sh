# abort if something fails
set -e

# xcode dev tools
xcode-select --install

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git
brew install git-flow-avh
brew install git-extras
brew install hub

# dotfiles
git clone --bare https://github.com/joaosa/dotfiles ~/.cfg

# zsh
brew install zsh
# prezto
zsh -c "git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto""
brew install fasd
