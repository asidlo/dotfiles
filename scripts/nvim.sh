#!/bin/bash

INSTALL_DIR=/usr/local/bin

function print_help() {
	cat >&2 <<EOF
Usage: $0 [-d installDirectory]

Installs nvim and its prerequisites. It will install the nvim cli in the specified directory.

Current values:
- d: $INSTALL_DIR
EOF
}

while getopts "d:h" opt; do
	case "$opt" in
	d)
		INSTALL_DIR=$OPTARG
		;;
	h)
		print_help
		exit 0
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		print_help
		exit 1
		;;
	esac
done

install_bob() {
	# https://gist.github.com/gvenzl/1386755861fb42db492276d3864a378c
	latest_tag=$(curl -s https://api.github.com/repos/MordechaiHadad/bob/releases/latest | sed -Ene '/^ *"tag_name": *"(v.+)",$/s//\1/p')
	echo "Using version $latest_tag"

	curl -L -o /tmp/bob.zip "https://github.com/MordechaiHadad/bob/releases/download/$latest_tag/bob-linux-x86_64.zip"
	unzip /tmp/bob.zip -d /tmp/bob
	chmod +x /tmp/bob/bob-linux-x86_64/bob
	mv /tmp/bob/bob-linux-x86_64/bob "$INSTALL_DIR"
	rm -f /tmp/bob.zip && rm -rf /tmp/bob

	# Install nightly neovim
	mkdir -p ~/.local/share
	"$INSTALL_DIR/bob" use stable

	# Add current neovim version to PATH
	ln -svf ~/.local/share/bob/nvim-bin/nvim "$INSTALL_DIR/nvim"
}

install_nvim_appimage() {
	mkdir -p ~/.local/bin
	curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o ~/.local/nvim.appimage
	chmod +x ~/.local/nvim.appimage

	pushd ~/.local || return
	./nvim.appimage --appimage-extract

	if [ -d ~/.local/nvim ]; then
		rm -rf ~/.local/nvim
	fi

	mv -f ./squashfs-root ~/.local/nvim
	ln -svf ~/.local/nvim/AppRun "$INSTALL_DIR/nvim"
	rm ./nvim.appimage

	popd || return
}

# unameOut="$(uname -s)"
# case "$(uname -s)" in
# 		Linux*)     machine=Linux;;
# 		Darwin*)    machine=Mac;;
# 		CYGWIN*)    machine=Cygwin;;
# 		MINGW*)     machine=MinGw;;
# 		MSYS_NT*)   machine=Git;;
# 		*)          machine="UNKNOWN:${unameOut}"
# esac

source /etc/os-release

case "$ID" in
ubuntu)
	# Install nvim runtime prerequisites
	sudo apt-get update -y
	sudo apt-get install build-essential tmux wget curl zip unzip python3 python3-pip python3-venv -y
	if (($(echo "$VERSION_ID" | sed 's/\.//g') > 1804)); then
		install_bob
	else
		install_nvim_appimage
	fi
	;;
mariner)
	sudo tdnf update -y
	sudo tdnf install build-essential tmux wget curl zip unzip python3 python3-pip python3-venv -y
	install_bob
	;;
*)
	echo "Unsupported distribution: $ID"
	exit 1
	;;
esac

# /usr/bin/python3 -m pip install pynvim
