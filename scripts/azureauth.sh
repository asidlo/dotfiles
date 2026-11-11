#!/usr/bin/env bash
# Install the AzureAuth CLI.
#
# Agency authenticates through azureauth, and every MCP server it launches
# shells out to it for a token. Nothing else in this repo installs it -- on the
# appgw devcontainer it arrives baked into the image (/usr/lib/azureauth/,
# owned by no package), which is why its absence is easy to miss until a
# different machine has no sign-in at all.
#
# Agency can install it itself, but only sometimes, and that is the gap this
# closes. From the agency binary's own strings:
#
#     "WSL detected, installing azureauth..."
#     "Headless Linux detected, skipping azureauth and using Azure CLI"
#
# so on a plain Linux box or a container it does not install azureauth, it
# silently falls back to the Azure CLI backend. And when it does install, it
# runs `dpkg -i` first -- which does not exist on Azure Linux (rpm), leaving it
# on an `ar x` extraction fallback.
#
# The ordering matters more than the install: scripts/azureauth-signin-fix.sh
# wraps whatever binary exists AT THE TIME IT RUNS. If azureauth shows up later
# -- installed by Agency on first use -- it is never wrapped, and the sign-in
# hang that fix exists to prevent comes straight back. Installing it here, one
# step earlier, makes that ordering deterministic.
#
# Upstream ships a .deb and nothing else, so the rpm distros get the same
# payload unpacked by hand. That is exactly how the appgw image was built: the
# binary this extracts is byte-identical (72568 bytes) to the one in the image,
# with the same usr/bin/azureauth -> /usr/lib/azureauth/azureauth symlink.
#
# Version is pinned to Agency's DEFAULT_AZUREAUTH_VERSION, from
# ~/.config/agency/<ver>/source/content/client/auth_core/src/entra/azureauth.rs.
# A mismatch is not fatal -- Agency downloads its own copy if the version it
# wants is missing -- but matching keeps it from doing so.
#
# Override with AZUREAUTH_VERSION; skip entirely with DOTFILES_SKIP_AZUREAUTH=1.
#
# Best-effort: never fails the parent install.

set -u

MARKER="dotfiles-azureauth-signin-fix"
VERSION="${AZUREAUTH_VERSION:-0.9.5}"
LIBDIR="/usr/lib/azureauth"
REAL="$LIBDIR/azureauth"
LINK="/usr/bin/azureauth"

if [ "${DOTFILES_SKIP_AZUREAUTH:-0}" = "1" ]; then
  echo "azureauth: DOTFILES_SKIP_AZUREAUTH=1; skipping."
  exit 0
fi

if [ "$(uname -s)" != "Linux" ]; then
  echo "azureauth: not Linux; skipping (macOS/Windows install differently)."
  exit 0
fi

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  echo "azureauth: need root or sudo; skipping."
  exit 0
fi

# Is a real (non-wrapper) azureauth already here at the version we want?
#
# Deliberately probes the REAL binary rather than whatever $LINK resolves to:
# azureauth-signin-fix.sh may already have pointed $LINK at its wrapper, and
# reinstalling over that would clobber the wrapper and undo the fix.
installed_version() {
  local bin="$1"
  [ -x "$bin" ] || return 1
  grep -qs "$MARKER" "$bin" && return 1
  "$bin" --version 2>/dev/null | head -1 | tr -d '[:space:]'
}

current=$(installed_version "$REAL" || true)
if [ -z "$current" ] && [ -e "$LINK" ]; then
  # No packaged copy, but $LINK may point at a real binary somewhere else.
  resolved=$(readlink -f "$LINK" 2>/dev/null || true)
  if [ -n "$resolved" ] && [ "$resolved" != "$REAL" ]; then
    current=$(installed_version "$resolved" || true)
  fi
fi

# azureauth reports a 4-part version ("0.9.5.0") for a 3-part tag ("0.9.5").
case "$current" in
"$VERSION" | "$VERSION".*)
  echo "azureauth: $current already installed; nothing to do."
  exit 0
  ;;
esac

if [ -n "$current" ]; then
  echo "azureauth: found $current, want $VERSION; reinstalling."
fi

case "$(uname -m)" in
x86_64) ARCH="x64" ;;
aarch64 | arm64) ARCH="arm64" ;;
*)
  echo "azureauth: unsupported architecture $(uname -m); skipping." >&2
  exit 0
  ;;
esac

# Upstream publishes linux-x64/linux-arm64 .deb assets only; note the arch is
# "x64", not the "amd64" a .deb filename would normally use.
URL="https://github.com/AzureAD/microsoft-authentication-cli/releases/download/${VERSION}/azureauth-${VERSION}-linux-${ARCH}.deb"

tmpdir=$(mktemp -d) || exit 0
# shellcheck disable=SC2064  # expand tmpdir now, while it is still in scope
trap "rm -rf '$tmpdir'" EXIT

echo "azureauth: downloading $URL"
if ! curl -fsSL -o "$tmpdir/azureauth.deb" "$URL"; then
  echo "azureauth: download failed; skipping." >&2
  exit 0
fi

install_ok=0

if command -v dpkg >/dev/null 2>&1; then
  if $SUDO dpkg -i "$tmpdir/azureauth.deb" >/dev/null 2>&1; then
    install_ok=1
  else
    echo "azureauth: dpkg -i failed; falling back to manual extraction."
  fi
fi

# rpm distros (Azure Linux, Fedora, ...) have no dpkg. A .deb is just an ar
# archive holding data.tar.*, so unpack it by hand -- which is how the appgw
# devcontainer image got its copy.
if [ "$install_ok" -eq 0 ]; then
  if ! command -v ar >/dev/null 2>&1; then
    echo "azureauth: neither dpkg nor ar is available; skipping." >&2
    exit 0
  fi

  (cd "$tmpdir" && ar x azureauth.deb) || {
    echo "azureauth: could not unpack the .deb; skipping." >&2
    exit 0
  }

  data=$(ls "$tmpdir"/data.tar.* 2>/dev/null | head -1)
  if [ -z "$data" ]; then
    echo "azureauth: no data.tar.* inside the .deb; skipping." >&2
    exit 0
  fi

  # zstd-compressed payloads need a tar built with zstd support; check rather
  # than let tar fail with a confusing "unrecognized archive format".
  case "$data" in
  *.zst)
    if ! tar --help 2>/dev/null | grep -q zstd && ! command -v zstd >/dev/null 2>&1; then
      echo "azureauth: data.tar.zst needs zstd support in tar; skipping." >&2
      exit 0
    fi
    ;;
  esac

  if ! tar xf "$data" -C "$tmpdir"; then
    echo "azureauth: could not extract $data; skipping." >&2
    exit 0
  fi

  src="$tmpdir/usr/lib/azureauth"
  if [ ! -x "$src/azureauth" ]; then
    echo "azureauth: binary not found at usr/lib/azureauth in the .deb; skipping." >&2
    exit 0
  fi

  # Replace wholesale: the payload is a self-contained .NET app directory, and
  # leaving another version's .dll files behind it is how you get a runtime
  # that loads half of each.
  $SUDO rm -rf "$LIBDIR"
  $SUDO mkdir -p "$(dirname "$LIBDIR")"
  $SUDO cp -a "$src" "$LIBDIR" || {
    echo "azureauth: could not install to $LIBDIR; skipping." >&2
    exit 0
  }
  $SUDO chmod 0755 "$REAL"
  install_ok=1
fi

# Point /usr/bin/azureauth at it -- unless the sign-in wrapper already owns
# that path, in which case leave it alone: the wrapper re-resolves the real
# binary at runtime, so it picks this install up on its own, and overwriting
# the symlink here would silently disable the fix.
if [ -e "$LINK" ] && grep -qs "$MARKER" "$(readlink -f "$LINK" 2>/dev/null)" 2>/dev/null; then
  echo "azureauth: leaving $LINK pointing at the sign-in wrapper."
else
  $SUDO ln -sfn "$REAL" "$LINK"
fi

final=$("$REAL" --version 2>/dev/null | head -1 || true)
if [ -z "$final" ]; then
  echo "azureauth: installed but $REAL does not run." >&2
  exit 0
fi

echo "azureauth: installed $final -> $REAL"
exit 0
