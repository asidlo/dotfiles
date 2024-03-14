#!/bin/bash

# Check if zsh is installed and if not, install it
if ! command -v zsh &>/dev/null; then
	source /etc/os-release
	case "$ID" in
	debian | ubuntu)
		sudo apt-get install -y zsh
		;;
	fedora)
		sudo dnf install -y zsh
		;;
	mariner)
		sudo tdnf install -y zsh
		;;
	*)
		echo "Unsupported OS"
		exit 1
		;;
	esac
fi

mkdir -p ~/.local/bin
curl -sfL git.io/antibody | sh -s - -b ~/.local/bin

# Set zsh as current shell
sudo chsh -s /bin/zsh "$USER"
