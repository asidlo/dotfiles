#!/bin/bash
# Remove dotfile symlinks that a previous *root* run of install.sh created.
#
#   wsl-clean-root-dotfiles.sh <dotfiles-repo-path> [home]
#
# install.ps1 used to invoke install.sh before a non-root user existed, so every
# config was linked into /root. This unlinks those stale links only. A path is
# removed exclusively when it is a symlink whose target points into the dotfiles
# repo -- real files are never deleted, and installed trees such as ~/.nvm,
# ~/.cargo, ~/.nuget, ~/.rustup and ~/.tmux/plugins are never touched.

set -uo pipefail

repo="${1:-}"
home="${2:-/root}"

if [ -z "$repo" ]; then
	echo "usage: wsl-clean-root-dotfiles.sh <dotfiles-repo-path> [home]" >&2
	exit 2
fi

links=(
	.gitconfig
	.vimrc
	.zshrc
	.zshenv
	.bashrc
	.tmux.conf
	.ssh/config
	.config/git/keys
	.config/lazygit/config.yml
	.config/starship.toml
	.config/nvim
	.local/bin/pbcopy
	.local/bin/pbpaste
	.local/bin/open
	.local/bin/git-credential-manager-wsl
)

removed=0
kept=0

for rel in "${links[@]}"; do
	path="$home/$rel"
	[ -L "$path" ] || continue

	target="$(readlink "$path")"
	case "$target" in
	"$repo"/*)
		rm -f "$path" && removed=$((removed + 1))
		echo "[clean-root] removed $path -> $target"
		;;
	*)
		kept=$((kept + 1))
		echo "[clean-root] kept    $path -> $target (not a dotfiles link)"
		;;
	esac
done

echo "[clean-root] $removed stale link(s) removed, $kept left alone"
