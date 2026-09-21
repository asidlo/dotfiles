#!/bin/bash

set -e -o pipefail

ensure_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    return 0
  fi

  if [ "$(id -u)" -ne 0 ]; then
    echo "sudo is not installed and root privileges are required to install it." >&2
    echo "Run scripts/ensure-sudo.sh as root once, then rerun install.sh as your normal user." >&2
    return 1
  fi

  local os_release_file="${OS_RELEASE_FILE:-/etc/os-release}"
  if [ ! -r "$os_release_file" ]; then
    echo "Cannot install sudo: $os_release_file is not readable." >&2
    return 1
  fi

  # shellcheck disable=SC1090
  source "$os_release_file"

  echo "sudo not found; installing it for ${PRETTY_NAME:-${ID:-unknown}}..."
  case "${ID:-}" in
  ubuntu | debian)
    if ! command -v apt-get >/dev/null 2>&1; then
      echo "Cannot install sudo: apt-get was not found." >&2
      return 1
    fi
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y sudo
    ;;
  mariner | azurelinux)
    if command -v tdnf >/dev/null 2>&1; then
      tdnf install -y sudo
    elif command -v dnf >/dev/null 2>&1; then
      dnf install -y sudo
    else
      echo "Cannot install sudo: neither tdnf nor dnf was found." >&2
      return 1
    fi
    ;;
  *)
    echo "Cannot install sudo automatically on distribution: ${ID:-unknown}." >&2
    return 1
    ;;
  esac

  if ! command -v sudo >/dev/null 2>&1; then
    echo "The package manager completed, but sudo is still unavailable." >&2
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ensure_sudo
fi
