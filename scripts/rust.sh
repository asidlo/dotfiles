#!/bin/bash

# Install cargo for rust dev
# Check if rust is already installed and if so then skip
if ! command -v cargo >/dev/null 2>&1; then
  # --no-modify-path: rustup otherwise appends `. "$HOME/.cargo/env"` to
  # ~/.zshenv, ~/.bashrc and ~/.profile. Those are symlinks into this repo, so
  # every fresh install left the working tree dirty with a line the configs
  # already carry (guarded by a -f test, which rustup's is not).
  curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
  source "$HOME"/.cargo/env
fi
