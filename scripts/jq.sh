#!/bin/bash

# Detect OS
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

case "$OS_ID" in
mariner | azurelinux)
  echo "Detected $OS_ID. Installing jq via tdnf..."
  sudo tdnf install -y jq
  ;;
ubuntu)
  echo "Detected Ubuntu. Installing jq via apt..."
  sudo apt-get update
  sudo apt-get install -y jq
  ;;
*)
  echo "Unsupported OS: $OS_ID. Please install jq manually."
  ;;
esac
