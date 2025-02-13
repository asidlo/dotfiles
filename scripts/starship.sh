#!/bin/bash

if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
fi
