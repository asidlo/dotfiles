#!/bin/bash

if command -v lazygit &> /dev/null; then
    exit 0
fi

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
mkdir /tmp/lazygit && tar xf /tmp/lazygit.tar.gz -C /tmp/lazygit
mv /tmp/lazygit/lazygit ~/.local/bin && rm -rf /tmp/lazygit && rm /tmp/lazygit.tar.gz
