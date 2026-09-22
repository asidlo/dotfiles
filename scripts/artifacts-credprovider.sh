#!/bin/bash

# NOT part of install.sh -- kept as a manual escape hatch only.
#
# This installs Microsoft's artifacts-credprovider, which can do an interactive
# DeviceFlow sign-in. dotfiles installs the silent devcontainer-credprovider
# instead (scripts/devcontainer-credprovider.sh); running both together makes
# NuGet stall ~87s on a DeviceFlow prompt per restore whenever this provider's
# session-token cache is cold. Only run this by hand on a machine that has no
# Azure identity for DefaultAzureCredential to pick up, and expect the prompt.

set -e -o pipefail

nuget_netcore_dir="$HOME/.nuget/plugins/netcore"

# Tar updates existing directory metadata after extraction, so repair files left
# under the user's plugin tree by an earlier privileged install.
if [ "$(id -u)" -ne 0 ] && [ -d "$nuget_netcore_dir" ]; then
    foreign_owned_path=$(find "$nuget_netcore_dir" ! -uid "$(id -u)" -print -quit)
    if [ -n "$foreign_owned_path" ]; then
        echo "Repairing ownership under $nuget_netcore_dir..."
        sudo chown -R -P "$(id -u):$(id -g)" "$nuget_netcore_dir"
    fi
fi

wget -qO- https://aka.ms/install-artifacts-credprovider.sh | bash
