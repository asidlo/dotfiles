#!/bin/bash
# Smarter cd that learns your habits: https://github.com/ajeetdsouza/zoxide
command -v zoxide >/dev/null 2>&1 && exit 0

mkdir -p ~/.local/bin

# The official installer downloads a prebuilt binary and works on every distro,
# Azure Linux included. It used to be bypassed there in favour of building from
# source with `cargo install`, but that needs a working rustc -- which segfaults
# on start-up in emulated environments (its bundled jemalloc assumes userspace
# pointers are 48-bit clean, and faults on its first allocation when they are
# not). There was never a reason to compile this one; --bin-dir keeps the binary
# on the ~/.local/bin we already PATH.
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir ~/.local/bin
