#!/bin/bash

mkdir -p ~/.docker
ln -sfv "$DOTFILES_DIR/misc/docker.config.json" ~/.docker/config.json
