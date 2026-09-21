#!/bin/bash

if [ ! -d ~/.tmux/plugins/tpm ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install the plugins declared in misc/tmux.conf so a fresh setup has a working
# config without needing an interactive `prefix + I` inside tmux. Idempotent:
# tpm reports "Already installed" and skips plugins that are already cloned.
if [ -x ~/.tmux/plugins/tpm/bin/install_plugins ]; then
	export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/"
	~/.tmux/plugins/tpm/bin/install_plugins
fi
