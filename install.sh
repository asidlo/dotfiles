#!/bin/bash

set -e -o pipefail

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG

# echo an error message before exiting
trap '[ $? -ne 0 ] && echo "\"${last_command}\" command failed with exit code $?."' EXIT

# * Check if running in WSL and make sure to symlink /etc/wsl.conf since we dont want to
#   include windows paths when using npm
# * Also symlink from C:\Program Files\Neovim\bin\win32yank.exe to ~/.local/bin/win32yank.exe
# * If running ubuntu 18 then when installing node use nvm install 16.15.1 instead of latest
#   This will prevent the GCLIB_2.28 not found error
# * Also would be good to maybe have it install the lsps and the treesitter syntaxs when installing nvim
# * And should refactor into functions that can be called via flags

DOTFILES_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")

[ "$RG_VERSION" != "" ] || RG_VERSION="13.0.0"
[ "$FD_VERSION" != "" ] || FD_VERSION="8.6.0"
[ "$DOTNET_VERSION" != "" ] || DOTNET_VERSION="7.0"
[ "$UBUNTU_VERSION" != "" ] || UBUNTU_VERSION="22.04"
[ "$BAT_VERSION" != "" ] || BAT_VERSION="0.22.1"
[ "$GO_VERSION" != "" ] || GO_VERSION="1.19.4"
[ "$GITCONFIG" != "" ] || GITCONFIG="gitconfig"
[ "$LUA_VERSION" != "" ] || LUA_VERSION="5.4.4"
[ "$LUAROCKS_VERSION" != "" ] || LUAROCKS_VERSION="3.9.1"
[ "$JAVA_VERSION" != "" ] || JAVA_VERSION="17.0.3-ms"
[ "$NETCOREDBG_VERSION" != "" ] || NETCOREDBG_VERSION="2.2.0-947"

USER=$(whoami)
is_root()
{
    [ "$USER" != "" ] && [ "$USER" == "root" ]
}

if [ "$INSTALL_ALL" != "" ] && [ "$INSTALL_ALL" -eq 1 ]; then
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
    command -v npm > /dev/null && return 0

    # Install nvm for npm and nodejs
    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
}

install_cargo()
{
    command -v cargo > /dev/null 2>&1 && return 0

    # Install cargo for rust dev
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME"/.cargo/env
}

export DEBIAN_FRONTEND=noninteractive

if is_root; then
    export HOME=/root
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
sudo chsh -s /bin/zsh "$USER"

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
    sudo bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen' 
    sudo locale-gen
fi

if [ "$INSTALL_NVIM" != "" ] && [ "$INSTALL_NVIM" -eq 1 ]; then
    # Install nvim runtime prerequisites
    sudo apt-get install build-essential tmux wget curl zip unzip -y

    # Install nvim
    # ~/.local/src/dotfiles/nvim/download-latest-nvim-local.sh
    
    # https://gist.github.com/gvenzl/1386755861fb42db492276d3864a378c
    latest_tag=$(curl -s https://api.github.com/repos/MordechaiHadad/bob/releases/latest | sed -Ene '/^ *"tag_name": *"(v.+)",$/s//\1/p')
    echo "Using version $latest_tag"
    
    curl -L -o /tmp/bob.zip "https://github.com/MordechaiHadad/bob/releases/download/$latest_tag/bob-linux-x86_64.zip"
    unzip /tmp/bob.zip -d /tmp/bob
    chmod +x /tmp/bob/bob
    mv /tmp/bob/bob ~/.local/bin
    rm -f /tmp/bob.zip && rm -rf /tmp/bob
    
    # Install nightly neovim
    mkdir -p ~/.local/share
    ~/.local/bin/bob use nightly
    
    # Add current neovim version to PATH
    ln -svf ~/.local/share/neovim/bin/nvim ~/.local/bin/nvim

    # Add symlink for config
    [ -L ~/.config/nvim ] || ln -sv "$DOTFILES_DIR/nvim/fromscratch" ~/.config/nvim
fi

if [ "$INSTALL_NODE" != "" ] && [ "$INSTALL_NODE" -eq 1 ]; then
    install_npm
fi

# Install dotnet
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
if [ "$INSTALL_DOTNET" != "" ] && [ "$INSTALL_DOTNET" -eq 1 ]; then
    wget https://packages.microsoft.com/config/ubuntu/"$UBUNTU_VERSION"/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt-get update; \
      sudo apt-get install -y apt-transport-https && \
      sudo apt-get update && \
      sudo apt-get install -y dotnet-sdk-"$DOTNET_VERSION"

    # dotnet debugger deps for netcoredbg
    # https://stackoverflow.com/a/66465559
#     sudo apt-get update
#     sudo apt-get install -y wget gcc-8 unzip libssl1.0.0 software-properties-common
#     sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
#     sudo apt-get update
#     sudo apt-get install -y --only-upgrade libstdc++6

    curl -L https://github.com/Samsung/netcoredbg/releases/download/"$NETCOREDBG_VERSION"/netcoredbg-linux-amd64.tar.gz -o /tmp/netcoredbg-linux-amd64.tar.gz
    tar xzvf /tmp/netcoredbg-linux-amd64.tar.gz -C /tmp
    mv /tmp/netcoredbg/* ~/.local/bin
    rm /tmp/netcoredbg-linux-amd64.tar.gz && rm -rf /tmp/netcoredbg
fi

if [ "$INSTALL_PYTHON" != "" ] && [ "$INSTALL_PYTHON" -eq 1 ]; then
    sudo apt-get install python3-venv python3-pip -y
    /usr/bin/python3 -m pip install pynvim
    pip3 install black
fi

if [ "$INSTALL_GO" != "" ] && [ "$INSTALL_GO" -eq 1 ]; then
    curl -LO https://go.dev/dl/go"$GO_VERSION".linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go"$GO_VERSION".linux-amd64.tar.gz
    rm ./go"$GO_VERSION".linux-amd64.tar.gz
fi

# Install sdkman for java
if [ "$INSTALL_JAVA" != "" ] && [ "$INSTALL_JAVA" -eq 1 ]; then
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk i java "$JAVA_VERSION"
fi

# Install formatters/linters
if [ "$INSTALL_LUA" != "" ] && [ "$INSTALL_LUA" -eq 1 ]; then
    install_cargo && cargo install stylua

    sudo apt-get install build-essential libreadline-dev unzip -y
    curl -R -O http://www.lua.org/ftp/lua-"$LUA_VERSION".tar.gz
    tar -zxf lua-"$LUA_VERSION".tar.gz
    rm lua-"$LUA_VERSION".tar.gz
    cd lua-"$LUA_VERSION"
    make linux test
    sudo make install
    cd ..
    rm -rf ./lua-"$LUA_VERSION"

    wget https://luarocks.org/releases/luarocks-"$LUAROCKS_VERSION".tar.gz
    tar zxpf luarocks-"$LUAROCKS_VERSION".tar.gz
    rm luarocks-"$LUAROCKS_VERSION".tar.gz
    cd luarocks-"$LUAROCKS_VERSION"
    ./configure --with-lua-include=/usr/local/include
    make
    sudo make install
    cd ..
    rm -rf luarocks-"$LUAROCKS_VERSION"

    sudo luarocks install luacheck
    sudo luarocks install lanes
fi

if [ "$INSTALL_BASH" != "" ] && [ "$INSTALL_BASH" -eq 1 ]; then
    install_cargo && cargo install shellharden
    sudo apt-get install shellcheck -y
fi

if [ "$INSTALL_MARKDOWN" != "" ] && [ "$INSTALL_MARKDOWN" -eq 1 ]; then
    install_npm
    npm install -g @fsouza/prettierd
    npm install -g markdownlint-cli
    ln -sfv "$DOTFILES_DIR/markdownlint.json" ~/.markdownlint.json
fi
