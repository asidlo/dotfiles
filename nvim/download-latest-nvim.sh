#!/bin/bash

curl -L https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage -o /tmp/nvim

chmod 755 /tmp/nvim

sudo mv /tmp/nvim /usr/local/bin

