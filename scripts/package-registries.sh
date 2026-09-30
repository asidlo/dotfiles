#!/usr/bin/env bash
# Point npm and pip at the Central Feed Services (CFS) proxy.
#
# Microsoft-managed and SAW devices block direct access to the public package
# registries -- registry.npmjs.org, and pypi.org/simple + files.pythonhosted.org.
# Packages have to come through the CFS-protected upstream feed instead.
#
# Measured here, not assumed: `npx --registry https://registry.npmjs.org ...`
# ran for 75s and then died with
#   npm error code ERR_SSL_SSL/TLS_ALERT_HANDSHAKE_FAILURE
#   ssl3_read_bytes:ssl/tls alert handshake failure ... SSL alert number 40
# The TLS handshake is refused outright, so it is not a timeout you can wait
# out or retry past.
#
# What breaks without this, in practice:
#   - Any npx-launched MCP server (the handshake stall alone blows Copilot
#     CLI's 60s MCP negotiation budget, so the server is killed before it
#     ever starts).
#   - `pre-commit install --install-hooks`: its `language: node` hooks
#     (markdownlint-cli2) npm-install, and its `language: python` hooks
#     (pre-commit-hooks, codespell) pip-install, both from the blocked public
#     registries -- which aborts devcontainer creation.
#   - `pipx install pre-commit` itself, which downloads from PyPI.
#
# These are written to the USER-level config rather than a repo-level one on
# purpose: pre-commit, pipx and npx all run from their own cache directories,
# not the repo root, so a project-local .npmrc would never be consulted. The
# user-level files also cover the isolated virtualenvs pipx and pre-commit
# create for their own pip calls.
#
# Both files are merged, never overwritten. ~/.npmrc in particular routinely
# holds Azure Artifacts credentials (//pkgs.dev.azure.com/...:_authToken=...),
# and clobbering it would silently break every authenticated feed on the box.
# Only the registry / index-url key is touched.
#
# Escape hatches, for a network that can still reach the public registries
# directly (a personal machine, say):
#   DOTFILES_SKIP_FEED_PROXY=1   skip this entirely
#   NPM_REGISTRY=...             use a different npm registry
#   PIP_INDEX_URL=...            use a different Python index (pip reads this
#                                variable natively too)
#
# Best-effort: never fails the parent install.

set -u

if [ "${DOTFILES_SKIP_FEED_PROXY:-0}" = "1" ]; then
  echo "package-registries: DOTFILES_SKIP_FEED_PROXY=1; leaving registries alone."
  exit 0
fi

NPM_REGISTRY="${NPM_REGISTRY:-https://packagefeedproxy.microsoft.io/npm/}"
PIP_INDEX_URL="${PIP_INDEX_URL:-https://packagefeedproxy.microsoft.io/pypi/simple/}"

# --- npm --------------------------------------------------------------------
# Edited as a file rather than via `npm config set` so it works before npm.sh
# has installed node -- a later npm picks the setting up regardless. Writing in
# place with `cat >` keeps the existing inode and mode, which matters when the
# file is 0600 because it holds feed tokens.
npmrc="$HOME/.npmrc"
if [ ! -e "$npmrc" ]; then
  if (umask 077 && : >"$npmrc") 2>/dev/null; then
    :
  else
    echo "package-registries: cannot create $npmrc; skipping npm." >&2
    npmrc=""
  fi
fi

if [ -n "$npmrc" ] && [ -w "$npmrc" ]; then
  current=$(sed -nE 's#^[[:space:]]*registry[[:space:]]*=[[:space:]]*(.*)$#\1#p' \
    "$npmrc" | tail -1)
  if [ "$current" = "$NPM_REGISTRY" ]; then
    echo "package-registries: npm registry already $NPM_REGISTRY"
  else
    tmp=$(mktemp) || tmp=""
    if [ -n "$tmp" ]; then
      if grep -qE '^[[:space:]]*registry[[:space:]]*=' "$npmrc"; then
        sed -E "s#^[[:space:]]*registry[[:space:]]*=.*#registry=$NPM_REGISTRY#" \
          "$npmrc" >"$tmp"
      else
        cat "$npmrc" >"$tmp"
        printf 'registry=%s\n' "$NPM_REGISTRY" >>"$tmp"
      fi
      cat "$tmp" >"$npmrc" && echo "package-registries: npm registry -> $NPM_REGISTRY"
      rm -f "$tmp"
    fi
  fi
elif [ -n "$npmrc" ]; then
  echo "package-registries: $npmrc is not writable; skipping npm." >&2
fi

# --- pip --------------------------------------------------------------------
# configparser rather than `pip config set` for the same reason: it works with
# no pip installed yet, and it preserves any other settings already in the file.
if ! command -v python3 >/dev/null 2>&1; then
  echo "package-registries: python3 not found; skipping pip."
  exit 0
fi

if [ "$(uname -s)" = "Darwin" ]; then
  pipconf="$HOME/Library/Application Support/pip/pip.conf"
else
  pipconf="${XDG_CONFIG_HOME:-$HOME/.config}/pip/pip.conf"
fi

PIPCONF="$pipconf" INDEX_URL="$PIP_INDEX_URL" python3 - <<'PY' || true
import configparser
import os
import sys

path = os.environ["PIPCONF"]
url = os.environ["INDEX_URL"]

cp = configparser.ConfigParser()
try:
    cp.read(path)
except configparser.Error as exc:
    print("package-registries: %s is unparseable (%s); leaving it alone."
          % (path, exc), file=sys.stderr)
    raise SystemExit(0)

if cp.has_option("global", "index-url") and \
        cp.get("global", "index-url").strip() == url:
    print("package-registries: pip index-url already %s" % url)
    raise SystemExit(0)

if not cp.has_section("global"):
    cp.add_section("global")
cp.set("global", "index-url", url)

try:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        cp.write(fh)
except OSError as exc:
    print("package-registries: cannot write %s (%s); skipping pip."
          % (path, exc), file=sys.stderr)
    raise SystemExit(0)

print("package-registries: pip index-url -> %s" % url)
PY

exit 0
