#!/bin/bash

set -e -o pipefail

trap 'echo "Error on line $LINENO in $0: Command \"$BASH_COMMAND\" failed"; exit 1' ERR

# Get current working directory
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")

"$SCRIPT_DIR/fd.sh"
"$SCRIPT_DIR/fzf.sh"
"$SCRIPT_DIR/bat.sh"
"$SCRIPT_DIR/rg.sh"
"$SCRIPT_DIR/lazygit.sh"
"$SCRIPT_DIR/nvim.sh"
"$SCRIPT_DIR/starship.sh"
"$SCRIPT_DIR/tmux.sh"
"$SCRIPT_DIR/zsh.sh"

ln -sfv "$DOTFILES_DIR/git/gitconfig.work" ~/.gitconfig
ln -sfv "$DOTFILES_DIR/vim/minimal.vim" ~/.vimrc
ln -sfv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf
mkdir -p ~/.config && ln -sfv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml
