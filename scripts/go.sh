#!/bin/bash

GO_VERSION=$(curl https://go.dev/VERSION?m=text | head -n1)
DOWNLOAD_URL="https://dl.google.com/go/$GO_VERSION.linux-amd64.tar.gz"

if command -v go &> /dev/null; then
  # Check if current versio n is the same as latest
  if [[ $(go version) == *"$GO_VERSION"* ]]; then
    exit 0
  fi
fi

curl -L "$DOWNLOAD_URL" -o /tmp/go.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
