#!/bin/bash

# Installs asidlo/devcontainer-credprovider: the silent NuGet credential provider
# (DefaultAzureCredential over ~/.azure). This is deliberately the *only*
# credential provider dotfiles installs, and it is installed in every
# environment -- minimal and full alike.
#
# Do not also install Microsoft's artifacts-credprovider
# (scripts/artifacts-credprovider.sh, kept for manual use only). With both
# present NuGet queries Microsoft's provider first, and whenever its
# session-token cache under ~/.local/share/MicrosoftCredentialProvider is cold
# -- e.g. a freshly recreated container, since that path is not a volume --
# `dotnet restore --interactive` prints a DeviceFlow code and stalls ~87s per
# restore before giving up and falling through to this provider. There is no
# way to suppress that: the shipped provider honours only
# ARTIFACTS_CREDENTIALPROVIDER_{ACCESSTOKEN,FEED_ENDPOINTS,EXTERNAL_FEED_ENDPOINTS,URI_PREFIXES}
# and NUGET_CERT_REVOCATION_MODE -- NUGET_CREDENTIALPROVIDER_FORCE_CANSHOWDIALOG_TO
# is absent from the binary and is a measured no-op.

set -e -o pipefail

DOTFILES_DIR=$(dirname "$(dirname "$(realpath "${BASH_SOURCE:-$0}")")")

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
            # Remove Microsoft's provider if a previous install.sh (or the
            # devcontainer image) left it behind. Leaving it is the whole bug:
            # NuGet queries it first and stalls on DeviceFlow. Only ever done
            # once the silent provider above is confirmed installed, so this
            # cannot leave the machine with no provider at all. Re-add it by
            # hand with scripts/artifacts-credprovider.sh if you really need it.
            ms_provider="$HOME/.nuget/plugins/netcore/CredentialProvider.Microsoft"
            if [ -d "$ms_provider" ]; then
                echo "Removing conflicting CredentialProvider.Microsoft (see scripts/artifacts-credprovider.sh to restore it)."
                rm -rf "$ms_provider" ||
                    echo "Warning: could not remove $ms_provider; restores may stall on a DeviceFlow prompt." >&2
            fi
            # Invalidate NuGet's plugin cache. NuGet caches each plugin's
            # operation claims under $XDG_DATA_HOME/NuGet/plugin-cache, keyed by
            # plugin path. A cache written before this provider existed -- e.g.
            # by an earlier install that only had CredentialProvider.Microsoft
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
