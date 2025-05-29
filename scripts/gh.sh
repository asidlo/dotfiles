#!/bin/bash

trap 'echo "Error on line $LINENO in $0: Command \"$BASH_COMMAND\" failed"; exit 1' ERR

function install_golang() {
  command -v go &>/dev/null && return

  cd /tmp || return

  # Get the latest version of golang release
  latest_version=$(curl -s -L https://golang.org/dl/?mode=json | grep -oP '"version": "\K[^"]+' | head -n 1)

  # Download the latest version of golang
  curl -L -o "$latest_version.linux-amd64.tar.gz" "https://golang.org/dl/$latest_version.linux-amd64.tar.gz"

  # Check if go is installed, if not install
  rm -rf /usr/local/go && tar -C /usr/local -xzf "$latest_version.linux-amd64.tar.gz"

  # Clean up
  rm -rf /tmp/"$latest_version.linux-amd64.tar.gz"
}

source /etc/os-release

case $ID in
debian | ubuntu)
  type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
    sudo apt update &&
    sudo apt install gh -y
  ;;
mariner | azurelinux)
  sudo tdnf install gh -y
  ;;
centos | fedora | rhel)
  sudo dnf install 'dnf-command(config-manager)'
  sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
  sudo dnf install gh
  ;;
*)
  install_golang

  git clone https://github.com/cli/cli.git /tmp/gh-cli
  cd /tmp/gh-cli || exit 1

  # installs to /usr/local/bin/gh
  make install
  ;;
esac
