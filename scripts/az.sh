#!/bin/bash

source /etc/os-release

# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=script
case "$ID" in
"mariner")
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
