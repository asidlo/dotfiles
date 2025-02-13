#!/bin/bash

set -e -o pipefail

trap 'echo "Error on line $LINENO in $0: Command \"$BASH_COMMAND\" failed"; exit 1' ERR

# Get current working directory
DOTFILES_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
SCRIPT_DIR="$DOTFILES_DIR/scripts"

source /etc/os-release

# Only update locale if os is ubuntu or debian
if [ "$ID" == "ubuntu" ] || [ "$ID" == "debian" ]; then
  sudo locale-gen "en_US.UTF-8"
fi

"$SCRIPT_DIR/fd.sh"
"$SCRIPT_DIR/fzf.sh"
"$SCRIPT_DIR/bat.sh"
"$SCRIPT_DIR/rg.sh"
"$SCRIPT_DIR/starship.sh"
"$SCRIPT_DIR/zsh.sh"
"$SCRIPT_DIR/gh.sh"
"$SCRIPT_DIR/artifacts-credprovider.sh"
"$SCRIPT_DIR/az.sh"

ln -sfv "$DOTFILES_DIR/git/gitconfig.work.codespaces" ~/.gitconfig
ln -sfv "$DOTFILES_DIR/vim/minimal.vim" ~/.vimrc
ln -sfv "$DOTFILES_DIR/zsh/zshrc.min" ~/.zshrc
ln -sfv "$DOTFILES_DIR/zsh/zshenv" ~/.zshenv
ln -sfv "$DOTFILES_DIR/bash/bashrc" ~/.bashrc

mkdir -p ~/.config && ln -sfv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml

# If not running in codespaces do full install
if [ -n "$CODESPACES" ]; then
  "$SCRIPT_DIR/rust.sh"
  "$SCRIPT_DIR/lazygit.sh"
  "$SCRIPT_DIR/nvim.sh" -d ~/.local/bin
  "$SCRIPT_DIR/go.sh"
  "$SCRIPT_DIR/npm.sh"
  "$SCRIPT_DIR/dotnet.sh"
  "$SCRIPT_DIR/tmux.sh"

  ln -sfv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf
  mkdir -p ~/.config && ln -sfv "$DOTFILES_DIR/nvim/lazynvim" ~/.config/nvim
fi
