#!/bin/bash
# Per-directory environments: https://direnv.net
command -v direnv >/dev/null 2>&1 && exit 0

mkdir -p ~/.local/bin

# The official installer honours $bin_path for the install location.
export bin_path="$HOME/.local/bin"
curl -sfL https://direnv.net/install.sh | bash
