#!/bin/bash

if [ -z "$FD_VERSION" ]; then
	FD_VERSION="$(curl -s -I https://github.com/sharkdp/fd/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/^v//')"
fi

source /etc/os-release

case "$ID" in
"mariner")
	SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
	"$SCRIPT_DIR/rust.sh"
	cargo install fd-find --version "$FD_VERSION"
	;;
"ubuntu" | "debian")
	curl -L https://github.com/sharkdp/fd/releases/download/v"$FD_VERSION"/fd_"$FD_VERSION"_amd64.deb -o /tmp/fd.deb
	sudo apt-get install /tmp/fd.deb
	rm /tmp/fd.deb
	;;
*)
	echo "Unsupported OS: $ID"
	exit 1
	;;
esac
