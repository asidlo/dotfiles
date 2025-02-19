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
  # Download the powershell '.tar.gz' archive
  curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/powershell-7.5.0-linux-x64.tar.gz

  # Create the target folder where powershell will be placed
  sudo mkdir -p /opt/microsoft/powershell/7

  # Expand powershell to the target folder
  sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

  # Set execute permissions
  sudo chmod +x /opt/microsoft/powershell/7/pwsh

  # Create the symbolic link that points to pwsh
  sudo ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
  ;;
esac

mkdir -p ~/.config/powershell
ln -svf ~/.local/src/dotfiles/powershell/pwsh-profile.linux.ps1 /home/asidlo/.config/powershell/Microsoft.PowerShell_profile.ps1
