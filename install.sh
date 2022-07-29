#!/bin/bash

DOTFILES_DIR=$(dirname "${BASH_SOURCE[0]}")

export DOTFILES_DIR

pushd "$DOTFILES_DIR/nvim" || exit

source install-tools.sh

popd || exit
