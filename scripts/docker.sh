#!/bin/bash

# Get current script location
DOTFILES_DIR=$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-$0}")")")

# Detect OS
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

case "$OS_ID" in
mariner | azurelinux)
    echo "Detected $OS_ID. Installing Docker via tdnf..."
    sudo tdnf install -y moby-engine moby-cli
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "Start shell with docker group via 'newgrp docker', changes will only take effect on restart"
    ;;
ubuntu)
    echo "Detected Ubuntu. Installing Docker via apt..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    if ! command -v docker >/dev/null 2>&1; then
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    ;;
*)
    echo "Unsupported OS: $OS_ID. Please install Docker manually."
    ;;
esac

# mkdir -p ~/.docker
# ln -sfv "$DOTFILES_DIR/misc/docker.config.json" ~/.docker/config.json
