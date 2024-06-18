#!/bin/bash

# TODO (AS): Restart wsl for /etc conf to take effect
mkdir -p ~/.local/src
if [ ! -d ~/.local/src/dotfiles ]; then
    git clone https://github.com/asidlo/dotfiles ~/.local/src/dotfiles
fi

# Install windows programs and settings first then run this in wsl
sudo ln -svf ~/.local/src/dotfiles/etc/wsl.conf /etc/wsl.conf
mkdir -p ~/.local/bin
ln -svf /mnt/c/Program\ Files/Neovim/bin/win32yank.exe ~/.local/bin/win32yank.exe

# Restart wsl

~/.local/src/dotfiles/install.sh