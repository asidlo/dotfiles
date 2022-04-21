#!/bin/bash

mkdir -p ~/.local/bin

curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o ~/.local/nvim.appimage

chmod u+x ~/.local/nvim.appimage

~/.local/nvim.appimage --appimage-extract

rm ~/.local/nvim.appimage
mv ~/.local/squashfs-root ~/.local/nvim

ln -svf ~/.local/nvim/AppRun ~/.local/bin/nvim
