#!/bin/bash

# The sourced path and command mocks are intentionally dynamic in this test.
# shellcheck disable=SC1090,SC2317

set -e -o pipefail

ROOT_DIR=$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")
SCRIPT="$ROOT_DIR/scripts/ensure-sudo.sh"
TEST_DIR=$(mktemp -d)
EMPTY_PATH="$TEST_DIR/bin"
mkdir -p "$EMPTY_PATH"
trap 'rm -rf "$TEST_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_log() {
  local expected="$1"
  local log="$2"
  local actual
  actual=$(<"$log")
  [ "$actual" = "$expected" ] || fail "expected '$expected', got '$actual'"
}

write_os_release() {
  local id="$1"
  local path="$TEST_DIR/os-release-$id"
  printf 'ID=%s\nPRETTY_NAME="Test %s"\n' "$id" "$id" >"$path"
  printf '%s\n' "$path"
}

test_existing_sudo_is_unchanged() (
  PATH="$EMPTY_PATH"
  source "$SCRIPT"
  sudo() { :; }
  id() { printf '1000\n'; }

  ensure_sudo
)

test_ubuntu_uses_apt() (
  local log="$TEST_DIR/ubuntu.log"
  local os_release
  os_release=$(write_os_release ubuntu)
  PATH="$EMPTY_PATH"
  source "$SCRIPT"
  id() { printf '0\n'; }
  apt-get() {
    printf '%s\n' "$*" >>"$log"
    if [ "$*" = "install -y sudo" ]; then
      sudo() { :; }
    fi
  }

  OS_RELEASE_FILE="$os_release" ensure_sudo
  assert_log $'update\ninstall -y sudo' "$log"
)

test_azure_linux_uses_tdnf() (
  local log="$TEST_DIR/azurelinux.log"
  local os_release
  os_release=$(write_os_release azurelinux)
  PATH="$EMPTY_PATH"
  source "$SCRIPT"
  id() { printf '0\n'; }
  tdnf() {
    printf '%s\n' "$*" >>"$log"
    sudo() { :; }
  }

  OS_RELEASE_FILE="$os_release" ensure_sudo
  assert_log 'install -y sudo' "$log"
)

test_mariner_falls_back_to_dnf() (
  local log="$TEST_DIR/mariner.log"
  local os_release
  os_release=$(write_os_release mariner)
  PATH="$EMPTY_PATH"
  source "$SCRIPT"
  id() { printf '0\n'; }
  dnf() {
    printf '%s\n' "$*" >>"$log"
    sudo() { :; }
  }

  OS_RELEASE_FILE="$os_release" ensure_sudo
  assert_log 'install -y sudo' "$log"
)

test_non_root_fails_clearly() (
  local output
  PATH="$EMPTY_PATH"
  source "$SCRIPT"
  id() { printf '1000\n'; }

  if output=$(ensure_sudo 2>&1); then
    fail "missing sudo unexpectedly succeeded for a non-root user"
  fi
  [[ "$output" == *"root privileges are required"* ]] ||
    fail "non-root failure did not explain the privilege requirement"
)

test_install_must_expose_sudo() (
  local output
  local os_release
  os_release=$(write_os_release ubuntu)
  PATH="$EMPTY_PATH"
  source "$SCRIPT"
  id() { printf '0\n'; }
  apt-get() { :; }

  if output=$(OS_RELEASE_FILE="$os_release" ensure_sudo 2>&1); then
    fail "package-manager success without sudo unexpectedly passed"
  fi
  [[ "$output" == *"sudo is still unavailable"* ]] ||
    fail "missing installed binary was not reported"
)

test_existing_sudo_is_unchanged
test_ubuntu_uses_apt
test_azure_linux_uses_tdnf
test_mariner_falls_back_to_dnf
test_non_root_fails_clearly
test_install_must_expose_sudo

echo "ensure-sudo tests passed"
