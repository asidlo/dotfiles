#!/bin/bash

set -e

RG_VERSION="13.0.0"
FD_VERSION="8.4.0"
DOTNET_VERSION="6.0"
UBUNTU_VERSION="18.04"
BAT_VERSION="0.21.0"
GO_VERSION="1.18.3"
GITCONFIG="gitconfig.work"

if [ -n "$INSTALL_ALL" ] && [ "$INSTALL_ALL" -eq 1 ]; then
    INSTALL_MARKDOWN=1
    INSTALL_JAVA=1
    INSTALL_LUA=1
    INSTALL_BASH=1
    INSTALL_PYTHON=1
    INSTALL_DOTNET=1
fi

install_npm()
{
    command -v npm > /dev/null 2&>1 && return 0

    # Install nvm for npm and nodejs
    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
}

install_cargo()
{
    command -v cargo > /dev/null 2&>1 && return 0

    # Install cargo for rust dev
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME"/.cargo/env
}

# Needs to be run as root if sudo isnt already installed
command -v sudo 2&> /dev/null || apt install sudo

# For generating english locales to be set via zshrc and used for character rendering
sudo apt install language-pack-en -y

# Install zsh
sudo apt install zsh -y

# Set zsh as current shell
sudo chsh -s /bin/zsh

# Download dotfiles and link if file is not already present and a symlink
[ -L ~/.gitconfig ] || ln -sv ~/.local/src/dotfiles/git/"$GITCONFIG" ~/.gitconfig
[ -L ~/.zshrc ] || ln -sv ~/.local/src/dotfiles/zsh/zshrc.min ~/.zshrc
[ -L ~/.zshenv ] || ln -sv ~/.local/src/dotfiles/zsh/zshenv ~/.zshenv
[ -L ~/.tmux.conf ] || ln -sv ~/.local/src/dotfiles/misc/tmux.conf ~/.tmux.conf

mkdir -p ~/.omnisharp
[ -L ~/.omnisharp/omnisharp.json ] || ln -sv ~/.local/src/dotfiles/misc/omnisharp.json ~/.omnisharp/omnisharp.json

mkdir -p ~/.config
[ -L ~/.config/starship.toml ] || ln -sv ~/.local/src/dotfiles/zsh/starship.toml ~/.config/starship.toml
[ -L ~/.config/nvim ] || ln -sv ~/.local/src/dotfiles/nvim/fromscratch ~/.config/nvim

mkdir -p ~/.local/bin
curl -sfL git.io/antibody | sh -s - -b ~/.local/bin

# Install ripgrep
# https://github.com/BurntSushi/ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/"$RG_VERSION"/ripgrep_13.0.0_amd64.deb
sudo apt install ./ripgrep_"$RG_VERSION"_amd64.deb
rm ./ripgrep_"$RG_VERSION"_amd64.deb

# Install fd
# https://github.com/sharkdp/fd
curl -LO https://github.com/sharkdp/fd/releases/download/v"$FD_VERSION"/fd_"$FD_VERSION"_amd64.deb
sudo apt install ./fd_"$FD_VERSION"_amd64.deb
rm ./fd_"$FD_VERSION"_amd64.deb

# Install bat
curl -LO https://github.com/sharkdp/bat/releases/download/v"$BAT_VERSION"/bat_"$BAT_VERSION"_amd64.deb
sudo apt install ./bat_"$BAT_VERSION"_amd64.deb
rm ./bat_"$BAT_VERSION"_amd64.deb

# Install starship
curl -sS https://starship.rs/install.sh | sudo sh -s -- -y

# Install fzf
mkdir -p ~/.local/src
if [ ! -d ~/.local/src/fzf/ ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.local/src/fzf
fi
~/.local/src/fzf/install --xdg --key-bindings --completion --no-update-rc --no-bash --no-fish

# Install nvim
~/.local/src/dotfiles/nvim/download-stable-nvim-local.sh

# Install nvim runtime prerequisites
sudo apt install build-essential tmux zip unzip -y

# Install dotnet
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
if [ -n "$INSTALL_DOTNET" ] && [ "$INSTALL_DOTNET" -eq 1 ]; then
    wget https://packages.microsoft.com/config/ubuntu/"$UBUNTU_VERSION"/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt-get update; \
      sudo apt-get install -y apt-transport-https && \
      sudo apt-get update && \
      sudo apt-get install -y dotnet-sdk-"$DOTNET_VERSION"
fi

if [ -n "$INSTALL_PYTHON" ] && [ "$INSTALL_PYTHON" -eq 1 ]; then
    sudo apt install python3-venv python3-pip -y
    /usr/bin/python3 -m pip install pynvim
    pip3 install black
fi

if [ -n "$INSTALL_GO" ] && [ "$INSTALL_GO" -eq 1 ]; then
    curl -LO https://go.dev/dl/go"$GO_VERSION".linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go"$GO_VERSION".linux-amd64.tar.gz
    rm ./go"$GO_VERSION".linux-amd64.tar.gz
fi

# Install sdkman for java
if [ -n "$INSTALL_JAVA" ] && [ "$INSTALL_JAVA" -eq 1 ]; then
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk i java 17.0.3-ms
fi

# Install formatters/linters
if [ -n "$INSTALL_LUA" ] && [ "$INSTALL_LUA" -eq 1 ]; then
    install_cargo && cargo install stylua

    sudo apt install build-essential libreadline-dev unzip -y
    curl -R -O http://www.lua.org/ftp/lua-5.3.5.tar.gz
    tar -zxf lua-5.3.5.tar.gz
    rm lua-5.3.5.tar.gz
    cd lua-5.3.5
    make linux test
    sudo make install
    cd ..
    rm -rf ./lua-5.3.5

    wget https://luarocks.org/releases/luarocks-3.8.0.tar.gz
    tar zxpf luarocks-3.8.0.tar.gz
    rm luarocks-3.8.0.tar.gz
    cd luarocks-3.8.0
    ./configure --with-lua-include=/usr/local/include
    make
    make install
    cd ..
    rm -rf luarocks-3.8.0

    sudo luarocks install luacheck
    sudo luarocks install lanes
fi

if [ -n "$INSTALL_BASH" ] && [ "$INSTALL_BASH" -eq 1 ]; then
    install_cargo && cargo install shellharden
    sudo apt install shellcheck -y
fi

if [ -n "$INSTALL_MARKDOWN" ] && [ "$INSTALL_MARKDOWN" -eq 1 ]; then
    install_npm
    npm install -g @fsouza/prettierd
    npm install -g markdownlint-cli
fi
