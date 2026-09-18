#!/bin/bash
# Modern, colourful ls replacement: https://github.com/eza-community/eza
command -v eza >/dev/null 2>&1 && exit 0

source /etc/os-release

# Download the prebuilt eza release binary into ~/.local/bin. eza publishes glibc
# ("gnu") binaries for x86_64 and aarch64, which cover Debian/Ubuntu and Azure
# Linux/Mariner alike (all glibc-based). This avoids a slow, fragile from-source
# cargo build (palette, an eza dependency, fails to compile on some toolchains).
install_eza_from_release() {
  local arch tmp
  arch=$(uname -m)
  case "$arch" in
  x86_64 | aarch64) ;;
  *)
    echo "No prebuilt eza binary for architecture '$arch'." >&2
    return 1
    ;;
  esac
  mkdir -p ~/.local/bin
  tmp=$(mktemp -d)
  curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz" -o "$tmp/eza.tar.gz"
  tar -xzf "$tmp/eza.tar.gz" -C "$tmp"
  install -m 0755 "$tmp/eza" ~/.local/bin/eza
  rm -rf "$tmp"
}

case "$ID" in
ubuntu | debian)
  # eza is in apt from Ubuntu 23.10+ / Debian 13+; fall back to the release
  # tarball on older releases that don't package it yet.
  if apt-cache show eza >/dev/null 2>&1; then
    sudo apt-get install -y eza
  else
    install_eza_from_release
  fi
  ;;
mariner | azurelinux)
  install_eza_from_release
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
