#!/bin/bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# A container running on the WSL2 kernel inherits "microsoft" in /proc/version
# and /proc/sys/kernel/osrelease, but none of the Windows interop those strings
# imply: no $WSL_DISTRO_NAME, no /run/WSL, no drvfs mount, no cmd.exe. Testing
# the kernel alone made devcontainers look like WSL hosts, so this script chased
# wslu packages and interop shims that cannot exist there. Test for interop
# itself instead, and treat containers as the plain Linux boxes they are.
is_wsl() {
	if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
		return 1
	fi
	if [ -n "$WSL_DISTRO_NAME" ] || [ -n "$WSL_INTEROP" ]; then
		return 0
	fi
	if [ -d /run/WSL ]; then
		return 0
	fi
	if grep -qiE "(microsoft|wsl)" /proc/sys/kernel/osrelease 2>/dev/null && [ -d /mnt/c ]; then
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

# PathInstaller can sign in three ways -- AzureAuth, ManagedIdentity or
# AzureCli -- and defaults to AzureAuth, which is the one method that cannot
# work in this container. Two independent faults sit on that default.
#
# First the browser never got back to us. Web sign-in parks a callback listener
# on our loopback, and that loop *does* close in a devcontainer: the editor
# auto-forwards the listener's port. But azureauth binds the callback on [::1]
# only while the forwarder dials 127.0.0.1, so every redirect arrived and was
# refused -- one "ECONNREFUSED 127.0.0.1:<port>" pair per attempt in the
# editor's remote log. Forcing the listener onto IPv4 does fix that much.
#
# Fixing it only exposed the second fault. Sign-in then genuinely succeeded --
# the installer logged CacheLoadSucceeded and CacheSaveSucceeded -- and it
# segfaulted immediately afterwards, on every attempt, inside that same
# library. The crash had looked intermittent only because a run that cannot
# reach sign-in never reaches the crash either.
#
# AzureCli sidesteps both: the token comes from `az`, so the azureauth stack is
# never loaded and neither the bind nor the crash is reachable. It needs a
# logged-in `az`, whose own callback binds 0.0.0.0 inside a container and so is
# reachable by the forwarder.
ensure_azure_cli_login() {
	# Probe that az *runs*, not merely that the name resolves: a codespace shim
	# can occupy it on PATH with no real Azure CLI behind it (see az.sh).
	if ! az version >/dev/null 2>&1; then
		echo "Azure CLI is unavailable; falling back to the AzureAuth sign-in." >&2
		echo "  For a sign-in that works here, install it: bash $SCRIPT_DIR/az.sh" >&2
		return 1
	fi

	if az account show >/dev/null 2>&1; then
		return 0
	fi

	if [ "$interactive_auth" -ne 1 ]; then
		return 1
	fi

	# Let az warn normally here. It prints the sign-in URL at warning level, and
	# --only-show-errors would swallow the one line that rescues a run where the
	# browser fails to open. Only its success JSON is noise worth dropping.
	echo "Signing in to Azure CLI; a browser window will open..."
	if az login >/dev/null; then
		return 0
	fi

	echo "Warning: 'az login' did not complete; falling back to AzureAuth." >&2
	return 1
}

# /dev/tty must be *opened*, not just tested with -e: it exists as a device node
# even in a container with no controlling terminal (install.sh relies on the
# same distinction for its sudo warm-up).
has_controlling_terminal() {
	[ -t 0 ] && (exec 3<>/dev/tty) 2>/dev/null
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

report_agency_skipped() {
	echo >&2
	echo "WARNING: agency was not installed -- its installer must sign in first." >&2
	echo "  Cause: no controlling terminal is available for the interactive auth flow." >&2
	echo "  Fix:   re-run from an interactive shell: bash $SCRIPT_DIR/agency.sh" >&2
}

# With no terminal at all nobody can complete the sign-in, so bound the
# installer: left alone it still starts its web flow and blocks through three
# five-minute timeouts.
if has_controlling_terminal; then
	interactive_auth=1
else
	interactive_auth=0
	echo "No terminal available for the agency sign-in; skipping this step." >&2
fi

# Falls back to the installer's own default when az cannot carry the sign-in,
# so a machine without Azure CLI still gets the behaviour it had before.
auth_args=()
if ensure_azure_cli_login; then
	auth_args=(--auth-method=AzureCli)
fi

installer_runner=(sh -s agency "${auth_args[@]}")
if [ "$interactive_auth" -eq 0 ] && command -v timeout >/dev/null 2>&1; then
	installer_runner=(timeout 300 sh -s agency "${auth_args[@]}")
fi

# PathInstaller can still take a SIGSEGV from the qemu layer this container runs
# under -- the same emulation fragility that makes rustc unusable here. Retry
# rather than making the caller rerun the whole script.
#
# The crash does not reach the exit status. InstallTool.sh ends on an `export`,
# so the pipeline reports that export's status and a PathInstaller killed by a
# signal still looks like a clean install -- which is exactly how a crashed run
# got reported as success. Scan the output for it instead.
installer_crashed() {
	grep -qE 'Segmentation fault|core dumped' "$agency_log"
}

# Each of those crashes drops a ~270MB core into $PWD; that is how this repo
# once accumulated 1.2GB of them. The emulator is not ours to fix, but it does
# not get to litter whatever directory the caller happened to be standing in.
ulimit -c 0 2>/dev/null || true

for attempt in 1 2 3; do
	curl -sSfL https://aka.ms/InstallTool.sh | "${installer_runner[@]}" 2>&1 | tee "$agency_log"
	# Snapshot immediately: PIPESTATUS is clobbered by the next command. Index 0
	# is curl, 1 is the installer. Checking only the installer would let a failed
	# download pass, because `sh` exits 0 when it reads an empty script on stdin.
	agency_status=("${PIPESTATUS[@]}")
	curl_rc=${agency_status[0]}
	agency_rc=${agency_status[1]}

	if [ "$curl_rc" -ne 0 ]; then
		echo "ERROR: could not download the agency installer (curl exit $curl_rc)." >&2
		exit "$curl_rc"
	fi

	installer_crashed || break
	if [ "$attempt" -lt 3 ]; then
		echo "The agency installer crashed; retrying (attempt $attempt of 3)." >&2
	fi
done

if installer_crashed; then
	echo >&2
	echo "ERROR: the agency installer crashed on all three attempts." >&2
	echo "  Cause: intermittent SIGSEGV from the qemu layer, not your sign-in." >&2
	echo "  Retry: bash $SCRIPT_DIR/agency.sh" >&2
	exit 1
fi

if [ "$agency_rc" -ne 0 ]; then
	# 124 is `timeout` giving up on a sign-in we already knew nobody could
	# complete. Treat it as a skip: an unattended run is not a broken install,
	# and failing the step here would flag every container run red.
	if [ "$interactive_auth" -eq 0 ] && [ "$agency_rc" -eq 124 ]; then
		report_agency_skipped
		exit 0
	fi
	echo "ERROR: the agency installer exited $agency_rc." >&2
	exit "$agency_rc"
fi

if grep -qE 'Error obtaining access token|Authentication failed' "$agency_log"; then
	if [ "$interactive_auth" -eq 0 ]; then
		report_agency_skipped
		exit 0
	fi
	echo >&2
	# Sign-in is not a post-install step: the installer trades the token for a
	# PAT to fetch the package, so a failed sign-in means nothing was installed.
	echo "ERROR: agency sign-in failed; the tool was not installed." >&2
	if is_wsl && ! command -v cmd.exe >/dev/null 2>&1; then
		echo "  Cause: cmd.exe is not on PATH (etc/wsl.conf sets appendWindowsPath=false)." >&2
		echo "  Fix:   bash $SCRIPT_DIR/wsl-interop-shims.sh && bash $SCRIPT_DIR/agency.sh" >&2
	elif [ ${#auth_args[@]} -gt 0 ]; then
		# az answered `account show` or we would not be on this path, so the
		# account exists and its token is the part that did not hold up.
		echo "  Cause: the Azure CLI token was rejected -- expired, or the wrong tenant." >&2
		echo "  Fix:   az login && bash $SCRIPT_DIR/agency.sh" >&2
	else
		echo "  Retry: bash $SCRIPT_DIR/agency.sh" >&2
	fi
	exit 1
fi

# The installer's exit status cannot be trusted (see the crash note above), so
# confirm the tool actually landed instead of inferring it from a quiet run.
# InstallTool.sh unpacks into ~/.config/agency/CurrentVersion and only puts that
# on PATH inside its own shell, so check the directory as well as PATH.
if ! command -v agency >/dev/null 2>&1 &&
	[ -z "$(ls -A "$HOME/.config/agency/CurrentVersion" 2>/dev/null)" ]; then
	if [ "$interactive_auth" -eq 0 ]; then
		report_agency_skipped
		exit 0
	fi
	echo >&2
	echo "ERROR: the installer reported success but no agency binary was installed." >&2
	echo "  Retry: bash $SCRIPT_DIR/agency.sh" >&2
	exit 1
fi