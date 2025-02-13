#!/bin/bash

source /etc/os-release

if command -v pwsh &>/dev/null; then
  exit 0
fi

# Install powershell
case "$ID" in
ubuntu)
	sudo apt-get update &&
		sudo apt-get install -y wget apt-transport-https software-properties-common &&
		wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" &&
		sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb && sudo apt-get update &&
		sudo apt-get install -y powershell
	;;
*)
	echo "Unsupported OS"
	exit 1
	;;
esac

mkdir -p ~/.config/powershell
ln -svf ~/.local/src/dotfiles/powershell/pwsh-profile.linux.ps1 /home/asidlo/.config/powershell/Microsoft.PowerShell_profile.ps1
