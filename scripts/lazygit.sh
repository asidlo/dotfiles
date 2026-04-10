#!/bin/bash

if command -v lazygit &> /dev/null; then
    exit 0
fi

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
MACHINE=$(uname -m)
case "$MACHINE" in
  x86_64) LAZYGIT_ARCH="x86_64" ;;
  aarch64) LAZYGIT_ARCH="arm64" ;;
  *) echo "Unsupported architecture: $MACHINE"; exit 1 ;;
esac
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
mkdir /tmp/lazygit && tar xf /tmp/lazygit.tar.gz -C /tmp/lazygit
mv /tmp/lazygit/lazygit ~/.local/bin && rm -rf /tmp/lazygit && rm /tmp/lazygit.tar.gz
