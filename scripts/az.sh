#!/bin/bash

source /etc/os-release

if command -v az &>/dev/null; then
  exit 0
fi

# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=script
case "$ID" in
"mariner" | "azurelinux")
  sudo tdnf install -y ca-certificates
  sudo tdnf install -y azure-cli
  ;;
"ubuntu" | "debian")
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
