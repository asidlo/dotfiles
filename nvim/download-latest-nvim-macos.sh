#!/bin/bash

set -e

mkdir -p /tmp/nvim

curl -L https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz -o /tmp/nvim/nvim-macos.tar.gz

tar xzvf /tmp/nvim/nvim-macos.tar.gz -C /tmp/nvim

mv /tmp/nvim/nvim-osx64 ~/.local/nvim

ln -svf  ~/.local/nvim/bin/nvim ~/.local/bin/nvim

rm -rf /tmp/nvim
