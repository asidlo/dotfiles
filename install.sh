#!/bin/bash

set -e -o pipefail

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG

# echo an error message before exiting
trap '[ $? -ne 0 ] && echo "\"${last_command}\" command failed with exit code $?."' EXIT

DOTFILES_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")

[ -n "$RG_VERSION" ] || RG_VERSION="13.0.0"
[ -n "$FD_VERSION" ] || FD_VERSION="8.4.0"
[ -n "$DOTNET_VERSION" ] || DOTNET_VERSION="6.0"
[ -n "$UBUNTU_VERSION" ] || UBUNTU_VERSION="18.04"
[ -n "$BAT_VERSION" ] || BAT_VERSION="0.21.0"
[ -n "$GO_VERSION" ] || GO_VERSION="1.18.4"
[ -n "$GITCONFIG" ] || GITCONFIG="gitconfig.work.codespaces"

USER=$(whoami)
is_root()
{
    [ -n "$USER" ] && [ "$USER" == "root" ]
}

if [ -n "$INSTALL_ALL" ] && [ "$INSTALL_ALL" -eq 1 ]; then
    INSTALL_MARKDOWN=1
    INSTALL_JAVA=1
    INSTALL_LUA=1
    INSTALL_BASH=1
    INSTALL_PYTHON=1
    INSTALL_DOTNET=1
    INSTALL_NODE=1
    INSTALL_NVIM=1
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

export DEBIAN_FRONTEND=noninteractive

if is_root; then
    apt-get update -y && apt-get install sudo -y
fi
sudo apt-get update -y

# Download dotfiles and link if file is not already present and a symlink
ln -sfv "$DOTFILES_DIR/git/$GITCONFIG" ~/.gitconfig
ln -sfv "$DOTFILES_DIR/zsh/zshrc.min" ~/.zshrc
ln -sfv "$DOTFILES_DIR/zsh/zshenv" ~/.zshenv
ln -sfv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf

mkdir -p ~/.omnisharp
ln -sfv "$DOTFILES_DIR/misc/omnisharp.json" ~/.omnisharp/omnisharp.json

mkdir -p ~/.config
ln -sfv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml

mkdir -p ~/.local/bin
curl -sfL git.io/antibody | sh -s - -b ~/.local/bin

# Install ripgrep
# https://github.com/BurntSushi/ripgrep
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/"$RG_VERSION"/ripgrep_13.0.0_amd64.deb
sudo apt-get install ./ripgrep_"$RG_VERSION"_amd64.deb
rm ./ripgrep_"$RG_VERSION"_amd64.deb

# Install fd
# https://github.com/sharkdp/fd
curl -LO https://github.com/sharkdp/fd/releases/download/v"$FD_VERSION"/fd_"$FD_VERSION"_amd64.deb
sudo apt-get install ./fd_"$FD_VERSION"_amd64.deb
rm ./fd_"$FD_VERSION"_amd64.deb

# Install bat
curl -LO https://github.com/sharkdp/bat/releases/download/v"$BAT_VERSION"/bat_"$BAT_VERSION"_amd64.deb
sudo apt-get install ./bat_"$BAT_VERSION"_amd64.deb
rm ./bat_"$BAT_VERSION"_amd64.deb

# Install starship
curl -sS https://starship.rs/install.sh | sudo sh -s -- -y

# Install zsh
# codespaces adds a zlogin by default
if ! type zsh > /dev/null 2>&1; then
    if [ -f /etc/zsh/zlogin ]; then
        sudo mv /etc/zsh/zlogin /etc/zsh/zlogin.bkp
    fi
    sudo apt-get install zsh -y
    if [ -f /etc/zsh/zlogin.bkp ]; then
        sudo mv /etc/zsh/zlogin.bkp /etc/zsh/zlogin
    fi
fi

# Set zsh as current shell
sudo chsh -s /bin/zsh

# Install fzf
mkdir -p ~/.local/src
if [ ! -d ~/.local/src/fzf/ ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.local/src/fzf
fi
~/.local/src/fzf/install --xdg --key-bindings --completion --no-update-rc --no-bash --no-fish
ln -svf ~/.local/src/fzf/bin/fzf ~/.local/bin/fzf

# For generating english locales to be set via zshrc and used for character rendering
# sudo apt-get update -y && sudo apt-get install language-pack-en -y

sudo apt-get install locales -y

# Ensure at least the en_US.UTF-8 UTF-8 locale is available.
# Common need for both applications and things like the agnoster ZSH theme.
if ! grep -o -E '^\s*en_US.UTF-8\s+UTF-8' /etc/locale.gen > /dev/null; then
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen 
    sudo locale-gen
fi

if [ -n "$INSTALL_NVIM" ] && [ "$INSTALL_NVIM" -eq 1 ]; then
    # Install nvim runtime prerequisites
    sudo apt-get install build-essential tmux wget curl zip unzip -y

    # Install nvim
    ~/.local/src/dotfiles/nvim/download-latest-nvim-local.sh

    [ -L ~/.config/nvim ] || ln -sv "$DOTFILES_DIR/nvim/fromscratch" ~/.config/nvim
fi

if [ -n "$INSTALL_NODE" ] && [ "$INSTALL_NODE" -eq 1 ]; then
    install_npm
fi

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

    # dotnet debugger deps for netcoredbg
    # https://stackoverflow.com/a/66465559
    sudo apt-get update
    sudo apt-get install -y wget gcc-8 unzip libssl1.0.0 software-properties-common
    sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
    sudo apt-get update
    sudo apt-get install -y --only-upgrade libstdc++6

    curl -L https://github.com/Samsung/netcoredbg/releases/download/2.0.0-915/netcoredbg-linux-amd64.tar.gz -o /tmp/netcoredbg-linux-amd64.tar.gz
    tar xzvf /tmp/netcoredbg-linux-amd64.tar.gz -C /tmp
    mv /tmp/netcoredbg/* ~/.local/bin
    rm /tmp/netcoredbg-linux-amd64.tar.gz && rm -rf /tmp/netcoredbg
fi

if [ -n "$INSTALL_PYTHON" ] && [ "$INSTALL_PYTHON" -eq 1 ]; then
    sudo apt-get install python3-venv python3-pip -y
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

    sudo apt-get install build-essential libreadline-dev unzip -y
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
    sudo make install
    cd ..
    rm -rf luarocks-3.8.0

    sudo luarocks install luacheck
    sudo luarocks install lanes
fi

if [ -n "$INSTALL_BASH" ] && [ "$INSTALL_BASH" -eq 1 ]; then
    install_cargo && cargo install shellharden
    sudo apt-get install shellcheck -y
fi

if [ -n "$INSTALL_MARKDOWN" ] && [ "$INSTALL_MARKDOWN" -eq 1 ]; then
    install_npm
    npm install -g @fsouza/prettierd
    npm install -g markdownlint-cli
fi
