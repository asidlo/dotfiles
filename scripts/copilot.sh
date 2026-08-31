#!/bin/bash

set -o pipefail

if command -v copilot >/dev/null 2>&1; then
  echo "copilot is already installed."
else
  curl -fsSL https://gh.io/copilot-install | bash || exit 1
  command -v copilot >/dev/null 2>&1 || exit 1
fi

if copilot plugin list 2>&1 | grep -qi anvil; then
  echo "anvil plugin is already installed."
  exit 0
fi

# Keep the direct burkeholland/anvil install: anvil has no marketplace.json and
# is not published in github/copilot-plugins or github/awesome-copilot.
copilot plugin install burkeholland/anvil 2>&1 | grep -v 'Warning: Direct plugin installs (repos, URLs, local paths) are deprecated.'
plugin_status=${PIPESTATUS[0]}

if [ "$plugin_status" -ne 0 ]; then
  echo "Warning: could not install anvil plugin; continuing. You may need to log in to copilot first." >&2
fi
