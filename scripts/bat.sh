#!/bin/bash
# bat: a cat clone with syntax highlighting: https://github.com/sharkdp/bat
# Be additive: never clobber an existing bat/batcat. The upstream .deb uses the
# Debian package name "bat", which shares files with apt's bat package (the one
# that ships /usr/bin/batcat), so reinstalling it would clobber batcat and break
# setups (e.g. comfort-shell) whose `bat` shim execs `batcat`.
if command -v bat >/dev/null 2>&1; then
  exit 0
fi

# Only batcat present (apt's renamed binary): expose a `bat` shim so configs that
# invoke `bat` directly (e.g. the bash/bashrc fzf preview) keep working, without
# clobbering batcat.
if command -v batcat >/dev/null 2>&1; then
  mkdir -p ~/.local/bin
  ln -sfv "$(command -v batcat)" ~/.local/bin/bat
  exit 0
fi

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
  ARCH=$(dpkg --print-architecture)
  curl -L https://github.com/sharkdp/bat/releases/download/v"$BAT_VERSION"/bat_"$BAT_VERSION"_"$ARCH".deb -o /tmp/bat.deb
  sudo apt-get install -y /tmp/bat.deb
  rm /tmp/bat.deb
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
