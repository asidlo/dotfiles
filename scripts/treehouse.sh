#!/bin/bash
# Pool of reusable git worktrees for agents: https://github.com/kunchenguid/treehouse
command -v treehouse >/dev/null 2>&1 && exit 0
set -e -o pipefail

# Fail before downloading anything if a dependency is missing. The installer
# needs curl/tar/gzip/mktemp/uname/tr/grep, and treehouse itself drives git.
missing=()
for dep in curl tar gzip mktemp uname tr grep sh git; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "ERROR: treehouse needs these missing commands: ${missing[*]}" >&2
  echo "       Install them (scripts/dependencies.sh covers curl) and re-run." >&2
  exit 1
fi

mkdir -p ~/.local/bin

# The installer targets ~/.local/bin only if it is already on PATH, otherwise it
# falls back to `sudo mv` into /usr/local/bin. Put it on PATH so it always lands
# next to the rest of our user-local tools.
curl -fsSL https://kunchenguid.github.io/treehouse/install.sh |
  PATH="$HOME/.local/bin:$PATH" sh

"$HOME/.local/bin/treehouse" --version
