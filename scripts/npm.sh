#!/bin/bash

# Install nvm for npm and nodejs
curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Removes decimal to use built in integer math instead of floats
if (($(echo "$UBUNTU_VERSION" | sed 's/\.//g') > 1804)); then
	nvm install --lts
else
	nvm install 16.15.1
fi
