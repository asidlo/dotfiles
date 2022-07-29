#!/bin/bash

export DOTFILES_DIR="/workspace/.codespaces/.persistedshare/dotfiles"
export GITCONFIG="gitconfig.work"

pushd "$DOTFILES_DIR/nvim" || exit

source install.sh

popd || exit
