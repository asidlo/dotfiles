#!/bin/bash

set -e -o pipefail

# Get current script location
DOTFILES_DIR=$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-$0}")")")
DOTNET_INSTALL_DIR="${DOTNET_INSTALL_DIR:-$HOME/.dotnet}"

mkdir -p ~/.omnisharp
ln -sfv "$DOTFILES_DIR/misc/omnisharp.json" ~/.omnisharp/omnisharp.json

# Detect OS and install latest LTS .NET SDK using system package manager
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

case "$OS_ID" in
mariner | azurelinux)
    echo "Detected $OS_ID. Installing latest LTS .NET SDK via tdnf..."
    # makecache, not update: tdnf's `update` upgrades every installed package (it is
    # apt's `upgrade`, not apt's `update`). See scripts/dependencies.sh. The
    # `tdnf list available` below only needs fresh metadata.
    sudo tdnf makecache
    latest_sdk=$(tdnf list available dotnet-sdk* 2>/dev/null | awk '/dotnet-sdk-[0-9]+\.[0-9]+/ {print $1}' | sort -V | tail -n1)
    if [ -n "$latest_sdk" ]; then
        sudo tdnf install -y "$latest_sdk"
    else
        echo "Could not determine latest dotnet-sdk version for tdnf."
    fi
    ;;
ubuntu)
    echo "Detected Ubuntu. Installing latest LTS .NET SDK via apt..."
    # Add Microsoft package repository if not already present
    if ! grep -q "packages.microsoft.com" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        wget "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
    fi
    sudo apt-get update
    latest_sdk=$(apt-cache search dotnet-sdk- | awk '{print $1}' | grep -E '^dotnet-sdk-[0-9]+\.[0-9]+$' | sort -V | tail -n1)
    if [ -n "$latest_sdk" ]; then
        sudo apt-get install -y "$latest_sdk"
    else
        echo "Could not determine latest dotnet-sdk version for apt."
    fi
    ;;
*)
    echo "Unsupported OS: $OS_ID. Falling back to dotnet-install.sh script."
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel LTS --install-dir "$DOTNET_INSTALL_DIR"
    ;;
esac

# Install asidlo/devcontainer-credprovider (user install, recommended for WSL/local dev)
if command -v gh >/dev/null 2>&1 || command -v curl >/dev/null 2>&1; then
    echo "Installing asidlo/devcontainer-credprovider..."
    tmp_dir=$(mktemp -d)
    archive="$tmp_dir/devcontainer-credprovider.tar.gz"
    download_status=1

    if command -v gh >/dev/null 2>&1; then
        if gh release download -R asidlo/devcontainer-credprovider -p "*.tar.gz" -D "$tmp_dir"; then
            download_status=0
        else
            download_status=$?
            echo "GitHub CLI download failed; retrying the public release over HTTPS..." >&2
        fi
    fi

    if [ "$download_status" -ne 0 ] && command -v curl >/dev/null 2>&1; then
        if curl -fsSL \
            "https://github.com/asidlo/devcontainer-credprovider/releases/latest/download/devcontainer-credprovider.tar.gz" \
            -o "$archive"; then
            download_status=0
        else
            download_status=$?
        fi
    fi

    install_status=$download_status
    if [ "$download_status" -eq 0 ]; then
        # SKIP_XDG_OPEN: the installer's step 4 writes its own xdg-open shim to
        # /usr/local/bin, which a non-root user cannot do. Its `set -e` turns
        # that "Permission denied" into a hard failure *after* the credential
        # provider is already installed, so the whole script reported FAILED
        # over a browser helper it only needs at sign-in time. Link ours into
        # ~/.local/bin instead -- same job, no sudo, and it reaches the VS Code
        # client's browser on a display-less remote.
        mkdir -p "$HOME/.local/bin" &&
            ln -sfn "$DOTFILES_DIR/bin/xdg-open" "$HOME/.local/bin/xdg-open" ||
            echo "Warning: could not link xdg-open into ~/.local/bin; browser sign-in may fall back to device code." >&2

        if mkdir -p "$tmp_dir/cred-provider" &&
            tar xzf "$archive" -C "$tmp_dir/cred-provider" &&
            SKIP_ARTIFACTS_CREDPROVIDER=true SKIP_XDG_OPEN=true \
                "$tmp_dir/cred-provider/install.sh" --user </dev/null; then
            echo "devcontainer-credprovider installed successfully."
            # Invalidate NuGet's plugin cache. NuGet caches each plugin's
            # operation claims under $XDG_DATA_HOME/NuGet/plugin-cache, keyed by
            # plugin path. A cache baked before this provider existed -- e.g.
            # inside a container image that only shipped CredentialProvider.Microsoft
            # -- makes NuGet trust the stale claims and never launch the provider
            # we just installed. Restores then fail with 401/NU1301 and no plugin
            # log at all, which looks exactly like the provider was never installed.
            # `plugins-cache` is undocumented in `dotnet nuget locals --help`
            # (which lists only all|http-cache|global-packages|temp) but works;
            # fall back to removing the directory so this cannot silently no-op.
            dotnet nuget locals plugins-cache --clear >/dev/null 2>&1 ||
                rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/NuGet/plugin-cache" ||
                echo "Warning: could not clear NuGet plugin cache; run 'dotnet nuget locals all --clear' if restores 401." >&2
            install_status=0
        else
            install_status=$?
        fi
    fi

    rm -rf "$tmp_dir"

    if [ "$install_status" -ne 0 ]; then
        echo "Failed to install devcontainer-credprovider." >&2
        exit "$install_status"
    fi
else
    echo "Neither GitHub CLI (gh) nor curl was found; cannot install devcontainer-credprovider." >&2
    exit 1
fi
