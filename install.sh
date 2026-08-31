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

  set +e
  "$@" 2>&1 | tee "$step_log"
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

# ---------------------------------------------------------------------------
# sudo: authorise once, up front.
#
# Nearly every tool script below calls sudo. With no cached credential and no
# TTY to prompt on (an unattended run, CI, or `wsl.exe -- bash install.sh`), the
# first one blocks forever on a password prompt nobody can answer -- a hang that
# is far worse than a failure. Resolve it here: fail fast with instructions, and
# otherwise keep the timestamp warm so nothing re-prompts mid-run.
# ---------------------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  echo "sudo: running as root, not required"
elif ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: not running as root and sudo is not installed." >&2
  exit 1
elif sudo -n true 2>/dev/null; then
  echo "sudo: already authorised (passwordless or cached)"
elif [ -t 0 ]; then
  echo "sudo: authenticating once so the installs below don't prompt repeatedly"
  if ! sudo -v; then
    echo "ERROR: sudo authentication failed." >&2
    exit 1
  fi
else
  cat >&2 <<EOF
ERROR: sudo needs a password, but this run has no terminal to prompt on.

       Re-run install.sh from an interactive shell:
           wsl -d <distro> -u $(whoami)
           cd $DOTFILES_DIR && bash ./install.sh

       ...or grant passwordless sudo first:
           echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$(whoami)
EOF
  exit 1
fi

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
# ---------------------------------------------------------------------------

# Select gitconfig based on environment
if [ "$MINIMAL_ENV" -eq 1 ]; then
  ln -sfv "$DOTFILES_DIR/git/gitconfig.work.codespaces" ~/.gitconfig
elif grep -qi 'microsoft\|wsl' /proc/version 2>/dev/null; then
  ln -sfv "$DOTFILES_DIR/git/gitconfig.work" ~/.gitconfig
  # gitconfig.work's credential helper points here; the shim resolves the
  # arch-correct Git for Windows credential manager (clangarm64 vs mingw64).
  mkdir -p ~/.local/bin
  ln -sfv "$DOTFILES_DIR/bin/git-credential-manager-wsl" ~/.local/bin/git-credential-manager-wsl
else
  ln -sfv "$DOTFILES_DIR/git/gitconfig.work.wavespaces" ~/.gitconfig
fi
mkdir -p ~/.ssh && ln -sfv "$DOTFILES_DIR/git/config" ~/.ssh/config
mkdir -p ~/.config/git && ln -sfv "$DOTFILES_DIR/git/keys" ~/.config/git/keys
mkdir -p ~/.config/lazygit && ln -svf "$DOTFILES_DIR/git/lazygit.config" ~/.config/lazygit/config.yml
ln -sfv "$DOTFILES_DIR/vim/minimal.vim" ~/.vimrc
ln -sfv "$DOTFILES_DIR/zsh/zshrc.min" ~/.zshrc
ln -sfv "$DOTFILES_DIR/zsh/zshenv" ~/.zshenv
ln -sfv "$DOTFILES_DIR/bash/bashrc" ~/.bashrc

# Portable CLI shims (clipboard + open) -> ~/.local/bin (already on PATH).
# Self-sufficient on WSL, Wayland, X11, or remote SSH (OSC52) without comfort-shell.
mkdir -p ~/.local/bin
for shim in pbcopy pbpaste open; do
  ln -sfv "$DOTFILES_DIR/bin/$shim" ~/.local/bin/"$shim"
done

mkdir -p ~/.config && ln -sfv "$DOTFILES_DIR/zsh/starship.toml" ~/.config/starship.toml

# Full-environment-only configs (paired with the tools installed below).
if [ "$MINIMAL_ENV" -eq 0 ]; then
  ln -sfv "$DOTFILES_DIR/misc/tmux.conf" ~/.tmux.conf
  mkdir -p ~/.config && ln -sfv "$DOTFILES_DIR/nvim/lazynvim" ~/.config/nvim
fi

# ---------------------------------------------------------------------------
# Tool installs (best-effort; may require network or sudo).
# ---------------------------------------------------------------------------
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
run_step "$SCRIPT_DIR/artifacts-credprovider.sh"
run_step "$SCRIPT_DIR/az.sh"
run_step "$SCRIPT_DIR/copilot.sh"
run_step "$SCRIPT_DIR/agency.sh"
run_step "$SCRIPT_DIR/npm.sh"

# If not running in codespaces or devcontainer, do full install
if [ "$MINIMAL_ENV" -eq 0 ]; then
  run_step "$SCRIPT_DIR/rust.sh"
  run_step "$SCRIPT_DIR/lazygit.sh"
  run_step "$SCRIPT_DIR/nvim.sh" -d ~/.local/bin
  run_step "$SCRIPT_DIR/go.sh"
  run_step "$SCRIPT_DIR/dotnet.sh"
  run_step "$SCRIPT_DIR/tmux.sh"
fi

print_summary
