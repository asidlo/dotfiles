#!/bin/bash

if [ -z "$FD_VERSION" ]; then
  FD_VERSION="$(curl -s -I https://github.com/sharkdp/fd/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/^v//')"
fi

source /etc/os-release

# Azure Linux ships no fd package, and `cargo install` is not a usable fallback:
# building from source needs a working rustc, which segfaults on start-up in
# emulated environments (rustc's bundled jemalloc assumes userspace pointers are
# 48-bit clean, and faults on its first allocation when they are not). Download
# the prebuilt static musl binary instead -- the same approach eza.sh takes.
install_fd_from_release() {
  local arch tmp
  arch=$(uname -m)
  case "$arch" in
  x86_64 | aarch64) ;;
  *)
    echo "No prebuilt fd binary for architecture '$arch'." >&2
    return 1
    ;;
  esac
  mkdir -p ~/.local/bin
  tmp=$(mktemp -d)
  curl -fsSL "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${arch}-unknown-linux-musl.tar.gz" -o "$tmp/fd.tar.gz" || { rm -rf "$tmp"; return 1; }
  tar -xzf "$tmp/fd.tar.gz" -C "$tmp" --strip-components=1 || { rm -rf "$tmp"; return 1; }
  install -m 0755 "$tmp/fd" ~/.local/bin/fd || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
}

case "$ID" in
"mariner" | "azurelinux")
  install_fd_from_release
  ;;
"ubuntu" | "debian")
  ARCH=$(dpkg --print-architecture)
  curl -L https://github.com/sharkdp/fd/releases/download/v"$FD_VERSION"/fd_"$FD_VERSION"_"$ARCH".deb -o /tmp/fd.deb
  sudo apt-get install -y /tmp/fd.deb
  rm /tmp/fd.deb
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
