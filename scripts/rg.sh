#!/bin/bash

if [ -z "$RG_VERSION" ]; then
	RG_VERSION="$(curl -s -I https://github.com/BurntSushi/ripgrep/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}')"
fi

# Install ripgrep
# https://github.com/BurntSushi/ripgrep
case "$ID" in
"mariner")
	SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
	"$SCRIPT_DIR/rust.sh"
	cargo install ripgrep --version "$RG_VERSION"
	;;
"ubuntu" | "debian")
	# Latest version of rg deb (>14.0.0) includes a -1 at the end of the version for some reason.
	curl -L https://github.com/BurntSushi/ripgrep/releases/download/"$RG_VERSION"/ripgrep_"$RG_VERSION"-1_amd64.deb -o /tmp/ripgrep.deb
	sudo apt-get install /tmp/ripgrep.deb
	rm /tmp/ripgrep.deb
	;;
*)
	echo "Unsupported OS: $ID"
	exit 1
	;;
esac
