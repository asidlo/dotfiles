#!/bin/bash

# Install cargo for rust dev
# Check if rust is already installed and if so then skip
if ! command -v cargo >/dev/null 2>&1; then
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME"/.cargo/env
fi
