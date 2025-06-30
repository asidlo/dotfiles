#!/bin/bash

source /etc/os-release

mkdir -p ~/.local/{src,bin}

case "$ID" in
ubuntu)
    sudo apt-get update -y
    sudo apt-get install build-essential tmux wget curl zip unzip python3 python3-pip python3-venv -y
    ;;
mariner | azurelinux)
    sudo tdnf update -y
    sudo tdnf install build-essential tmux wget curl zip unzip python3 python3-pip -y
    ;;
*)
    echo "Unsupported distribution: $ID"
    exit 1
    ;;
esac
