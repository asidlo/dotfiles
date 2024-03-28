#!/bin/bash

set -e -o pipefail

trap 'echo "Error on line $LINENO in $0: Command \"$BASH_COMMAND\" failed"; exit 1' ERR

# Get current working directory
DOTFILES_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
SCRIPT_DIR="$DOTFILES_DIR/scripts"

"$SCRIPT_DIR/fd.sh"
"$SCRIPT_DIR/fzf.sh"
"$SCRIPT_DIR/bat.sh"
"$SCRIPT_DIR/rg.sh"
"$SCRIPT_DIR/lazygit.sh"
"$SCRIPT_DIR/nvim.sh" -d ~/.local/bin
"$SCRIPT_DIR/starship.sh"
"$SCRIPT_DIR/tmux.sh"
"$SCRIPT_DIR/zsh.sh"

ln -sfv "$DOTFILES_DIR/git/gitconfig.work.codespaces" ~/.gitconfig
ln -sfv "$DOTFILES_DIR/vim/minimal.vim" ~/.vimrc
ln -sfv "$DOTFILES_DIR/zsh/zshrc.min" ~/.zshrc
ln -sfv "$DOTFILES_DIR/zsh/zshenv" ~/.zshenv
ln -sfv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf
mkdir -p ~/.config && ln -sfv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml
