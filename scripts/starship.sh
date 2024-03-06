#!/bin/bash

curl -sS https://starship.rs/install.sh | sudo sh -s -- -y

mkdir -p ~/.config
ln -sfv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml
