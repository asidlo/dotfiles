#!/bin/bash
# Smarter cd that learns your habits: https://github.com/ajeetdsouza/zoxide
command -v zoxide >/dev/null 2>&1 && exit 0

source /etc/os-release

mkdir -p ~/.local/bin

case "$ID" in
mariner | azurelinux)
  SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
  "$SCRIPT_DIR/rust.sh"
  ~/.cargo/bin/cargo install zoxide --locked
  ;;
*)
  # Official installer; --bin-dir keeps it on the ~/.local/bin we already PATH.
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir ~/.local/bin
  ;;
esac
