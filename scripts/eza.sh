#!/bin/bash
# Modern, colourful ls replacement: https://github.com/eza-community/eza
command -v eza >/dev/null 2>&1 && exit 0

source /etc/os-release

case "$ID" in
ubuntu | debian)
  # eza is in apt from Ubuntu 23.10+ / Debian 13+; fall back to the release
  # tarball on older releases that don't package it yet.
  if apt-cache show eza >/dev/null 2>&1; then
    sudo apt-get install -y eza
  else
    ARCH=$(uname -m)
    mkdir -p ~/.local/bin
    curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH}-unknown-linux-gnu.tar.gz" -o /tmp/eza.tar.gz
    tar -xzf /tmp/eza.tar.gz -C ~/.local/bin eza
    rm -f /tmp/eza.tar.gz
  fi
  ;;
mariner | azurelinux)
  SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
  "$SCRIPT_DIR/rust.sh"
  ~/.cargo/bin/cargo install eza
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
