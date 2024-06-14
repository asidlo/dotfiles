#!/bin/bash

# Install windows programs and settings first then run this in wsl
sudo ln -svf ~/.local/src/dotfiles/etc/wsl.conf /etc/wsl.conf
ln -svf /mnt/c/Program\ Files/Neovim/bin/win32yank.exe ~/.local/bin/win32yank.exe

# TODO (AS): Restart wsl for /etc conf to take effect

mkdir -p ~/.local/src
if [ ! -d ~/.local/src/dotfiles ]; then
    git clone https://github.com/asidlo/dotfiles ~/.local/src/dotfiles
fi

~/.local/src/dotfiles/install.sh