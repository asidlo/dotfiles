#!/bin/bash

set -o pipefail

# ---------------------------------------------------------------------------
# `command -v copilot` is not enough to decide the CLI is installed.
#
# VS Code's Copilot Chat extension puts its own `copilot` on $PATH in every
# integrated terminal:
#
#   ~/.vscode-server/data/User/globalStorage/github.copilot-chat/copilotCli/copilot
#
# That file is a shim around the real CLI, and when the real CLI is missing it
# asks -- on stdin -- "Install GitHub Copilot CLI? ['y/N']" and waits. Run from
# install.sh the question is piped into tee, so the install merely looked hung
# until someone pressed Enter; and because this script had already announced
# "copilot is already installed", neither the CLI nor the anvil plugin was ever
# installed afterwards.
#
# So: look past the shim when deciding, and give every copilot invocation an
# empty stdin so a prompt can only fail fast, never block an unattended run.
# The shim stays fine for interactive use -- with the real CLI present it just
# forwards to it.
# ---------------------------------------------------------------------------

is_vscode_shim() {
  case "$1" in
  */github.copilot-chat/copilotCli/copilot) return 0 ;;
  *) return 1 ;;
  esac
}

# Walk $PATH by hand: `command -v` reports only the first match, which inside a
# VS Code terminal is the shim, hiding any real CLI behind it. $HOME/.local/bin
# and /usr/local/bin are appended because they are where the official installer
# puts the binary ($PREFIX/bin; $PREFIX defaults to $HOME/.local for non-root,
# /usr/local for root) -- a just-installed CLI is found even if this shell's
# PATH predates it.
find_copilot() {
  local dir candidate

  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    candidate="$dir/copilot"
    if [ -x "$candidate" ] && ! is_vscode_shim "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(printf '%s\n' "${PATH//:/$'\n'}" "$HOME/.local/bin" /usr/local/bin)

  return 1
}

copilot_bin=$(find_copilot) || copilot_bin=""

if [ -n "$copilot_bin" ]; then
  echo "copilot is already installed ($copilot_bin)."
else
  # Download, then run -- not `curl | bash`. Piping hands the *script* to the
  # shell on stdin, so there is no stdin left to close and any prompt the
  # installer makes would hang the run exactly like the shim did.
  installer=$(mktemp) || exit 1
  trap 'rm -f "$installer"' EXIT

  if ! curl -fsSL https://gh.io/copilot-install -o "$installer"; then
    echo "Failed to download the GitHub Copilot CLI installer." >&2
    exit 1
  fi

  bash "$installer" </dev/null || exit 1

  copilot_bin=$(find_copilot) || {
    echo "GitHub Copilot CLI installer finished, but no copilot binary was found." >&2
    exit 1
  }
fi

if "$copilot_bin" plugin list </dev/null 2>&1 | grep -qi anvil; then
  echo "anvil plugin is already installed."
  exit 0
fi

# Keep the direct burkeholland/anvil install: anvil has no marketplace.json and
# is not published in github/copilot-plugins or github/awesome-copilot.
"$copilot_bin" plugin install burkeholland/anvil </dev/null 2>&1 | grep -v 'Warning: Direct plugin installs (repos, URLs, local paths) are deprecated.'
plugin_status=${PIPESTATUS[0]}

if [ "$plugin_status" -ne 0 ]; then
  echo "Warning: could not install anvil plugin; continuing. You may need to log in to copilot first." >&2
fi
