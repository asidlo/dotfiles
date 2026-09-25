#!/bin/bash

set -e -o pipefail

# Get current working directory
DOTFILES_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
SCRIPT_DIR="$DOTFILES_DIR/scripts"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="$STATE_DIR/install-$(date +%Y%m%d-%H%M%S).log"
STEP_LOG_DIR="$STATE_DIR/install-steps-$(date +%Y%m%d-%H%M%S)"

if [ -t 1 ]; then
  USE_COLOR=1
else
  USE_COLOR=0
fi

mkdir -p "$STATE_DIR" "$STEP_LOG_DIR"

# ---------------------------------------------------------------------------
# sudo: authorise once, up front -- and BEFORE stdout/stderr are piped to tee.
#
# Nearly every tool script below calls sudo. With no cached credential and no
# TTY to prompt on (an unattended run, CI, or `wsl.exe -- bash install.sh`), the
# first one blocks forever on a password prompt nobody can answer -- a hang that
# is far worse than a failure. Resolve it here: fail fast with instructions, and
# otherwise keep the timestamp warm so nothing re-prompts mid-run.
#
# This block must stay above the `exec > >(tee ...)` line. tee buffers, so with
# stderr redirected into it the "[sudo] password for ..." prompt never reaches
# the screen and sudo just sits there until it times out. The prompt is also
# pinned to /dev/tty so a future reordering cannot silently reintroduce that.
#
# `-e /dev/tty` is NOT sufficient to decide we can prompt: /dev/tty is always
# present as a device node inside WSL, even when the process has no controlling
# terminal. Opening it is the real test. Requiring a controlling terminal also
# keeps the warm-up meaningful -- sudo's default timestamp_type=tty degrades to
# `ppid` without one, so the credential would not survive into the per-tool
# scripts run_step spawns and each of them would prompt again.
# ---------------------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  echo "sudo: running as root, not required"
elif ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: not running as root and sudo is not installed." >&2
  exit 1
elif sudo -n true 2>/dev/null; then
  echo "sudo: already authorised (passwordless or cached)"
elif [ -t 0 ] && (exec 3<>/dev/tty) 2>/dev/null; then
  # Announce on the terminal itself, not stdout: install.ps1 captures stdout
  # through a pipeline, where this notice can sit buffered while sudo waits.
  echo "sudo: authenticating once so the installs below don't prompt repeatedly" >/dev/tty || true

  # Bound the wait. sudo's own passwd_timeout is five minutes, long enough that
  # an unnoticed prompt looks like a hung install rather than a failed one.
  #
  # --foreground is load-bearing, not decoration. Without it `timeout` calls
  # setpgid(0,0) and runs sudo in a NEW process group, which is by definition
  # not the terminal's foreground group. sudo then reads /dev/tty, the kernel
  # raises SIGTTIN, and sudo is *stopped* -- the prompt is printed (writes are
  # allowed) but no password is ever collected, so the install appears to hang
  # forever. Measured: `timeout` alone put the child in pgid 1117 against the
  # shell's 320; `timeout --foreground` kept it in 320.
  #
  # Probe --foreground rather than assuming it: BusyBox timeout has no such
  # flag, and passing it there would turn a working prompt into a hard failure.
  # Falling back to a bare `sudo -v` merely gives up the bound, which is the
  # lesser evil -- sudo still enforces its own passwd_timeout.
  sudo_auth=(sudo -v)
  if command -v timeout >/dev/null 2>&1 && timeout --foreground 5 true >/dev/null 2>&1; then
    sudo_auth=(timeout --foreground 120 sudo -v)
  fi

  # `|| rc=$?` rather than `if ! ...`: it keeps the real exit code (124 means
  # timeout gave up) and stops `set -e` from killing the script first.
  rc=0
  SUDO_PROMPT='[sudo] password for %p (dotfiles install.sh): ' \
    "${sudo_auth[@]}" </dev/tty >/dev/tty 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then
    if [ "$rc" -eq 124 ]; then
      echo "ERROR: sudo password prompt went unanswered for 120s." >&2
    else
      echo "ERROR: sudo authentication failed." >&2
    fi
    exit 1
  fi
else
  cat >&2 <<EOF
ERROR: sudo needs a password, but this run has no terminal to prompt on.

       install.ps1 normally handles this for you: Phase 6 installs a temporary
       /etc/sudoers.d/99-dotfiles-install and removes it again afterwards. If
       you are here, that step was skipped or failed.

       Re-run install.sh from an interactive shell:
           wsl -d <distro> -u $(whoami)
           cd $DOTFILES_DIR && bash ./install.sh

       ...or grant passwordless sudo first:
           echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami)
EOF
  exit 1
fi

exec > >(tee -a "$LOG_FILE") 2>&1
echo "Logging install output to $LOG_FILE"

STEP_NAMES=()
STEP_CODES=()
STEP_TAILS=()

color() {
  if [ "$USE_COLOR" -eq 1 ]; then
    printf '\033[%sm%s\033[0m' "$1" "$2"
  else
    printf '%s' "$2"
  fi
}

run_step() {
  local script="$1"
  local name
  local code
  local step_log
  local tail_output

  name=$(basename "$script")
  step_log="$STEP_LOG_DIR/${#STEP_NAMES[@]}-$name.log"

  echo
  printf '▶ [%s]\n' "$name"

  # </dev/null, always. A step that reads stdin has no one to answer it here,
  # and the prompt is usually invisible: stdout is piped through tee, so the
  # question can sit in a buffer while the install looks frozen. scripts/
  # copilot.sh hit exactly this -- VS Code's `copilot` shim asked "Install
  # GitHub Copilot CLI? ['y/N']" and the run stalled until someone guessed to
  # press Enter. At EOF that same prompt fails immediately, which is loud,
  # recorded in the step log, and recoverable. sudo is unaffected: it was
  # authorised above and reads from /dev/tty regardless.
  set +e
  "$@" </dev/null 2>&1 | tee "$step_log"
  code=${PIPESTATUS[0]}
  set -e

  tail_output=$(tail -n 20 "$step_log" 2>/dev/null || true)
  STEP_NAMES+=("$name")
  STEP_CODES+=("$code")
  STEP_TAILS+=("$tail_output")

  return 0
}

print_summary() {
  local failed=0
  local total=${#STEP_NAMES[@]}
  local i
  local status

  echo
  echo "Install step summary"
  echo "===================="
  printf '%-32s %s\n' "Step" "Status"
  printf '%-32s %s\n' "----" "------"

  for i in "${!STEP_NAMES[@]}"; do
    if [ "${STEP_CODES[$i]}" -eq 0 ]; then
      status="$(color 32 OK)"
    else
      status="$(color 31 "FAILED (exit ${STEP_CODES[$i]})")"
      failed=$((failed + 1))
    fi
    printf '%-32s %b\n' "${STEP_NAMES[$i]}" "$status"
  done

  if [ "$failed" -gt 0 ]; then
    echo
    echo "Failure output tails"
    echo "===================="
    for i in "${!STEP_NAMES[@]}"; do
      if [ "${STEP_CODES[$i]}" -ne 0 ]; then
        printf '\n[%s] FAILED (exit %s)\n' "${STEP_NAMES[$i]}" "${STEP_CODES[$i]}"
        if [ -n "${STEP_TAILS[$i]}" ]; then
          printf '%s\n' "${STEP_TAILS[$i]}" | sed 's/^/  /'
        else
          echo "  (no output captured)"
        fi
      fi
    done
  fi

  echo
  echo "Log written to $LOG_FILE"
  echo "$failed of $total steps failed"

  if [ "$failed" -gt 0 ]; then
    exit 1
  fi

  exit 0
}

source /etc/os-release

# Bootstrap sudo itself (root containers on Azure Linux ship without it), then
# keep the credential warm for the long-running installs below.
"$SCRIPT_DIR/ensure-sudo.sh"

if [ "$(id -u)" -ne 0 ]; then
  # sudo forgets after ~15 minutes; some steps (dotnet, rust, nvim) run longer.
  while true; do
    sudo -n true 2>/dev/null || exit 0
    sleep 60
  done &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
fi

# Only update locale if os is ubuntu or debian
if [ "$ID" == "ubuntu" ] || [ "$ID" == "debian" ]; then
  sudo locale-gen "en_US.UTF-8"
fi

# Detect minimal/container environments (codespaces, devcontainers) once so the
# gitconfig choice and the "full install" gate below stay in sync.
if [ -n "$CODESPACES" ] || [ -n "$DEVCONTAINER" ] || [ -n "$DEV_CONTAINER" ] || [ -d "/.devcontainer" ] || [ -d "/workspaces" ]; then
  MINIMAL_ENV=1
else
  MINIMAL_ENV=0
fi

# ---------------------------------------------------------------------------
# Symlinks first. Configs are the core of the dotfiles, so link them before the
# best-effort, network/sudo-heavy tool installs below. That way a tool script
# that fails, blocks, or replaces the shell can never leave configs unlinked.
#
# Every link uses `ln -sfn`, never plain `ln -sf`. Without -n (--no-dereference)
# a destination that is already a symlink *to a directory* is followed, so ln
# creates the new link INSIDE the old target and leaves the original pointing
# where it always did. Re-running this script then silently kept ~/.config/nvim
# and ~/.config/git/keys aimed at the previous checkout while depositing stray
# nvim/lazynvim/lazynvim and git/keys/keys links in the repo. With -n the
# symlink itself is replaced, and a *real* directory in the way fails loudly
# instead of being quietly descended into.
# ---------------------------------------------------------------------------

# Select gitconfig based on environment
if [ "$MINIMAL_ENV" -eq 1 ]; then
  ln -sfnv "$DOTFILES_DIR/git/gitconfig.work.codespaces" ~/.gitconfig
elif grep -qi 'microsoft\|wsl' /proc/version 2>/dev/null; then
  ln -sfnv "$DOTFILES_DIR/git/gitconfig.work" ~/.gitconfig
  # gitconfig.work's credential helper points here; the shim resolves the
  # arch-correct Git for Windows credential manager (clangarm64 vs mingw64).
  mkdir -p ~/.local/bin
  ln -sfnv "$DOTFILES_DIR/bin/git-credential-manager-wsl" ~/.local/bin/git-credential-manager-wsl
else
  ln -sfnv "$DOTFILES_DIR/git/gitconfig.work.wavespaces" ~/.gitconfig
  # gitconfig.work.wavespaces' credential helper points here; the shim lets GCM
  # run its browser sign-in against the VS Code client instead of device code.
  mkdir -p ~/.local/bin
  ln -sfnv "$DOTFILES_DIR/bin/git-credential-manager-remote" ~/.local/bin/git-credential-manager-remote
fi
mkdir -p ~/.ssh && ln -sfnv "$DOTFILES_DIR/git/config" ~/.ssh/config
mkdir -p ~/.config/git && ln -sfnv "$DOTFILES_DIR/git/keys" ~/.config/git/keys
mkdir -p ~/.config/lazygit && ln -sfnv "$DOTFILES_DIR/git/lazygit.config" ~/.config/lazygit/config.yml
ln -sfnv "$DOTFILES_DIR/vim/minimal.vim" ~/.vimrc
ln -sfnv "$DOTFILES_DIR/zsh/zshrc.min" ~/.zshrc
ln -sfnv "$DOTFILES_DIR/zsh/zshenv" ~/.zshenv
ln -sfnv "$DOTFILES_DIR/bash/bashrc" ~/.bashrc

# Portable CLI shims (clipboard + open) -> ~/.local/bin (already on PATH).
# Self-sufficient on WSL, Wayland, X11, or remote SSH (OSC52) without comfort-shell.
# xdg-open is here for the auth flows rather than for us: the NuGet credential
# providers and GCM both look it up by name, and Azure Linux has no xdg-utils.
mkdir -p ~/.local/bin
for shim in pbcopy pbpaste open xdg-open; do
  ln -sfnv "$DOTFILES_DIR/bin/$shim" ~/.local/bin/"$shim"
done

# ...and shadow comfort-shell's copies in ~/bin, which outranks ~/.local/bin.
#
# comfort-shell (vendor/WindowsDeveloperConfig/wsl-comfort) prepends ~/bin to
# PATH from its managed ~/.zprofile block and drops its own open/xdg-open there,
# so ours never win the lookup no matter what BROWSER points at. Theirs hands
# the URL to `cmd.exe /c start`, where an unquoted & is a command separator:
# WSL interop does not quote it, so cmd truncates an OAuth authorize URL at the
# first parameter. The browser then gets ?client_id=... with no scope, and Entra
# refuses the sign-in with "AADSTS900144: The request body must contain the
# following parameter: 'scope'" -- which is what broke `az login`.
# bin/open prefers wslview (powershell.exe), which preserves the query string.
#
# Only take over a name that is genuinely free, already ours, or comfort-shell's.
# Anything else -- a hand-written script, or a symlink pointing somewhere we do
# not own (including a dangling one, which is still somebody's deliberate
# choice) -- is left alone and reported, since silently clobbering it would be
# worse than losing the PATH race. Note this only shadows comfort-shell;
# re-running its bootstrap will overwrite ~/bin again, and re-running this
# script is the way back.
if [ -d ~/bin ]; then
  for shim in pbcopy pbpaste open xdg-open; do
    shim_src="$DOTFILES_DIR/bin/$shim"
    shim_dest=~/bin/"$shim"
    if { [ ! -e "$shim_dest" ] && [ ! -L "$shim_dest" ]; } ||
      [ "$(readlink -f "$shim_dest" 2>/dev/null)" = "$(readlink -f "$shim_src")" ] ||
      grep -qs 'comfort-shell shim' "$shim_dest"; then
      ln -sfnv "$shim_src" "$shim_dest"
    else
      echo "skipping ~/bin/$shim: not ours and not a comfort-shell shim" >&2
    fi
  done
  unset shim_src shim_dest
fi

mkdir -p ~/.config && ln -sfnv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml

# Docker CLI presentation defaults are MERGED, never symlinked. `docker login`
# writes registry credentials into the same ~/.docker/config.json, and this repo
# is public, so a symlink here would publish them on the next login. The helper
# copies only the keys docker/config.json declares and leaves any existing
# "auths"/"credsStore" exactly as found.
# Never fatal: this is cosmetic CLI formatting, and the helper exits non-zero on
# purpose when ~/.docker/config.json is unparseable. Under `set -e` at top level
# that would abort the install before print_summary runs, so a broken Docker
# config would silently cost you the whole step report.
if command -v python3 >/dev/null 2>&1; then
  "$DOTFILES_DIR/bin/docker-config-merge" "$DOTFILES_DIR/docker/config.json" ||
    echo "docker-config-merge: failed (exit $?), leaving ~/.docker/config.json untouched" >&2
else
  echo "docker-config-merge: python3 not found, skipping ~/.docker/config.json"
fi

# Full-environment-only configs (paired with the tools installed below).
if [ "$MINIMAL_ENV" -eq 0 ]; then
  ln -sfnv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf
  mkdir -p ~/.config && ln -sfnv "$DOTFILES_DIR/nvim/lazynvim" ~/.config/nvim
fi

# ---------------------------------------------------------------------------
# Tool installs (best-effort; may require network or sudo).
# ---------------------------------------------------------------------------
# First: re-expose cmd.exe/clip.exe/etc and the Windows VS Code launcher, which etc/wsl.conf's
# appendWindowsPath=false removes from $PATH. agency.sh below shells out to
# cmd.exe and fails its sign-in without them.
run_step "$SCRIPT_DIR/wsl-interop-shims.sh"
run_step "$SCRIPT_DIR/dependencies.sh"
run_step "$SCRIPT_DIR/fd.sh"
run_step "$SCRIPT_DIR/fzf.sh"
run_step "$SCRIPT_DIR/bat.sh"
run_step "$SCRIPT_DIR/rg.sh"
run_step "$SCRIPT_DIR/zoxide.sh"
run_step "$SCRIPT_DIR/direnv.sh"
run_step "$SCRIPT_DIR/eza.sh"
run_step "$SCRIPT_DIR/btop.sh"
run_step "$SCRIPT_DIR/starship.sh"
run_step "$SCRIPT_DIR/zsh.sh"
run_step "$SCRIPT_DIR/gh.sh"
# Every environment gets exactly one NuGet credential provider, the silent one.
# Microsoft's artifacts-credprovider is deliberately NOT installed -- see the
# header of devcontainer-credprovider.sh. Runs after gh.sh (it downloads the
# release) and before az.sh, whose login the provider consumes at restore time.
run_step "$SCRIPT_DIR/devcontainer-credprovider.sh"
run_step "$SCRIPT_DIR/az.sh"
run_step "$SCRIPT_DIR/copilot.sh"
run_step "$SCRIPT_DIR/agency.sh"
# agency.sh installs wslview (wslu), which appgw-devbridge's host listener needs.
run_step "$SCRIPT_DIR/appgw-devbridge.sh"
run_step "$SCRIPT_DIR/npm.sh"

# If not running in codespaces or devcontainer, do full install
if [ "$MINIMAL_ENV" -eq 0 ]; then
  run_step "$SCRIPT_DIR/rust.sh"
  run_step "$SCRIPT_DIR/lazygit.sh"
  run_step "$SCRIPT_DIR/nvim.sh" -d ~/.local/bin
  run_step "$SCRIPT_DIR/clangd.sh"
  run_step "$SCRIPT_DIR/nvim-tools.sh"
  run_step "$SCRIPT_DIR/go.sh"
  run_step "$SCRIPT_DIR/npm.sh"
  run_step "$SCRIPT_DIR/dotnet.sh"
  run_step "$SCRIPT_DIR/tmux.sh"
fi

print_summary
