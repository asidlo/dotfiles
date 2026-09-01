#!/bin/bash
# Restore the handful of Windows executables that Linux-side tooling shells out
# to by name.
#
# etc/wsl.conf deliberately sets `appendWindowsPath=false` so the ~15 Windows
# directories stay out of $PATH -- they slow completion down and shadow Linux
# binaries. The side effect is that `cmd.exe`, `clip.exe` and friends stop
# resolving, which silently breaks callers that look them up with `command -v`:
#
#   * scripts/agency.sh   -> the AzureAuth PathInstaller runs `cmd.exe` from
#                            GetDefaultPathWSL() and dies with Win32Exception(2)
#                            ("Authentication failed, please try again.")
#   * bin/pbcopy          -> falls back to OSC52 instead of the real clipboard
#   * bin/open            -> `cmd.exe /c start` fallback fails
#
# Symlinking just these few into ~/.local/bin keeps the clean $PATH and needs no
# sudo. Interop itself is untouched (`enabled=true`), so the symlinks execute
# through binfmt_misc exactly like the originals.

set -o pipefail

if ! grep -qi microsoft /proc/version 2>/dev/null && [ -z "${WSL_DISTRO_NAME:-}" ]; then
	echo "Not running under WSL; no interop shims needed."
	exit 0
fi

# The C: mount is /mnt/c by default but automount.root is configurable, so fall
# back to scanning the Windows drive mounts rather than hardcoding one path.
find_windir() {
	local candidate mountpoint fstype

	for candidate in /mnt/c/Windows /c/Windows; do
		if [ -x "$candidate/System32/cmd.exe" ]; then
			printf '%s' "$candidate"
			return 0
		fi
	done

	while read -r _ mountpoint fstype _; do
		case "$fstype" in
		9p | drvfs | virtiofs) ;;
		*) continue ;;
		esac
		if [ -x "$mountpoint/Windows/System32/cmd.exe" ]; then
			printf '%s' "$mountpoint/Windows"
			return 0
		fi
	done </proc/mounts

	return 1
}

WINDIR=$(find_windir) || {
	echo "Could not locate the Windows directory from WSL; skipping interop shims." >&2
	echo "  Is [automount] disabled, or the C: drive not mounted?" >&2
	exit 0
}

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# name -> path relative to %WINDIR%. explorer.exe lives beside System32, and
# powershell.exe is nested under WindowsPowerShell/v1.0.
SHIMS=(
	"cmd.exe:System32/cmd.exe"
	"clip.exe:System32/clip.exe"
	"wsl.exe:System32/wsl.exe"
	"powershell.exe:System32/WindowsPowerShell/v1.0/powershell.exe"
	"explorer.exe:explorer.exe"
)

linked=0
skipped=0

for entry in "${SHIMS[@]}"; do
	name="${entry%%:*}"
	rel="${entry#*:}"
	target="$WINDIR/$rel"

	if [ ! -x "$target" ]; then
		echo "  skip    $name (not found at $target)"
		skipped=$((skipped + 1))
		continue
	fi

	# Never clobber a real Linux binary or a hand-rolled shim that isn't ours.
	if [ -e "$BIN_DIR/$name" ] && [ ! -L "$BIN_DIR/$name" ]; then
		echo "  skip    $name (a non-symlink already exists at $BIN_DIR/$name)"
		skipped=$((skipped + 1))
		continue
	fi

	ln -sfn "$target" "$BIN_DIR/$name"
	echo "  link    $name -> $target"
	linked=$((linked + 1))
done

echo "Interop shims: $linked linked, $skipped skipped (in $BIN_DIR)."

case ":$PATH:" in
*":$BIN_DIR:"*) ;;
*) echo "Note: $BIN_DIR is not on \$PATH in this shell; open a new shell to pick the shims up." >&2 ;;
esac
