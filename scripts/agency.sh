#!/bin/bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

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

install_wslview_from_upstream_apt() {
	local codename

	codename="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
	if [ -z "$codename" ]; then
		echo "Cannot determine distro codename for upstream wslu apt repo." >&2
		return 1
	fi

	echo "Trying upstream wslu apt repository for $codename..."
	sudo apt-get install -y gnupg2 apt-transport-https wget ca-certificates || return 1
	sudo mkdir -p /etc/apt/keyrings
	wget -O - https://pkg.wslutiliti.es/public.key | sudo gpg --batch --yes -o /etc/apt/keyrings/wslu-archive-keyring.gpg --dearmor || return 1
	echo "deb [signed-by=/etc/apt/keyrings/wslu-archive-keyring.gpg] https://pkg.wslutiliti.es/debian $codename main" | sudo tee /etc/apt/sources.list.d/wslu.list >/dev/null

	if sudo apt-get update && sudo apt-get install -y wslu; then
		return 0
	fi

	sudo rm -f /etc/apt/sources.list.d/wslu.list
	sudo apt-get update || true
	return 1
}

install_wslview_from_github_release() {
	local cache_dir
	local deb_url
	local deb_file

	echo "Trying wslu .deb from GitHub releases..."
	cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/wslu"
	mkdir -p "$cache_dir"

	deb_url=$(curl -fsSL https://api.github.com/repos/wslutilities/wslu/releases?per_page=30 |
		grep -E '"browser_download_url": ".*\.deb"' |
		head -n 1 |
		sed -E 's/.*"([^"]+)".*/\1/')

	if [ -z "$deb_url" ]; then
		echo "No .deb asset found in recent wslutilities/wslu GitHub releases." >&2
		return 1
	fi

	deb_file="$cache_dir/$(basename "$deb_url")"
	curl -fsSL -o "$deb_file" "$deb_url" || return 1
	sudo dpkg -i "$deb_file" || sudo apt-get -f install -y
	command -v wslview >/dev/null 2>&1
}

install_wslview() {
	if command -v wslview >/dev/null 2>&1; then
		echo "wslview is already installed."
		return 0
	fi

	if [ ! -r /etc/os-release ]; then
		echo "Cannot determine distro: /etc/os-release not found." >&2
		echo "Could not install wslu/wslview; continuing without it." >&2
		return 0
	fi

	# shellcheck disable=SC1091
	. /etc/os-release

	echo "Installing wslu (provides wslview)..."
	case "$ID" in
	ubuntu | debian | linuxmint | pop)
		if sudo apt-get update && sudo apt-get install -y wslu; then
			return 0
		fi
		if install_wslview_from_upstream_apt; then
			return 0
		fi
		if install_wslview_from_github_release; then
			return 0
		fi
		;;
	fedora | rhel | centos)
		sudo dnf install -y wslu && return 0
		;;
	opensuse* | sles)
		sudo zypper install -y wslu && return 0
		;;
	arch | manjaro | endeavouros)
		sudo pacman -S --noconfirm wslu && return 0
		;;
	alpine)
		sudo apk add wslu && return 0
		;;
	*)
		echo "Unsupported distro '$ID'; please install wslu manually if you need wslview." >&2
		return 0
		;;
	esac

	# wslview is a nicety; this repo's bin/open shim already provides `open`.
	echo "Could not install wslu/wslview; continuing without it." >&2
	return 0
}

ensure_libicu() {
	local icu_package

	if ldconfig -p 2>/dev/null | grep -q libicuuc; then
		return 0
	fi

	if [ ! -r /etc/os-release ]; then
		echo "Cannot determine distro: /etc/os-release not found." >&2
		export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
		return 0
	fi

	# shellcheck disable=SC1091
	. /etc/os-release

	# The agency bootstrap runs a self-contained .NET binary that needs ICU.
	echo "Installing ICU runtime for the agency installer..."
	case "$ID" in
	ubuntu | debian | linuxmint | pop)
		sudo apt-get update
		if ! sudo apt-get install -y libicu-dev; then
			icu_package=$(apt-cache search --names-only '^libicu[0-9]+$' | sort -V | tail -n 1 | cut -d' ' -f1)
			if [ -n "$icu_package" ]; then
				sudo apt-get install -y "$icu_package" || true
			fi
		fi
		;;
	fedora | rhel | centos)
		sudo dnf install -y libicu || true
		;;
	opensuse* | sles)
		sudo zypper install -y libicu || true
		;;
	arch | manjaro | endeavouros)
		sudo pacman -S --noconfirm icu || true
		;;
	alpine)
		sudo apk add icu-libs || true
		;;
	*)
		echo "Unsupported distro '$ID'; cannot install ICU automatically." >&2
		;;
	esac

	if ldconfig -p 2>/dev/null | grep -q libicuuc; then
		return 0
	fi

	echo "Warning: ICU runtime is not available; running agency installer with DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1." >&2
	export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
}

# The agency bootstrap is a .NET tool that resolves its Windows-side install
# path by running `cmd.exe`. etc/wsl.conf sets appendWindowsPath=false, so
# cmd.exe is off $PATH and the installer dies with Win32Exception(2) ->
# "Error obtaining access token" -> "Authentication failed, please try again."
ensure_interop_shims() {
	if command -v cmd.exe >/dev/null 2>&1; then
		return 0
	fi

	if [ -r "$SCRIPT_DIR/wsl-interop-shims.sh" ]; then
		echo "cmd.exe is not on PATH; restoring Windows interop shims..."
		bash "$SCRIPT_DIR/wsl-interop-shims.sh" || true
		export PATH="$HOME/.local/bin:$PATH"
	fi

	if ! command -v cmd.exe >/dev/null 2>&1; then
		echo "Warning: cmd.exe is still not on PATH; the agency sign-in will fail." >&2
	fi
}

if is_wsl; then
	install_wslview
	ensure_interop_shims
fi

ensure_libicu

# Do NOT `exec $SHELL` here: install.sh runs this as a child step, and exec-ing
# an interactive login shell would take over the terminal and block install.sh
# before it links the dotfiles. Restart your shell after install.sh completes.
#
# The installer exits 0 even when sign-in fails, so the exit code alone would
# report a broken install as success. Scan the output for the failure instead.
agency_log=$(mktemp)
trap 'rm -f "$agency_log"' EXIT

curl -sSfL https://aka.ms/InstallTool.sh | sh -s agency 2>&1 | tee "$agency_log"
# Snapshot immediately: PIPESTATUS is clobbered by the next command. Index 0 is
# curl, 1 is the installer. Checking only the installer would let a failed
# download pass, because `sh` exits 0 when it reads an empty script on stdin.
agency_status=("${PIPESTATUS[@]}")
curl_rc=${agency_status[0]}
agency_rc=${agency_status[1]}

if [ "$curl_rc" -ne 0 ]; then
	echo "ERROR: could not download the agency installer (curl exit $curl_rc)." >&2
	exit "$curl_rc"
fi

if [ "$agency_rc" -ne 0 ]; then
	echo "ERROR: the agency installer exited $agency_rc." >&2
	exit "$agency_rc"
fi

if grep -qE 'Error obtaining access token|Authentication failed' "$agency_log"; then
	echo >&2
	echo "ERROR: agency installed but could not sign in." >&2
	if is_wsl && ! command -v cmd.exe >/dev/null 2>&1; then
		echo "  Cause: cmd.exe is not on PATH (etc/wsl.conf sets appendWindowsPath=false)." >&2
		echo "  Fix:   bash $SCRIPT_DIR/wsl-interop-shims.sh && bash $SCRIPT_DIR/agency.sh" >&2
	else
		echo "  Retry: bash $SCRIPT_DIR/agency.sh" >&2
	fi
	exit 1
fi