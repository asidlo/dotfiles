#!/bin/bash

# Install fzf
mkdir -p ~/.local/src
if [ ! -d ~/.local/src/fzf/ ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.local/src/fzf
fi
~/.local/src/fzf/install --xdg --key-bindings --completion --no-update-rc --no-bash --no-fish
ln -svf ~/.local/src/fzf/bin/fzf ~/.local/bin/fzf
