#!/bin/bash

DOTFILES_DIR=$(dirname "${BASH_SOURCE[0]}")

pushd "$DOTFILES_DIR/nvim" || exit

source install.sh

popd || exit
