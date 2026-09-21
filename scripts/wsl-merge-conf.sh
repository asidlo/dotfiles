#!/usr/bin/env bash
#
# Merge the repo's wsl.conf into /etc/wsl.conf, preserving any existing [user]
# section so this never clobbers the distro's default user.
#
# This lives in a real script file rather than an inline `bash -c` string on the
# PowerShell side on purpose: PowerShell here-strings carry CRLF line endings,
# and a stray \r turns `set -e` into `set: - : invalid option` and breaks every
# if/fi pair. .gitattributes pins *.sh to LF, so the bytes here are always sane.
#
# Runs as root (the caller uses `wsl.exe -u root`) so there is no sudo prompt to
# time out on during an unattended install.

set -euo pipefail

src="${1:-}"
dest="${2:-/etc/wsl.conf}"

if [ -z "$src" ]; then
  echo "usage: wsl-merge-conf.sh <source-wsl.conf> [dest]" >&2
  exit 2
fi
if [ ! -f "$src" ]; then
  echo "ERROR: source wsl.conf not found: $src" >&2
  exit 2
fi
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: wsl-merge-conf.sh must run as root (got uid $(id -u))" >&2
  exit 2
fi

# Normalise a section header line to a bare lowercase "[name]" for comparison.
# Inline comments are stripped first: a header written as `[user] # keep this`
# must still match, because failing to recognise it would drop the [user]
# section entirely and silently revert the distro's default user to root.
section_matcher='
  function header_name(line,   h) {
    h = line
    sub(/[#;].*$/, "", h)
    h = tolower(h)
    gsub(/[[:space:]]/, "", h)
    return h
  }
'

# Print $1 with the [$2] section removed.
strip_section() {
  awk -v want="$2" "$section_matcher"'
    BEGIN { skip = 0 }
    /^[[:space:]]*\[/ {
      skip = (header_name($0) == "[" want "]")
      if (skip) { next }
    }
    !skip { print }
  ' "$1"
}

# Print only the [$2] section of $1 (header included).
extract_section() {
  awk -v want="$2" "$section_matcher"'
    BEGIN { keep = 0 }
    /^[[:space:]]*\[/ {
      keep = (header_name($0) == "[" want "]")
    }
    keep { print }
  ' "$1"
}

mkdir -p "$(dirname "$dest")"

tmp="$(mktemp)"
src_lf="$(mktemp)"
dest_lf="$(mktemp)"
trap 'rm -f "$tmp" "$src_lf" "$dest_lf"' EXIT

# Normalise CRLF away before parsing. The repo copy is checked out on Windows,
# and WSL parses /etc/wsl.conf literally -- a trailing \r becomes part of the
# value, so `appendWindowsPath=false` silently stops matching. A lone \r also
# makes awk see a non-empty field, which would defeat the blank-line collapse
# below and break idempotence.
tr -d '\r' <"$src" >"$src_lf"

# Command substitution strips trailing newlines, which is exactly what we want:
# it keeps this idempotent instead of growing a blank line on every run.
existing_user=""
if [ -f "$dest" ]; then
  tr -d '\r' <"$dest" >"$dest_lf"
  existing_user="$(extract_section "$dest_lf" user)"
fi

strip_section "$src_lf" user >"$tmp"

if [ -n "$existing_user" ]; then
  printf '\n%s\n' "$existing_user" >>"$tmp"
fi

# Collapse runs of blank lines so repeated runs converge on identical bytes.
awk '
  NF == 0 { if (seen && blank++) { next } }
  NF      { blank = 0; seen = 1 }
  { print }
' "$tmp" >"$dest"

chmod 0644 "$dest"
echo "[wsl-conf] updated $dest"
