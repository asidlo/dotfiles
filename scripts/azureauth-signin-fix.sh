#!/usr/bin/env bash
# azureauth sign-in fix for containers and remote (VS Code) sessions.
#
# Symptom this cures: starting Copilot CLI / Agency pops a browser that spins
# forever on https://login.microsoftonline.com/<tenant>/reprocess?ctx=..., and
# no MCP server ever finishes authenticating.
#
# Three faults compound to produce it:
#
#  1. THUNDERING HERD. Agency launches its MCP servers together, and each one
#     shells out to its own `azureauth` for a token. With a cold MSAL cache
#     that is ~8 interactive sign-ins at once, all landing in a single browser
#     profile where they share AAD session cookies. They overwrite each other's
#     ctx/sessionid, so the interrupt ("reprocess") page never resolves. An
#     exclusive lock here lets exactly one sign-in run at a time.
#
#  2. IPv6-ONLY REDIRECT LISTENER. MSAL binds its loopback redirect listener to
#     [::1]:<random port> -- verified with `ss -ltnp`, where the azureauth row
#     shows [::1]:45193 and no IPv4 socket, and `curl -4 127.0.0.1:45193`
#     is refused while `curl -6 [::1]:45193` answers. VS Code's port forwarding
#     reaches into the container over IPv4, so the browser's redirect to
#     http://localhost:<port>/?code=... never arrives and azureauth waits out
#     its full 15-minute timeout. The helper below mirrors that listener onto
#     127.0.0.1 for the lifetime of each azureauth process.
#
#  3. ORPHANED CHILDREN. Agency gives up on azureauth after 180s but does not
#     kill it, so the abandoned process keeps holding a browser tab and an AAD
#     session for the remaining ~12 minutes and poisons the next attempt. The
#     lock in (1) contains the blast radius; the wrapper also reaps its child
#     if it is signalled.
#
# Agency invokes the hardcoded path /usr/bin/azureauth -- confirmed by probing
# both it and a PATH-earlier /usr/local/bin/azureauth, where only the former
# fired. So the wrapper has to take over /usr/bin/azureauth; a shim earlier in
# PATH is simply never consulted. The real binary is left untouched and is
# rediscovered at runtime, so upgrades of the azureauth package still apply.
#
# Scope: containers and remote sessions only. On a WSL *host* Agency resolves
# the Windows azureauth.exe through wslpath instead, and a desktop Linux box
# runs the browser in the same network namespace, so neither needs this.
#
# Best-effort: never fails the parent install.
#
# Undo with:
#   sudo ln -sfn "$(cat /usr/local/share/azureauth-signin-fix/real-path)" \
#     /usr/bin/azureauth
#   sudo rm -rf /usr/local/share/azureauth-signin-fix
#   rm -f ~/.local/bin/azureauth-replay-redirect

MARKER="dotfiles-azureauth-signin-fix"
SHARE_DIR="/usr/local/share/azureauth-signin-fix"
WRAPPER="$SHARE_DIR/azureauth-wrapper"
BRIDGE="$SHARE_DIR/redirect-bridge.py"
TARGET="/usr/bin/azureauth"
DOTFILES_DIR=$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-$0}")")")

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  echo "azureauth-signin-fix: need root or sudo; skipping."
  exit 0
fi

# --- applicability ----------------------------------------------------------
in_container=0
if [ -f /.dockerenv ] || [ -f /run/.containerenv ] ||
  [ -n "$REMOTE_CONTAINERS" ] || [ -n "$CODESPACES" ] ||
  [ -n "$DEVCONTAINER" ] || [ -d /workspaces ]; then
  in_container=1
fi

remote_session=0
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ]; then
  remote_session=1
fi

if [ "$in_container" -eq 0 ] && [ "$remote_session" -eq 0 ]; then
  echo "azureauth-signin-fix: not a container or remote session; nothing to do."
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "azureauth-signin-fix: python3 not found; skipping (the bridge needs it)." >&2
  exit 0
fi

# --- locate the REAL azureauth ----------------------------------------------
# Anything carrying our marker is a previous wrapper, never the real binary --
# without this check a re-run would wrap the wrapper and fork-bomb on first use.
is_ours() { grep -qs "$MARKER" "$1"; }

REAL=""
for cand in \
  /usr/lib/azureauth/azureauth \
  /opt/azureauth/azureauth \
  /usr/local/lib/azureauth/azureauth; do
  if [ -x "$cand" ] && ! is_ours "$cand"; then
    REAL="$cand"
    break
  fi
done

# Agency also installs per-version copies under ~/.azureauth/<version>/; take
# the highest version if no packaged binary was found.
if [ -z "$REAL" ]; then
  for cand in $(ls -d "$HOME"/.azureauth/*/azureauth 2>/dev/null | sort -V -r); do
    if [ -x "$cand" ] && ! is_ours "$cand"; then
      REAL="$cand"
      break
    fi
  done
fi

# Last resort: whatever /usr/bin/azureauth already resolves to, provided it is
# not our own wrapper.
if [ -z "$REAL" ] && [ -e "$TARGET" ]; then
  cand=$(readlink -f "$TARGET" 2>/dev/null)
  if [ -n "$cand" ] && [ -x "$cand" ] && ! is_ours "$cand"; then
    REAL="$cand"
  fi
fi

if [ -z "$REAL" ]; then
  echo "azureauth-signin-fix: no azureauth binary found; skipping."
  exit 0
fi

echo "azureauth-signin-fix: real binary is $REAL"

$SUDO mkdir -p "$SHARE_DIR" || {
  echo "azureauth-signin-fix: cannot create $SHARE_DIR; skipping." >&2
  exit 0
}

# --- the IPv4 -> IPv6 redirect bridge ---------------------------------------
$SUDO tee "$BRIDGE" >/dev/null <<'PY'
#!/usr/bin/env python3
"""Mirror azureauth's IPv6-only OAuth redirect listener onto IPv4.

MSAL binds its loopback redirect listener to [::1]:<port>. VS Code forwards
ports into a container over IPv4, so the browser's redirect to
http://localhost:<port>/?code=... never reaches it and sign-in hangs.

Given the azureauth pid, wait for that listener to appear, publish a matching
127.0.0.1 listener that forwards to it, and exit when the process goes away.
"""
import re
import socket
import subprocess
import sys
import threading
import time

PAT = re.compile(r"\[::1\]:(\d+)")


def pump(src, dst):
    try:
        while True:
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except OSError:
        pass
    finally:
        for s in (src, dst):
            try:
                s.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            s.close()


def handle(client, port):
    try:
        upstream = socket.create_connection(("::1", port), timeout=10)
    except OSError:
        client.close()
        return
    threading.Thread(target=pump, args=(client, upstream), daemon=True).start()
    threading.Thread(target=pump, args=(upstream, client), daemon=True).start()


def alive(pid):
    try:
        with open("/proc/%d/stat" % pid):
            return True
    except OSError:
        return False


def find_port(pid, deadline):
    while time.time() < deadline and alive(pid):
        try:
            out = subprocess.run(
                ["ss", "-ltnpH"], capture_output=True, text=True, timeout=5
            ).stdout
        except Exception:
            return None
        for line in out.splitlines():
            if "pid=%d," % pid in line:
                m = PAT.search(line)
                if m:
                    return int(m.group(1))
        time.sleep(0.2)
    return None


def main():
    if len(sys.argv) != 2:
        return 2
    pid = int(sys.argv[1])

    port = find_port(pid, time.time() + 60)
    if not port:
        return 0

    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        srv.bind(("127.0.0.1", port))
    except OSError:
        # Something already owns the IPv4 side; azureauth can still be reached
        # directly over IPv6, so this is not fatal.
        return 0
    srv.listen(64)
    srv.settimeout(0.5)

    while alive(pid):
        try:
            client, _ = srv.accept()
        except socket.timeout:
            continue
        except OSError:
            break
        handle(client, port)
    srv.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY

# --- the serializing wrapper -------------------------------------------------
# $REAL is expanded now (unquoted heredoc marker) so the wrapper records the
# binary this install found; everything else is escaped to survive to runtime.
$SUDO tee "$WRAPPER" >/dev/null <<EOF
#!/usr/bin/env bash
# $MARKER
#
# Serializes interactive azureauth sign-ins and bridges MSAL's IPv6-only
# redirect listener to IPv4. Installed by dotfiles scripts/azureauth-signin-fix.sh;
# see that file for the full rationale.

MARKER="$MARKER"
REAL="$REAL"
BRIDGE="$BRIDGE"
LOCK="\${AZUREAUTH_SIGNIN_LOCK:-/tmp/azureauth-signin.lock}"
EOF

$SUDO tee -a "$WRAPPER" >/dev/null <<'EOF'

# Re-resolve if the recorded binary moved (package upgrade, version bump).
if [ ! -x "$REAL" ] || grep -qs "$MARKER" "$REAL"; then
    REAL=""
    for cand in /usr/lib/azureauth/azureauth /opt/azureauth/azureauth \
                /usr/local/lib/azureauth/azureauth \
                $(ls -d "$HOME"/.azureauth/*/azureauth 2>/dev/null | sort -V -r); do
        if [ -x "$cand" ] && ! grep -qs "$MARKER" "$cand"; then
            REAL="$cand"
            break
        fi
    done
fi

if [ -z "$REAL" ] || [ ! -x "$REAL" ]; then
    echo "azureauth: real binary not found (wrapper installed by dotfiles)" >&2
    exit 127
fi

# Version and help probes must stay fast and must never serialize: Agency calls
# `azureauth --version` to validate its pin, and blocking that behind a sign-in
# lock would stall startup for every MCP server.
case " $* " in
    *" --version "*|*" -h "*|*" --help "*|*" -? "*)
        exec "$REAL" "$@"
        ;;
esac

run_with_bridge() {
    "$REAL" "$@" &
    local pid=$!
    if [ -x "$BRIDGE" ] && command -v python3 >/dev/null 2>&1; then
        setsid python3 "$BRIDGE" "$pid" >/dev/null 2>&1 &
    fi
    # Do not leave an orphan holding a browser tab and an AAD session if the
    # caller gives up on us; that stale sign-in poisons the next attempt.
    trap 'kill "$pid" 2>/dev/null' INT TERM HUP
    wait "$pid"
}

# The braces matter: `exec 9>"$LOCK" 2>/dev/null` would redirect fd 2 for the
# whole script, silently eating azureauth's own prompts and errors. Scoping the
# redirect to a command group keeps it to the exec itself. Failing to take the
# lock (read-only /tmp, another user owns the file) is not fatal -- serializing
# is an optimisation, so fall through and just run.
if ! { exec 9>"$LOCK"; } 2>/dev/null; then
    run_with_bridge "$@"
    exit $?
fi

if command -v flock >/dev/null 2>&1 && flock 9; then
    run_with_bridge "$@"
    status=$?
    flock -u 9
    exit $status
fi

run_with_bridge "$@"
EOF

$SUDO chmod 0755 "$WRAPPER" "$BRIDGE"

# --- take over /usr/bin/azureauth -------------------------------------------
# Record where the real binary was, so the undo instructions in the header can
# be followed without guessing. Only written once, and never pointed at us.
if [ ! -e "$SHARE_DIR/real-path" ]; then
  printf '%s\n' "$REAL" | $SUDO tee "$SHARE_DIR/real-path" >/dev/null
fi

$SUDO ln -sfn "$WRAPPER" "$TARGET"

# Manual escape hatch for a redirect that strands anyway (the bridge only runs
# while azureauth does; a sign-in finished after it gave up still dead-ends).
if [ -x "$DOTFILES_DIR/bin/azureauth-replay-redirect" ]; then
  mkdir -p ~/.local/bin &&
    ln -sfn "$DOTFILES_DIR/bin/azureauth-replay-redirect" \
      ~/.local/bin/azureauth-replay-redirect
fi

# Prove the passthrough still works; a broken azureauth would silently break
# every Agency/Copilot sign-in, so undo rather than leave that in place.
if ver=$("$TARGET" --version 2>/dev/null); then
  echo "azureauth-signin-fix: installed (azureauth $ver via $TARGET)."
  echo "azureauth-signin-fix: sign-ins are now serialized and IPv4-bridged."
else
  echo "azureauth-signin-fix: wrapper failed its --version check; reverting." >&2
  $SUDO ln -sfn "$REAL" "$TARGET"
  exit 0
fi

exit 0
