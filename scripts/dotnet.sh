#!/bin/bash

# Get current script location
DOTFILES_DIR=$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-$0}")")")
DOTNET_INSTALL_DIR="${DOTNET_INSTALL_DIR:-$HOME/.dotnet}"

mkdir -p ~/.omnisharp
ln -sfv "$DOTFILES_DIR/misc/omnisharp.json" ~/.omnisharp/omnisharp.json

# Detect OS and install latest LTS .NET SDK using system package manager
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

case "$OS_ID" in
mariner | azurelinux)
    echo "Detected $OS_ID. Installing latest LTS .NET SDK via tdnf..."
    sudo tdnf update -y
    latest_sdk=$(tdnf list available dotnet-sdk* 2>/dev/null | awk '/dotnet-sdk-[0-9]+\.[0-9]+/ {print $1}' | sort -V | tail -n1)
    if [ -n "$latest_sdk" ]; then
        sudo tdnf install -y "$latest_sdk"
    else
        echo "Could not determine latest dotnet-sdk version for tdnf."
    fi
    ;;
ubuntu)
    echo "Detected Ubuntu. Installing latest LTS .NET SDK via apt..."
    # Add Microsoft package repository if not already present
    if ! grep -q "packages.microsoft.com" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        wget "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
    fi
    sudo apt-get update
    latest_sdk=$(apt-cache search '^dotnet-sdk-[0-9]+$' | awk '{print $1}' | grep -Eo 'dotnet-sdk-[0-9]+' | sort -V | tail -n1)
    if [ -n "$latest_sdk" ]; then
        sudo apt-get install -y "$latest_sdk"
    else
        echo "Could not determine latest dotnet-sdk version for apt."
    fi
    ;;
*)
    echo "Unsupported OS: $OS_ID. Falling back to dotnet-install.sh script."
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel LTS --install-dir "$DOTNET_INSTALL_DIR"
    ;;
esac
