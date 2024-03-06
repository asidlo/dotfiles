#!/bin/bash

ln -sfv "$DOTFILES_DIR/zsh/zshrc.min" ~/.zshrc
ln -sfv "$DOTFILES_DIR/zsh/zshenv" ~/.zshenv

mkdir -p ~/.local/bin
curl -sfL git.io/antibody | sh -s - -b ~/.local/bin
