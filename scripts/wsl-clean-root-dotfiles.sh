#!/bin/bash
# Remove dotfile symlinks that a previous *root* run of install.sh created.
#
#   wsl-clean-root-dotfiles.sh <dotfiles-repo-path>[:<path>...] [home]
#
# install.ps1 used to invoke install.sh before a non-root user existed, so every
# config was linked into /root. This unlinks those stale links only. A path is
# removed exclusively when it is a symlink whose target points into the dotfiles
# repo -- real files are never deleted, and installed trees such as ~/.nvm,
# ~/.cargo, ~/.nuget, ~/.rustup and ~/.tmux/plugins are never touched.
#
# The repo argument takes a PATH-style colon-separated list because install.sh
# can now be run from two places: the Windows checkout under /mnt/<drive>/... and
# the distro's own clone under ~/.local/src/dotfiles. A link left by either one
# is stale. A single path still works exactly as before.

set -uo pipefail

repo="${1:-}"
home="${2:-/root}"

if [ -z "$repo" ]; then
	echo "usage: wsl-clean-root-dotfiles.sh <dotfiles-repo-path>[:<path>...] [home]" >&2
	exit 2
fi

IFS=':' read -r -a repos <<<"$repo"

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
	matched=0
	for r in "${repos[@]}"; do
		[ -n "$r" ] || continue
		case "$target" in
		"$r"/*)
			matched=1
			break
			;;
		esac
	done

	if [ "$matched" -eq 1 ]; then
		rm -f "$path" && removed=$((removed + 1))
		echo "[clean-root] removed $path -> $target"
	else
		kept=$((kept + 1))
		echo "[clean-root] kept    $path -> $target (not a dotfiles link)"
	fi
done

echo "[clean-root] $removed stale link(s) removed, $kept left alone"
