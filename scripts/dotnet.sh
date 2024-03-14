#!/bin/bash

mkdir -p ~/.omnisharp
ln -sfv "$DOTFILES_DIR/misc/omnisharp.json" ~/.omnisharp/omnisharp.json

# Install dotnet
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu#register-the-microsoft-package-repository
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-package-mixup?pivots=os-linux-ubuntu#i-need-a-version-of-net-that-isnt-provided-by-my-linux-distribution
source /etc/os-release
case $ID in
debian | ubuntu)
	wget https://packages.microsoft.com/config/ubuntu/"$UBUNTU_VERSION"/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
	sudo dpkg -i packages-microsoft-prod.deb
	rm packages-microsoft-prod.deb
	sudo apt-get update
	sudo apt-get install -y apt-transport-https &&
		sudo apt-get update &&
		sudo apt-get install -y dotnet-sdk-"$DOTNET_VERSION"
	;;
mariner)
	sudo tdnf install -y dotnet-sdk-"$DOTNET_VERSION"
	;;
esac
