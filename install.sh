#!/bin/bash

export DOTFILES_DIR=$(dirname "${BASH_SOURCE[0]}")
export GITCONFIG="gitconfig.work"

pushd "$DOTFILES_DIR/nvim" || exit

source install.sh

popd || exit
