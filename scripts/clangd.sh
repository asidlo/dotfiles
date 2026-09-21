#!/bin/bash

# Install clangd from the distro so nvim can use it.
#
# mason cannot supply clangd on Linux arm64: upstream only publishes
# darwin_x64, darwin_arm64, linux_x64_gnu and win_x64 assets, so every startup
# on an arm64 box fails with "The current platform is unsupported." The
# LazyVim clangd extra invokes a bare `clangd`, so a distro binary on PATH
# works everywhere and keeps mason quiet.

if command -v clangd >/dev/null 2>&1; then
  exit 0
fi

source /etc/os-release 2>/dev/null || true

case "$ID" in
debian | ubuntu)
  sudo apt-get update -y || echo "clangd.sh: apt-get update failed" >&2
  sudo apt-get install clangd -y || echo "clangd.sh: apt install failed; install clangd manually" >&2
  ;;
mariner | azurelinux)
  sudo tdnf install clang-tools-extra -y || echo "clangd.sh: tdnf install failed; install clangd manually" >&2
  ;;
*)
  echo "clangd.sh: unsupported distribution '$ID'; install clangd manually" >&2
  ;;
esac

# install.sh runs under `set -e`; never abort the whole bootstrap over clangd.
exit 0
