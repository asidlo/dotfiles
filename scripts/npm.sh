#!/bin/bash

if command -v nvm >/dev/null 2>&1; then
  exit 0
fi

# Install nvm for npm and nodejs
curl -o- https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash

if [ -s "$HOME/.nvm/nvm.sh" ]; then
	export NVM_DIR="$HOME/.nvm"
elif [ -s "/usr/local/share/nvm/nvm.sh" ]; then
	export NVM_DIR="/usr/local/share/nvm"
else
	echo "nvm not found in either $HOME/.nvm or /usr/local/share/nvm"
	exit 1
fi

. "$NVM_DIR/nvm.sh"

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
