#!/bin/bash

if [ -z "$RG_VERSION" ]; then
  RG_VERSION="$(curl -s -I https://github.com/BurntSushi/ripgrep/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')"
fi

source /etc/os-release

# ripgrep publishes prebuilt binaries for every platform we care about, so never
# build it from source: `cargo install` needs a working rustc, which segfaults on
# start-up in emulated environments (its bundled jemalloc assumes userspace
# pointers are 48-bit clean, and faults on its first allocation when they are
# not). Note the asset matrix is not uniform -- x86_64 ships a static musl build
# but aarch64 only ships gnu -- so the libc is selected per architecture.
install_rg_from_release() {
  local arch libc tmp
  arch=$(uname -m)
  case "$arch" in
  x86_64) libc=musl ;;
  aarch64) libc=gnu ;;
  *)
    echo "No prebuilt ripgrep binary for architecture '$arch'." >&2
    return 1
    ;;
  esac
  mkdir -p ~/.local/bin
  tmp=$(mktemp -d)
  curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${arch}-unknown-linux-${libc}.tar.gz" -o "$tmp/rg.tar.gz" || { rm -rf "$tmp"; return 1; }
  tar -xzf "$tmp/rg.tar.gz" -C "$tmp" --strip-components=1 || { rm -rf "$tmp"; return 1; }
  install -m 0755 "$tmp/rg" ~/.local/bin/rg || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
}

# Install ripgrep
# https://github.com/BurntSushi/ripgrep
case "$ID" in
"mariner" | "azurelinux")
  install_rg_from_release
  ;;
"ubuntu" | "debian")
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "amd64" ]; then
    # Latest version of rg deb (>14.0.0) includes a -1 at the end of the version for some reason.
    curl -L https://github.com/BurntSushi/ripgrep/releases/download/"$RG_VERSION"/ripgrep_"$RG_VERSION"-1_amd64.deb -o /tmp/ripgrep.deb
    sudo apt-get install -y /tmp/ripgrep.deb
    rm /tmp/ripgrep.deb
  else
    install_rg_from_release
  fi
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
