#!/bin/bash
#
# Install the UPSTREAM gh release binary from GitHub, in preference to the
# distro package.
#
# Why not the distro package: Azure Linux builds gh with Microsoft's Go
# toolchain and system crypto --
#
#   $ go version -m /usr/bin/gh
#   build   microsoft_systemcrypto=1
#   build   microsoft_toolset_version=go1.27.1-2-microsoft
#
# so TLS goes through the system OpenSSL instead of Go's own crypto. Recent Go
# offers the hybrid post-quantum key exchange X25519MLKEM768 on every TLS
# connection by default, and ML-KEM needs OpenSSL >= 3.5. Azure Linux 3.0 ships
# 3.3.7 (newest in the repo is 3.3.7-6), so key generation fails before the
# handshake completes and EVERY gh network call dies:
#
#   $ gh api /zen
#   Get "https://api.github.com/zen": EVP_PKEY_Q_keygen_MLKEM
#   openssl error(s):
#   ...error:03080106:digital envelope routines:EVP_PKEY_Q_keygen:passed
#   invalid argument:crypto/evp/evp_lib.c:1229:
#
# `gh auth login` is just the most visible casualty. The usual workaround is
# GODEBUG=tlsmlkem=0, but that is an env var every shell and every tool launch
# has to remember, and it is silently load-bearing once set. The upstream
# release binary is built with stock Go, uses Go's built-in crypto, does not
# dlopen OpenSSL at all, and so is simply not exposed to this.
#
# Installed to /usr/local/bin, which precedes /usr/bin in PATH, so the distro
# package is shadowed rather than removed -- tdnf/apt stay consistent and an
# `sudo rm /usr/local/bin/gh` is a complete undo.
#
# Override the version with GH_VERSION=2.102.0; set GH_USE_DISTRO=1 to opt out
# and take the package manager's build instead.

trap 'echo "Error on line $LINENO in $0: Command \"$BASH_COMMAND\" failed"; exit 1' ERR

PREFIX="/usr/local"
BIN="$PREFIX/bin/gh"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""
fi

install_from_distro() {
  source /etc/os-release

  case $ID in
  debian | ubuntu)
    type -p curl >/dev/null || ($SUDO apt update && $SUDO apt install curl -y)
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
      $SUDO chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
      $SUDO apt update &&
      $SUDO apt install gh -y
    ;;
  mariner | azurelinux)
    $SUDO tdnf install gh -y
    ;;
  centos | fedora | rhel)
    $SUDO dnf install -y 'dnf-command(config-manager)'
    $SUDO dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    $SUDO dnf install -y gh
    ;;
  *)
    echo "gh: unsupported distro '$ID' and no upstream binary available" >&2
    return 1
    ;;
  esac
}

if [ "${GH_USE_DISTRO:-0}" = "1" ]; then
  echo "gh: GH_USE_DISTRO=1; using the package manager build."
  install_from_distro
  exit $?
fi

if [ "$(uname -s)" != "Linux" ]; then
  echo "gh: upstream tarball path is Linux-only; falling back to the package manager."
  install_from_distro
  exit $?
fi

case "$(uname -m)" in
x86_64) GH_ARCH="amd64" ;;
aarch64 | arm64) GH_ARCH="arm64" ;;
*)
  echo "gh: unsupported architecture $(uname -m); falling back to the package manager." >&2
  install_from_distro
  exit $?
  ;;
esac

# Resolve the latest tag by following the /releases/latest redirect rather than
# calling api.github.com: the API rate-limits unauthenticated callers, and this
# script is what makes `gh auth login` work in the first place, so it cannot
# assume a usable token exists yet.
VERSION="${GH_VERSION:-}"
if [ -z "$VERSION" ]; then
  latest_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    https://github.com/cli/cli/releases/latest 2>/dev/null || true)
  VERSION="${latest_url##*/tag/v}"
  if [ -z "$VERSION" ] || [ "$VERSION" = "$latest_url" ]; then
    echo "gh: could not resolve the latest release; falling back to the package manager." >&2
    install_from_distro
    exit $?
  fi
fi
VERSION="${VERSION#v}"

if [ -x "$BIN" ] && "$BIN" --version 2>/dev/null | head -1 | grep -qF "gh version $VERSION"; then
  echo "gh: $BIN is already $VERSION"
  exit 0
fi

tarball="gh_${VERSION}_linux_${GH_ARCH}.tar.gz"
url="https://github.com/cli/cli/releases/download/v${VERSION}/${tarball}"
tmpdir=$(mktemp -d)
# shellcheck disable=SC2064  # expand tmpdir now, while it is still in scope
trap "rm -rf '$tmpdir'" EXIT

echo "gh: downloading $url"
if ! curl -fsSL -o "$tmpdir/$tarball" "$url"; then
  echo "gh: download failed; falling back to the package manager." >&2
  install_from_distro
  exit $?
fi

tar -xzf "$tmpdir/$tarball" -C "$tmpdir"
src="$tmpdir/gh_${VERSION}_linux_${GH_ARCH}"

if [ ! -x "$src/bin/gh" ]; then
  echo "gh: tarball did not contain bin/gh; falling back to the package manager." >&2
  install_from_distro
  exit $?
fi

$SUDO install -Dm755 "$src/bin/gh" "$BIN"

# Man pages and completions are part of the tarball; take them too so `man gh`
# matches the binary actually on PATH rather than the distro package's version.
if [ -d "$src/share/man/man1" ]; then
  $SUDO mkdir -p "$PREFIX/share/man/man1"
  $SUDO cp -f "$src"/share/man/man1/*.1 "$PREFIX/share/man/man1/" 2>/dev/null || true
fi

installed=$("$BIN" --version 2>/dev/null | head -1 || true)
if [ -z "$installed" ]; then
  echo "gh: $BIN failed to run after install" >&2
  exit 1
fi
echo "gh: installed $installed -> $BIN"

# The whole point of this script: prove the binary does TLS without OpenSSL's
# ML-KEM. Explicitly drop any GODEBUG=tlsmlkem=0 the caller may have exported,
# so a workaround already in the environment cannot make a still-broken build
# look healthy. Network-dependent, so it reports but never fails the install.
if env -u GODEBUG "$BIN" api /zen >/dev/null 2>&1; then
  echo "gh: verified TLS works without GODEBUG=tlsmlkem=0"
else
  echo "gh: note - could not verify an API call (offline, or no credentials yet)."
fi

if command -v tdnf >/dev/null 2>&1 && [ -x /usr/bin/gh ]; then
  echo "gh: note - the distro package at /usr/bin/gh is shadowed by $BIN."
fi
