#!/bin/bash

# Get current script location
DOTFILES_DIR=$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-$0}")")")
DOTNET_VERSION="${DOTNET_VERSION:-8.0}"

mkdir -p ~/.omnisharp
ln -sfv "$DOTFILES_DIR/misc/omnisharp.json" ~/.omnisharp/omnisharp.json

source /etc/os-release

# Install dotnet
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#register-the-microsoft-package-repository
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-package-mixup?pivots=os-linux-ubuntu#i-need-a-version-of-net-that-isnt-provided-by-my-linux-distribution
case "$ID" in
"mariner")
	sudo tdnf install -y dotnet-sdk-"$DOTNET_VERSION"
	;;
"ubuntu" | "debian")
	# Download Microsoft signing key and repository
	wget https://packages.microsoft.com/config/$ID/$VERSION_ID/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

	# Install Microsoft signing key and repository
	sudo dpkg -i packages-microsoft-prod.deb

	# Clean up
	rm packages-microsoft-prod.deb

	# Update packages and install
	sudo apt update
	sudo apt-get install -y dotnet-sdk-"$DOTNET_VERSION"
	;;
*)
	echo "Unsupported OS: $ID"
	exit 1
	;;
esac
