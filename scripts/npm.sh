#!/bin/bash

# Install nvm for npm and nodejs
curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

source /etc/os-release

if [ "$ID" == "ubuntu" ]; then
	# Removes decimal to use built in integer math instead of floats
	if (($(echo "$VERSION_ID" | sed 's/\.//g') <= 1804)); then
		nvm install 16.15.1
	else
		nvm install --lts
	fi
else
	nvm install --lts
fi
