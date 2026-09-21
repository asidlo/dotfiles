#!/usr/bin/env bash
# AppGw dev "browser bridge".
#
# Tools that run INSIDE the appgw container (az / gh / copilot / agency login)
# cannot open a browser: the container is not WSL, so it has no cmd.exe /
# wslview / WSL interop and no way to reach the Windows default browser.
#
# This sets up a tiny relay:
#   container side  -> a BROWSER shim (appgw-winbrowser) that sends the URL over
#                      TCP to the WSL host.
#   host side       -> a listener (systemd --user service) that receives the URL
#                      and opens it in the Windows browser via wslview.
#
# The shim + token are written to a shared dir that docker-compose.yml /
# devcontainer.json bind-mount (read-only) into the container as
# /opt/appgw-devbridge, with BROWSER=/opt/appgw-devbridge/appgw-winbrowser, so
# future setups keep working with no manual steps.
#
# Safe to run anywhere: inside a container (or non-WSL) it only writes the shim
# and skips the host listener. Best-effort; never fails the parent install.

BRIDGE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/appgw-devbridge"
PORT="${APPGW_URL_OPENER_PORT:-8099}"
mkdir -p "$BRIDGE_DIR" 2>/dev/null || true

# Shared secret so only holders of this token (delivered to the container via the
# read-only bind mount) can ask the host to open a browser. Generated once; never
# rotated here (a running listener caches it at startup) and never committed.
TOKEN_FILE="$BRIDGE_DIR/token"
if [ ! -s "$TOKEN_FILE" ]; then
  (umask 077; head -c 24 /dev/urandom | base64 | tr -d '\n=+/' > "$TOKEN_FILE") 2>/dev/null || true
  chmod 600 "$TOKEN_FILE" 2>/dev/null || true
fi

# --- container-side BROWSER shim (mounted into the container) ---------------
cat > "$BRIDGE_DIR/appgw-winbrowser" <<'SHIM'
#!/bin/sh
# appgw-winbrowser: forward a URL to the WSL-host opener, which pops the Windows
# browser. Installed as $BROWSER inside the appgw container. Falls back to
# printing the URL if the host listener is unreachable.
#
# Wire format is two lines: a shared token (read from the token file next to this
# shim, delivered via the read-only mount) then the URL. The host listener drops
# any payload whose token does not match, so a stray container cannot pop URLs.
PATH="$PATH:/usr/sbin:/sbin"
url="$1"
case "$url" in
  http://*|https://*) : ;;
  *) exit 0 ;;
esac
port="${APPGW_URL_OPENER_PORT:-8099}"
tok=$(cat "$(dirname "$0")/token" 2>/dev/null)
if [ -z "$tok" ]; then
  echo "appgw-winbrowser: no bridge token next to the shim; is /opt/appgw-devbridge mounted? Open this URL manually:" >&2
  echo "$url" >&2
  exit 1
fi
send() { printf '%s\n%s\n' "$tok" "$url" | nc -w2 "$1" "$port" 2>/dev/null && exit 0; }
# Prefer an explicit host (set for host-network services), then the docker bridge
# default gateway (the WSL host), then loopback, then the default docker bridge.
[ -n "$APPGW_URL_OPENER_HOST" ] && send "$APPGW_URL_OPENER_HOST"
gw=$(ip -4 route show default 2>/dev/null | awk '{print $3; exit}')
[ -n "$gw" ] && send "$gw"
send 127.0.0.1
send host.docker.internal
send 172.17.0.1
echo "appgw-winbrowser: host opener unreachable on :$port. Open this URL manually:" >&2
echo "$url" >&2
exit 1
SHIM
chmod +x "$BRIDGE_DIR/appgw-winbrowser" 2>/dev/null || true

# --- host listener is WSL-only; skip inside containers / non-WSL -------------
if [ -f /.dockerenv ] || ! command -v wslview >/dev/null 2>&1; then
  echo "appgw-devbridge: shim written to $BRIDGE_DIR/appgw-winbrowser (host listener skipped: not a WSL host)."
  exit 0
fi

# Pre-create the credential dirs as the current user so the container's bind
# mounts don't get auto-created root-owned by dockerd.
mkdir -p "$HOME/.azure" "$HOME/.copilot" "$HOME/.config/gh" 2>/dev/null || true

# --- host-side URL opener ----------------------------------------------------
cat > "$BRIDGE_DIR/url-opener.py" <<'PY'
#!/usr/bin/env python3
"""AppGw dev bridge: receive a token+URL over TCP and open it in the Windows browser.

Wire format is two lines: a shared token then an http/https URL. Payloads whose
token does not match the token file (fail-closed if absent) are dropped, so only
the bridged container - not any other local process - can pop the browser.
"""
import hmac, os, shutil, socket, subprocess, sys

PORT = int(os.environ.get("APPGW_URL_OPENER_PORT", "8099"))
TOKEN_FILE = os.environ.get(
    "APPGW_URL_OPENER_TOKEN_FILE",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "token"),
)
try:
    with open(TOKEN_FILE, "r", encoding="utf-8") as fh:
        EXPECTED = fh.read().strip()
except OSError:
    EXPECTED = ""
if not EXPECTED:
    print(f"appgw-url-opener: no token in {TOKEN_FILE}; refusing to start (fail-closed)", file=sys.stderr)
    sys.exit(1)

opener = shutil.which("wslview") or shutil.which("xdg-open") or shutil.which("sensible-browser")
if not opener:
    print("appgw-url-opener: no wslview/xdg-open found", file=sys.stderr)
    sys.exit(1)

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("0.0.0.0", PORT))
srv.listen(16)
print(f"appgw-url-opener listening on 0.0.0.0:{PORT} via {opener}", flush=True)

while True:
    try:
        conn, addr = srv.accept()
    except KeyboardInterrupt:
        break
    with conn:
        # TCP is a byte stream: read (bounded, timeout-guarded so a silent client
        # can't hang this single-threaded server) until we have both lines or EOF.
        conn.settimeout(2.0)
        data = b""
        try:
            while len(data) < 65536:
                chunk = conn.recv(4096)
                if not chunk:
                    break
                data += chunk
                if data.count(b"\n") >= 2:
                    break
        except OSError:
            pass
    if not data:
        continue
    lines = data.decode("utf-8", "replace").splitlines()
    token = lines[0].strip() if lines else ""
    url = lines[1].strip() if len(lines) > 1 else ""
    if not hmac.compare_digest(token, EXPECTED):
        print(f"rejected payload (bad token) from {addr[0]}", file=sys.stderr, flush=True)
        continue
    # Only ever hand http/https URLs to the opener, as a single argv element.
    if url.startswith("http://") or url.startswith("https://"):
        try:
            subprocess.Popen([opener, url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"opened: {url}", flush=True)
        except Exception as e:  # noqa: BLE001 - best effort, keep serving
            print(f"failed to open {url}: {e}", file=sys.stderr, flush=True)
    else:
        print(f"ignored non-URL payload from {addr[0]}", file=sys.stderr, flush=True)
PY

# --- run it: prefer a systemd --user service, else a background fallback ------
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/appgw-url-opener.service" <<UNIT
[Unit]
Description=AppGw dev bridge - open container URLs in the Windows browser
After=default.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $BRIDGE_DIR/url-opener.py
Environment=APPGW_URL_OPENER_PORT=$PORT
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
UNIT
  # Keep the listener alive across login sessions (best effort; needs sudo).
  sudo -n loginctl enable-linger "$USER" >/dev/null 2>&1 || true
  systemctl --user daemon-reload >/dev/null 2>&1 || true
  if systemctl --user enable --now appgw-url-opener.service >/dev/null 2>&1; then
    echo "appgw-devbridge: host listener enabled on :$PORT (systemd --user)."
  else
    echo "appgw-devbridge: could not enable systemd --user service; see 'systemctl --user status appgw-url-opener'." >&2
  fi
else
  # No usable systemd --user: launch in the background if nothing is listening.
  if ! (exec 3<>"/dev/tcp/127.0.0.1/$PORT") 2>/dev/null; then
    APPGW_URL_OPENER_PORT="$PORT" setsid nohup /usr/bin/python3 "$BRIDGE_DIR/url-opener.py" \
      >"$BRIDGE_DIR/url-opener.log" 2>&1 &
    echo "appgw-devbridge: host listener started in background on :$PORT (no systemd --user)."
  else
    echo "appgw-devbridge: host listener already running on :$PORT."
  fi
fi

exit 0
