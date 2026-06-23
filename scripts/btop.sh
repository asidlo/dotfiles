#!/bin/bash
# Resource monitor (htop-like): https://github.com/aristocratos/btop
command -v btop >/dev/null 2>&1 && exit 0

source /etc/os-release

case "$ID" in
ubuntu | debian)
  sudo apt-get install -y btop
  ;;
mariner | azurelinux)
  sudo tdnf install -y btop
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
