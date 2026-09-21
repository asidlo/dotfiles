#!/bin/bash
# Provision a non-root default user inside a WSL distro.
#
#   printf '%s' "$password" | wsl-provision-user.sh <username>
#
# The password is read from *stdin*, never from argv, so it cannot leak into
# `ps`, the shell history, or the install.ps1 transcript. Passing no stdin (or
# empty stdin) creates the user without touching its password.

set -uo pipefail

user="${1:-}"
if [ -z "$user" ]; then
	echo "usage: wsl-provision-user.sh <username>" >&2
	exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
	echo "[wsl-user] must run as root" >&2
	exit 1
fi

shell=/bin/bash
[ -x /bin/zsh ] && shell=/bin/zsh

if id -u "$user" >/dev/null 2>&1; then
	echo "[wsl-user] $user already exists"
else
	echo "[wsl-user] creating $user (login shell: $shell)"
	if ! useradd -m -s "$shell" "$user"; then
		echo "[wsl-user] useradd failed for $user" >&2
		exit 1
	fi
fi

# The admin group is named differently across distros; join whichever exist.
for grp in sudo wheel adm; do
	if getent group "$grp" >/dev/null 2>&1; then
		usermod -aG "$grp" "$user" 2>/dev/null || true
	fi
done

if [ ! -t 0 ]; then
	# PowerShell pipes with CRLF line endings, so a password arriving from
	# install.ps1 carries a trailing carriage return. Left in place it would be
	# baked into the hash and the user could never log in with what they typed.
	pw="$(cat | tr -d '\r')"
	if [ -n "$pw" ]; then
		if printf '%s:%s\n' "$user" "$pw" | chpasswd; then
			echo "[wsl-user] password set for $user"
		else
			echo "[wsl-user] chpasswd failed; set one later with: sudo passwd $user" >&2
		fi
	else
		echo "[wsl-user] no password supplied; existing password left unchanged"
	fi
	unset pw
fi

# Rewrite /etc/wsl.conf's [user] section. Any existing [user] section is dropped
# wholesale and replaced, so the result is deterministic across re-runs; every
# other section is preserved. The command substitution strips trailing blank
# lines, so repeated runs don't slowly grow the file.
conf=/etc/wsl.conf
touch "$conf"
body="$(awk '
	/^[[:space:]]*\[/ { section = $0; gsub(/[[:space:]]/, "", section) }
	{ if (section == "[user]") next; print }
' "$conf")"
{
	if [ -n "$body" ]; then
		printf '%s\n\n' "$body"
	fi
	printf '[user]\ndefault=%s\n' "$user"
} >"$conf"
echo "[wsl-user] /etc/wsl.conf default user = $user"
