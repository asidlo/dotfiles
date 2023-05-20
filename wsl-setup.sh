#!/bin/bash

mkdir -p ~/.local/src
if [ ! -d ~/.local/src/dotfiles ]; then
    git clone https://github.com/asidlo/dotfiles ~/.local/src/dotfiles
fi

ln -svf ~/.local/src/dotfiles/etc/wsl.conf /etc/wsl.conf
sudo ln -svf ~/.local/src/dotfiles/etc/wsl.conf /etc/wsl.conf
ln -svf /mnt/c/tools/neovim/nvim-win64/bin/win32yank.exe ~/.local/bin/win32yank.exe
