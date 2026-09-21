#!/bin/bash
# Clone (or refresh) the dotfiles repo *inside* the distro's own filesystem.
#
#   wsl-clone-dotfiles.sh [dest] [repo-url]
#
# `dest` defaults to .local/src/dotfiles and is resolved against $HOME unless it
# is absolute.
#
# install.ps1's Phase 6 used to run install.sh straight off the Windows checkout
# under /mnt/<drive>/..., which meant every symlink install.sh created pointed
# back across the 9p/drvfs boundary. Those links resolve, but:
#
#   * they are slow -- a git-aware `eza -la --git` listing costs ~17s on drvfs
#     against ~90ms on ext4, because libgit2 stats the whole tree over 9p;
#   * they evaporate whenever the Dev Drive is not mounted, which is every time
#     the distro boots before Windows has attached it;
#   * drvfs reports every file as mode 0777 regardless of the git index, so
#     permission mistakes stay invisible until something else reads the tree.
#
# Giving the distro its own clone removes the boundary. This script only lands
# the checkout; install.sh is run separately from the resulting path.
#
# Idempotent: an existing clone is fast-forwarded, and a clone carrying local
# modifications is left strictly alone rather than overwritten.

set -uo pipefail

DEST="${1:-.local/src/dotfiles}"
REPO_URL="${2:-https://github.com/asidlo/dotfiles}"

# Anchor a relative destination to $HOME here rather than in the caller, so
# install.ps1 never has to guess where the distro user's home actually is.
case "$DEST" in
/*) ;;
*) DEST="$HOME/$DEST" ;;
esac

log() { printf '[clone-dotfiles] %s\n' "$*"; }
die() {
	printf '[clone-dotfiles] ERROR: %s\n' "$*" >&2
	exit 1
}

case "$DEST" in
/mnt/*)
	# Not fatal -- an explicit override is the caller's business -- but this is
	# precisely the arrangement the script exists to get away from.
	log "WARNING: destination '$DEST' is on a Windows mount; that defeats the purpose of a native clone"
	;;
esac

if ! command -v git >/dev/null 2>&1; then
	# install.sh installs git via dependencies.sh, but that runs *after* this,
	# from the very checkout we are trying to create. Bootstrap it here.
	log "git not found; attempting to install it"
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update -qq && sudo apt-get install -y git
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y git
	elif command -v tdnf >/dev/null 2>&1; then
		sudo tdnf install -y git
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -S --noconfirm git
	fi
	command -v git >/dev/null 2>&1 || die "git is required but could not be installed"
fi

if [ -d "$DEST/.git" ]; then
	if ! git -C "$DEST" rev-parse --git-dir >/dev/null 2>&1; then
		die "'$DEST' contains a .git entry but is not a usable repository"
	fi

	origin="$(git -C "$DEST" remote get-url origin 2>/dev/null || true)"
	log "existing clone at $DEST (origin: ${origin:-<none>})"

	# A dirty tree means the user is working in here. Updating it behind their
	# back is how you lose someone's afternoon; report and move on instead.
	if [ -n "$(git -C "$DEST" status --porcelain 2>/dev/null)" ]; then
		log "local changes present; leaving the checkout untouched"
	elif [ -z "$origin" ]; then
		log "no origin remote; nothing to fast-forward"
	elif ! git -C "$DEST" fetch --prune --quiet origin 2>/dev/null; then
		# Offline, or the remote needs credentials nobody can supply here. The
		# checkout on disk is still perfectly usable, so this is not fatal.
		log "fetch failed (offline?); using the checkout as-is"
	elif ! upstream="$(git -C "$DEST" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"; then
		log "current branch has no upstream; skipping fast-forward"
	elif git -C "$DEST" merge --ff-only --quiet "$upstream" 2>/dev/null; then
		log "in sync with $upstream ($(git -C "$DEST" rev-parse --short HEAD))"
	else
		# Diverged from upstream: a rebase or reset is a judgement call the
		# installer has no business making unattended.
		log "cannot fast-forward onto $upstream; leaving the checkout as-is"
	fi
elif [ -e "$DEST" ]; then
	# An empty directory is fine to clone into; anything else is someone's data.
	if [ -d "$DEST" ] && [ -z "$(ls -A "$DEST" 2>/dev/null)" ]; then
		log "cloning $REPO_URL into existing empty directory $DEST"
		git clone --quiet "$REPO_URL" "$DEST" || die "git clone failed"
	else
		die "'$DEST' already exists and is not a dotfiles clone; move it aside first"
	fi
else
	log "cloning $REPO_URL -> $DEST"
	mkdir -p "$(dirname "$DEST")" || die "could not create $(dirname "$DEST")"
	git clone --quiet "$REPO_URL" "$DEST" || die "git clone failed"
fi

[ -f "$DEST/install.sh" ] || die "'$DEST' has no install.sh; is this the dotfiles repo?"

log "ready at $DEST ($(git -C "$DEST" rev-parse --short HEAD 2>/dev/null || echo unknown))"

# Machine-readable last line: install.ps1 reads this back to decide the working
# directory it hands to `wsl --cd`, rather than re-deriving the path itself.
printf 'dotfiles-path=%s\n' "$DEST"
