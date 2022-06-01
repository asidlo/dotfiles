#!/bin/bash

set -e

RG_VERSION="13.0.0"
FD_VERSION="8.4.0"
DOTNET_VERSION="6.0"
UBUNTU_VERSION="18.04"
BAT_VERSION="0.21.0"

GITCONFIG="gitconfig.work"

# Needs to be run as root if sudo isnt already installed
command -v sudo 2&> /dev/null || apt install sudo

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

# Install zsh
sudo apt install zsh -y

# Set zsh as current shell
sudo chsh -s /bin/zsh

# Install starship
curl -sS https://starship.rs/install.sh | sh

# Install dotnet
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
wget https://packages.microsoft.com/config/ubuntu/"$UBUNTU_VERSION"/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-"$DOTNET_VERSION"

# Install fzf
mkdir -p ~/.local/src
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.local/src/fzf
~/.local/src/fzf/install --xdg --key-bindings --completion --no-update-rc --no-bash --no-fish

# Download dotfiles and link

git clone https://github.com/asidlo/dotfiles.git ~/.local/src/dotfiles
ln -svf ~/.local/src/dotfiles/git/"$GITCONFIG" ~/.gitconfig
ln -svf ~/.local/src/dotfiles/zsh/zshrc.min ~/.zshrc
ln -svf ~/.local/src/dotfiles/zsh/zshenv ~/.zshenv

mkdir -p ~/.config
ln -svf ~/.local/src/dotfiles/zsh/starship.toml ~/.config/starship.toml
ln -svf ~/.local/src/dotfiles/nvim/fromscratch ~/.config/nvim

~/.local/src/dotfiles/nvim/download-stable-nvim-local.sh
