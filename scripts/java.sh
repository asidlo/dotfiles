#!/bin/bash

if ! command -v sdk &> /dev/null; then
  curl -s "https://get.sdkman.io" | bash
fi

source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk i java "$JAVA_VERSION"
