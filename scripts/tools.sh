#!/bin/bash

ln -sfv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf
ln -sfv "$DOTFILES_DIR/misc/hushlogin" ~/.hushlogin
ln -sfv "$DOTFILES_DIR/misc/shellcheckrc" ~/.shellcheckrc

mkdir -p ~/.docker
ln -sfv "$DOTFILES_DIR/misc/docker.config.json" ~/.docker/config.json
