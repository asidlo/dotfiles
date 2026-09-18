#!/bin/bash
# Grant or revoke a *temporary* passwordless-sudo drop-in inside a WSL distro.
#
#   wsl-sudoers-temp.sh grant <user>
#   wsl-sudoers-temp.sh revoke
#
# Why this exists: install.ps1 captures install.sh's output through a PowerShell
# pipeline, so the distro is handed no controlling pty. `sudo -v` then prompts on
# a terminal nobody can answer and dies on sudo's five-minute passwd_timeout --
# the exact "wsl-install-sh ... 00:05:00 ... exit 1" failure. Worse, with no tty
# sudo's default timestamp_type=tty degrades to `ppid`, so even an answered
# prompt would not carry into the per-tool scripts install.sh spawns: it would
# re-prompt, and hang again, part way through the run.
#
# The drop-in is deliberately short-lived. install.ps1 revokes it in a finally
# block, and revokes any leftover from a killed run before it grants a new one.
#
# The filename is fixed (and dot-free -- sudo ignores files in sudoers.d whose
# name contains a '.'), so two install.ps1 runs against the same distro would
# fight over it: one run's revoke can drop the other's active grant. That is
# accepted. Concurrent elevated runs of install.ps1 already race on far more
# destructive things -- winget, the Visual Studio installer, `wsl --manage
# --move` -- so they are unsupported outright rather than made safe here.

set -uo pipefail

FILE=/etc/sudoers.d/99-dotfiles-install

action="${1:-}"
user="${2:-}"

if [ "$(id -u)" -ne 0 ]; then
	echo "[wsl-sudoers] must run as root" >&2
	exit 1
fi

case "$action" in
revoke)
	if [ -e "$FILE" ]; then
		if rm -f "$FILE"; then
			echo "[wsl-sudoers] revoked temporary passwordless sudo ($FILE)"
		else
			echo "[wsl-sudoers] failed to remove $FILE -- remove it by hand" >&2
			exit 1
		fi
	else
		echo "[wsl-sudoers] no temporary sudoers drop-in to revoke"
	fi
	;;
grant)
	if [ -z "$user" ]; then
		echo "usage: wsl-sudoers-temp.sh grant <user>" >&2
		exit 2
	fi
	if ! id -u "$user" >/dev/null 2>&1; then
		echo "[wsl-sudoers] no such user: $user" >&2
		exit 1
	fi

	# Validate before installing. A syntactically broken file in sudoers.d
	# breaks sudo for *every* user of the distro, so it is never written
	# straight to its final location.
	tmp="$(mktemp)" || exit 1
	printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$user" >"$tmp"
	if ! visudo -cf "$tmp" >/dev/null 2>&1; then
		echo "[wsl-sudoers] refusing to install an invalid sudoers file" >&2
		rm -f "$tmp"
		exit 1
	fi
	install -m 0440 -o root -g root "$tmp" "$FILE"
	rc=$?
	rm -f "$tmp"
	if [ "$rc" -ne 0 ]; then
		echo "[wsl-sudoers] failed to install $FILE" >&2
		exit 1
	fi

	# Prove it actually took effect rather than trusting the write, so a
	# failure surfaces here instead of as another five-minute hang later.
	if command -v runuser >/dev/null 2>&1; then
		if ! runuser -u "$user" -- sudo -n true 2>/dev/null; then
			echo "[wsl-sudoers] $FILE installed but '$user' still needs a password" >&2
			exit 1
		fi
	fi
	echo "[wsl-sudoers] granted temporary passwordless sudo to '$user' ($FILE)"
	;;
*)
	echo "usage: wsl-sudoers-temp.sh grant <user> | revoke" >&2
	exit 2
	;;
esac
