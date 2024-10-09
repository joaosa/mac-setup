# abort if something fails
set -ef

# homebrew + brew cask
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# git+zsh
brew install \
 git \
 git-extras \
 git-delta \
 git-secret \
 git-crypt \
 stow \
 hub gh \
 ghq \
 lazygit \
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
 pv \
 gitmux \
 urlview \
 fasd zoxide \
 direnv \
 neofetch \
 imagemagick pngquant \
 starship ripgrep fd bat dust procs \
 iftop tcptraceroute mtr \
 hyperfine \
 fpp \
 gnu-units datamash \
 ykman \
 gnupg ssh-copy-id esolitos/ipa/sshpass \
 pwgen \
 fortune \
 wget httpie \
 htop bottom \
 jq python-yq fx jless \
 hledger \
 watch watchman \
 telnet nmap \
 magic-wormhole \
 ncdu \
 trash \
 ansible ansible-lint \
 awscli aws-vault docker-credential-helper-ecr \
 dive \
 kafka kcat \
 vault \
 tgenv tfenv \
 postgresql minio \
 youtube-dl \
 golang golang-migrate graphviz \
 haskell-stack \
 rustup \
 asciinema agg \
 exercism \
 sqlfluff \
 bambu-studio
# json schema validation
npm install -g ajv-cli
npm install -g lua-fmt

# go
go install \
 honnef.co/go/tools/cmd/struct-layout@latest \
 honnef.co/go/tools/cmd/struct-layout-optimize@latest \
 github.com/x-motemen/gore/cmd/gore@latest \
 github.com/go-delve/delve/cmd/dlv@latest \
 github.com/cirocosta/asciinema-edit@latest

pip3 install md2notion

# k8s
brew install \
 fluxctl \
 fluxcd/tap/flux \
 kubernetes-helm \
 kubectl \
 kubeseal \
 kubectx \
 k3d \
 derailed/k9s/k9s
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
 obsidian notion \
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
