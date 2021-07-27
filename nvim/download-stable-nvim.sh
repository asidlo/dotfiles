#!/bin/bash

curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o /tmp/nvim

chmod 755 /tmp/nvim

sudo mv /tmp/nvim /usr/local/bin

