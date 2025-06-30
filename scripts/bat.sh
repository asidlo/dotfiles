#!/bin/bash

if [ -z "$BAT_VERSION" ]; then
  BAT_VERSION="$(curl -s -I https://github.com/sharkdp/bat/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/^v//')"
fi

source /etc/os-release

case "$ID" in
"mariner" | "azurelinux")
  SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
  "$SCRIPT_DIR/rust.sh"
  ~/.cargo/bin/cargo install bat --version "$BAT_VERSION"
  ;;
"ubuntu" | "debian")
  curl -L https://github.com/sharkdp/bat/releases/download/v"$BAT_VERSION"/bat_"$BAT_VERSION"_amd64.deb -o /tmp/bat.deb
  sudo apt-get install /tmp/bat.deb
  rm /tmp/bat.deb
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
