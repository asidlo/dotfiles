#!/bin/bash

is_wsl() {
	if [ -n "$WSL_DISTRO_NAME" ]; then
		return 0
	fi
	if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
		return 0
	fi
	if grep -qiE "(microsoft|wsl)" /proc/sys/kernel/osrelease 2>/dev/null; then
		return 0
	fi
	return 1
}

install_wslview() {
	if command -v wslview >/dev/null 2>&1; then
		echo "wslview is already installed."
		return 0
	fi

	if [ ! -r /etc/os-release ]; then
		echo "Cannot determine distro: /etc/os-release not found." >&2
		return 1
	fi

	# shellcheck disable=SC1091
	. /etc/os-release

	echo "Installing wslu (provides wslview)..."
	case "$ID" in
	ubuntu | debian | linuxmint | pop)
		sudo apt-get update && sudo apt-get install -y wslu
		;;
	fedora | rhel | centos)
		sudo dnf install -y wslu
		;;
	opensuse* | sles)
		sudo zypper install -y wslu
		;;
	arch | manjaro | endeavouros)
		sudo pacman -S --noconfirm wslu
		;;
	alpine)
		sudo apk add wslu
		;;
	*)
		echo "Unsupported distro '$ID'; please install wslu manually." >&2
		return 1
		;;
	esac
}

if is_wsl; then
	install_wslview
fi

# Do NOT `exec $SHELL` here: install.sh runs this as a child step, and exec-ing
# an interactive login shell would take over the terminal and block install.sh
# before it links the dotfiles. Restart your shell after install.sh completes.
curl -sSfL https://aka.ms/InstallTool.sh | sh -s agency