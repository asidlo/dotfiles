#!/bin/bash

source /etc/os-release

mkdir -p ~/.local/{src,bin}

case "$ID" in
ubuntu)
    sudo apt-get update -y
    sudo apt-get install build-essential tmux wget curl zip unzip python3 python3-pip python3-venv -y
    ;;
mariner | azurelinux)
    # makecache, not update: tdnf's `update` is apt's `upgrade` -- it upgrades every
    # installed package, not just the metadata. The image ships bpftool-hwe, so
    # `tdnf update -y` dragged a whole new kernel-hwe (~61MB) plus kernel-hwe-devel
    # in on every run, for ~3min of rpm transactions nothing here asked for.
    # makecache is the real equivalent of the apt-get update above.
    sudo tdnf makecache
    sudo tdnf install build-essential tmux wget curl zip unzip python3 python3-pip -y
    # /etc/profile.d/debuginfod.sh globs /etc/debuginfod/*.urls, a directory this
    # image does not ship. /etc/zprofile sources profile.d in native zsh mode, where
    # an unmatched glob is a hard error -- and the script's `2>/dev/null` guards
    # cat's stderr, not the shell's, so it cannot suppress it. Every zsh login shell
    # prints "no matches found". An empty .urls file makes the glob match and leaves
    # DEBUGINFOD_URLS unset, which is exactly what the script intends.
    sudo mkdir -p /etc/debuginfod
    [ -e /etc/debuginfod/00-empty.urls ] || sudo touch /etc/debuginfod/00-empty.urls
    ;;
*)
    echo "Unsupported distribution: $ID"
    exit 1
    ;;
esac
