#!/bin/bash

# Install the npm-based tools that nvim expects, globally.
#
# mason pins an exact version for every npm package it manages. Corporate npm
# mirrors frequently lag those pins, and mason then retries (and fails) on
# every startup:
#
#   npm error notarget No matching version found for prettier@3.9.8
#   npm error notarget No matching version found for bash-language-server@5.8.0
#
# Installing them globally puts them on PATH, which conform and lspconfig both
# prefer, and lets the nvim config skip mason for these tools entirely.
#
# prettier is pinned to the 3.x line on purpose: some mirrors resolve the
# `latest` dist-tag to a 4.0.0-alpha build, which formats differently.

if ! command -v npm >/dev/null 2>&1; then
  # npm.sh installs node through nvm, which only alters its own shell, so pull
  # nvm into this one before giving up.
  for nvm_dir in "$HOME/.nvm" "/usr/local/share/nvm"; do
    if [ -s "$nvm_dir/nvm.sh" ]; then
      export NVM_DIR="$nvm_dir"
      # shellcheck source=/dev/null
      . "$nvm_dir/nvm.sh"
      break
    fi
  done
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "nvim-tools.sh: npm not found; skipping nvim npm tooling" >&2
  exit 0
fi

packages=(
  "prettier@^3"
  "bash-language-server"
)

# Install into ~/.local so this works with a root-owned system npm (Mariner
# installs nodejs/npm via tdnf) as well as an nvm-managed one. ~/.local/bin is
# already on PATH -- nvim.sh installs there too.
for pkg in "${packages[@]}"; do
  if ! npm install -g --prefix "$HOME/.local" "$pkg"; then
    echo "nvim-tools.sh: failed to install $pkg" >&2
  fi
done

exit 0
