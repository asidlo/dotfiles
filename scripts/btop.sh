#!/usr/bin/env bash
#
# Install the latest official btop static binary, or pin BTOP_VERSION=v1.4.7.
#
# Optional environment variables:
#   BTOP_VERSION  Release tag to install (default: latest)
#   PREFIX        Installation prefix (default: /usr/local)
#   GITHUB_TOKEN  GitHub token for authenticated API requests
#
# Resource monitor (htop-like): https://github.com/aristocratos/btop
set -euo pipefail

command -v btop >/dev/null 2>&1 && exit 0

readonly REPO="aristocratos/btop"
PREFIX="${PREFIX:-/usr/local}"

error() { printf 'Error: %s\n' "$*" >&2; }
info() { printf '%s\n' "$*"; }

for tool in curl python3 sha256sum tar install; do
    command -v "$tool" >/dev/null 2>&1 || {
        error "Required tool '$tool' was not found"
        exit 1
    }
done

case "$(uname -m)" in
    x86_64|amd64) asset_arch="x86_64-unknown-linux-musl" ;;
    aarch64|arm64) asset_arch="aarch64-unknown-linux-musl" ;;
    armv7l) asset_arch="armv7-unknown-linux-musleabi" ;;
    armv6l|arm) asset_arch="arm-unknown-linux-musleabi" ;;
    i386|i486|i586) asset_arch="i586-unknown-linux-musl" ;;
    i686) asset_arch="i686-unknown-linux-musl" ;;
    m68k) asset_arch="m68k-unknown-linux-musl" ;;
    mips64) asset_arch="mips64-unknown-linux-musl" ;;
    ppc64|powerpc64) asset_arch="powerpc64-unknown-linux-musl" ;;
    riscv64) asset_arch="riscv64-unknown-linux-musl" ;;
    s390x) asset_arch="s390x-ibm-linux-musl" ;;
    *) error "Unsupported architecture '$(uname -m)'"; exit 1 ;;
esac
readonly asset_name="btop-${asset_arch}.tar.gz"

curl_args=(--fail --silent --show-error --location --retry 3 --retry-all-errors)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(--header "Authorization: Bearer ${GITHUB_TOKEN}")
fi

if [[ -n "${BTOP_VERSION:-}" ]]; then
    [[ "$BTOP_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z]+)*$ ]] || {
        error "BTOP_VERSION must be a release tag such as v1.4.7"
        exit 1
    }
    api_url="https://api.github.com/repos/${REPO}/releases/tags/${BTOP_VERSION}"
else
    api_url="https://api.github.com/repos/${REPO}/releases/latest"
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

info "Resolving btop release metadata"
curl "${curl_args[@]}" "$api_url" -o "${workdir}/release.json"

readarray -t release_data < <(
    python3 - "$asset_name" "${workdir}/release.json" <<'PY'
import json
import re
import sys

asset_name, metadata_path = sys.argv[1:]
with open(metadata_path, encoding="utf-8") as metadata:
    release = json.load(metadata)

tag = release.get("tag_name", "")
if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+(?:[.-][0-9A-Za-z]+)*", tag):
    raise SystemExit("GitHub returned an invalid release tag")

asset = next((item for item in release.get("assets", [])
              if item.get("name") == asset_name), None)
if asset is None:
    raise SystemExit(f"Release {tag} does not contain {asset_name}")

digest = asset.get("digest", "")
if not re.fullmatch(r"sha256:[0-9a-fA-F]{64}", digest):
    raise SystemExit(f"Release asset {asset_name} has no valid SHA-256 digest")

print(tag)
print(asset["browser_download_url"])
print(digest.removeprefix("sha256:").lower())
PY
)

[[ "${#release_data[@]}" -eq 3 ]] || {
    error "Could not resolve release asset metadata"
    exit 1
}
readonly version="${release_data[0]}"
readonly download_url="${release_data[1]}"
readonly expected_sha256="${release_data[2]}"
readonly archive="${workdir}/${asset_name}"

info "Downloading btop ${version} for ${asset_arch}"
curl "${curl_args[@]}" "$download_url" -o "$archive"
printf '%s  %s\n' "$expected_sha256" "$archive" | sha256sum --check --status || {
    error "SHA-256 verification failed for ${asset_name}"
    exit 1
}

mkdir "${workdir}/extracted"
tar --extract --gzip --file "$archive" --directory "${workdir}/extracted" \
    --no-same-owner --no-same-permissions
source_dir="${workdir}/extracted/btop"
[[ -x "${source_dir}/bin/btop" && -d "${source_dir}/themes" ]] || {
    error "Downloaded archive does not have the expected layout"
    exit 1
}
"${source_dir}/bin/btop" --version >/dev/null

SUDO=()
if [[ "$(id -u)" -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || {
        error "Root privileges are required and sudo was not found"
        exit 1
    }
    SUDO=(sudo)
fi

info "Installing btop ${version} to ${PREFIX}"
"${SUDO[@]}" install -d \
    "${PREFIX}/bin" \
    "${PREFIX}/share/btop/themes" \
    "${PREFIX}/share/applications" \
    "${PREFIX}/share/icons/hicolor/48x48/apps" \
    "${PREFIX}/share/icons/hicolor/scalable/apps"
"${SUDO[@]}" install -m 0755 "${source_dir}/bin/btop" "${PREFIX}/bin/btop"
"${SUDO[@]}" install -m 0644 "${source_dir}/README.md" "${PREFIX}/share/btop/README.md"
"${SUDO[@]}" install -m 0644 "${source_dir}"/themes/*.theme "${PREFIX}/share/btop/themes/"
"${SUDO[@]}" install -m 0644 "${source_dir}/btop.desktop" "${PREFIX}/share/applications/btop.desktop"
"${SUDO[@]}" install -m 0644 "${source_dir}/Img/icon.png" \
    "${PREFIX}/share/icons/hicolor/48x48/apps/btop.png"
"${SUDO[@]}" install -m 0644 "${source_dir}/Img/icon.svg" \
    "${PREFIX}/share/icons/hicolor/scalable/apps/btop.svg"

installed_output="$("${PREFIX}/bin/btop" --version)"
installed_version="${installed_output%%$'\n'*}"
info "Installed ${installed_version}"
