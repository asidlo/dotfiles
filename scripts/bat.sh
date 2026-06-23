#!/bin/bash
# bat: a cat clone with syntax highlighting: https://github.com/sharkdp/bat
# Be additive: never clobber an existing bat/batcat, and make sure BOTH command
# names resolve to a working binary.
#
# Naming background:
#   - apt's `bat` package installs the binary as `batcat` (renamed to avoid a
#     clash with bacula's `bat`); sharkdp's upstream .deb installs it as `bat`.
#   - comfort-shell installs apt's `bat` and adds a `~/bin/bat` shim that execs
#     `batcat`; zsh/zshrc.min aliases `bat=batcat`, while bash/bashrc invokes
#     `bat` directly, so both names need to work.
# Reinstalling sharkdp's .deb would clobber /usr/bin/batcat and break the shim,
# so instead we bridge whichever name is missing with a symlink into ~/.local/bin
# (which both zsh/zshrc.min and bash/bashrc add to PATH).

# Locate a *real* bat binary (sharkdp `bat` or apt `batcat`), skipping any
# wrapper script (e.g. the comfort-shell `~/bin/bat` shim) that execs `batcat`
# -- linking `batcat` back to such a wrapper would create an infinite loop.
# Real bat/batcat are ELF binaries, so we accept anything starting with the ELF
# magic outright (never grep a binary -- its help text mentions "batcat" and
# would false-match). A non-ELF executable is a script/wrapper: skip it only if
# it routes through `batcat` (loop risk); otherwise it wraps a real bat, so keep.
find_real_bat() {
  local p magic
  while IFS= read -r p; do
    [ -x "$p" ] || continue
    magic=$(LC_ALL=C head -c 4 "$p" 2>/dev/null)
    if [ "$magic" = $'\x7fELF' ]; then
      printf '%s\n' "$p"
      return 0
    fi
    grep -q batcat "$p" 2>/dev/null && continue
    printf '%s\n' "$p"
    return 0
  done < <(type -aP bat batcat 2>/dev/null)
  return 1
}

if real_bat="$(find_real_bat)"; then
  mkdir -p ~/.local/bin
  command -v batcat >/dev/null 2>&1 || ln -sfv "$real_bat" ~/.local/bin/batcat
  command -v bat    >/dev/null 2>&1 || ln -sfv "$real_bat" ~/.local/bin/bat
  exit 0
fi

if [ -z "$BAT_VERSION" ]; then
  BAT_VERSION="$(curl -s -I https://github.com/sharkdp/bat/releases/latest | awk -F '/' '/^location/ {print  substr($NF, 1, length($NF)-1)}' | sed 's/^v//')"
fi

source /etc/os-release

case "$ID" in
"mariner" | "azurelinux")
  SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE:-$0}")")
  "$SCRIPT_DIR/rust.sh"
  ~/.cargo/bin/cargo install bat --version "$BAT_VERSION"
  ;;
"ubuntu" | "debian")
  ARCH=$(dpkg --print-architecture)
  curl -L https://github.com/sharkdp/bat/releases/download/v"$BAT_VERSION"/bat_"$BAT_VERSION"_"$ARCH".deb -o /tmp/bat.deb
  sudo apt-get install -y /tmp/bat.deb
  rm /tmp/bat.deb
  ;;
*)
  echo "Unsupported OS: $ID"
  exit 1
  ;;
esac
