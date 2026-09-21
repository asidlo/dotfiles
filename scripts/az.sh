#!/bin/bash

source /etc/os-release

if command -v az &>/dev/null; then
  exit 0
fi

# True only when packages.microsoft.com actually ships an azure-cli package for
# this apt suite.
#
# It publishes an empty placeholder suite for brand-new Ubuntu releases: 26.04
# (resolute) has a valid, signed InRelease but a zero-byte Packages index.
# Microsoft's installer only checks that the codename is listed under dists/, so
# it happily configures that empty repo and apt then dies with "E: Unable to
# locate package azure-cli". Probe for a real package before committing to it.
azure_cli_suite_has_package() {
  local suite="$1"
  local arch

  [ -n "$suite" ] || return 1
  arch=$(dpkg --print-architecture 2>/dev/null) || arch="amd64"

  curl -fsSL --max-time 30 \
    "https://packages.microsoft.com/repos/azure-cli/dists/$suite/main/binary-$arch/Packages" 2>/dev/null |
    grep -q '^Package: azure-cli$'
}

# First suite that carries the package wins: this release, then the Ubuntu base
# it derives from, then the newest suites Microsoft actually builds for.
pick_azure_cli_suite() {
  local suite
  local seen=""
  local candidates=("$VERSION_CODENAME" "$UBUNTU_CODENAME")

  if [ "$ID" = "debian" ]; then
    candidates+=("bookworm" "bullseye")
  else
    candidates+=("noble" "jammy")
  fi

  for suite in "${candidates[@]}"; do
    case " $seen " in
    *" $suite "*) continue ;;
    esac
    seen="$seen $suite"

    if azure_cli_suite_has_package "$suite"; then
      printf '%s\n' "$suite"
      return 0
    fi
  done

  return 1
}

# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=script
case "$ID" in
"mariner" | "azurelinux")
  sudo tdnf install -y ca-certificates
  sudo tdnf install -y azure-cli
  ;;
"ubuntu" | "debian")
  if suite=$(pick_azure_cli_suite); then
    echo "azure-cli: installing from packages.microsoft.com suite '$suite'"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo DIST_CODE="$suite" bash
  else
    # Every probe came back empty, which points at the network rather than the
    # repo. Let Microsoft's own detection have a go instead of failing here.
    echo "azure-cli: no suite could be confirmed; falling back to installer detection" >&2
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  fi
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac

if ! command -v az >/dev/null 2>&1; then
  echo "azure-cli: install reported success but 'az' is not on PATH" >&2
  exit 1
fi
