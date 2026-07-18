# Vendored: microsoft/WindowsDeveloperConfig

These files are vendored (copied verbatim) from Microsoft's
[WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig) project and are used as the
**base installer** driven by this repo's top-level `install.ps1`.

## Source

- **Repository:** https://github.com/microsoft/WindowsDeveloperConfig
- **Pinned commit:** `366712847217e840103ffc8e38c4467fadb24a1d` (branch `main`)
- **License:** MIT — see [`LICENSE`](./LICENSE) (Copyright (c) Microsoft Corporation).

## What is vendored (and why)

| Vendored path | Copied from (in WDC) | Why |
|---|---|---|
| `windows-dev-config/dev-config.winget` | `windows-dev-config/dev-config.winget` | The declarative "full setup" DSC document. `install.ps1` Phase 2 runs it via `winget configure`. Fully self-contained (all paths resolve to `%LOCALAPPDATA%` / `%TEMP%` / web downloads — no sibling-file dependencies). |
| `windows-dev-config/README.md` | `windows-dev-config/README.md` | Reference documentation for the config. |
| `wsl-comfort/install.ps1` | `wsl-comfort/install.ps1` | Sets up WSL + the "Comfort Shell", registers the `"Comfort Shell Dark"` Windows Terminal scheme, and runs the comfort-shell bootstrap. `install.ps1` Phase 3 invokes it with `-NonInteractive -Distro <name>`. |
| `wsl-comfort/comfort-shell-bootstrap.sh` | `wsl-comfort/comfort-shell-bootstrap.sh` | Required beside `wsl-comfort/install.ps1` (it is located via `$PSScriptRoot`). |
| `wsl-comfort/readme.md` | `wsl-comfort/readme.md` | Reference documentation for the comfort shell. |

## What is intentionally **not** vendored

- WDC's `windows-dev-config/install.ps1` shim and the `Workloads/` tree (including `Workloads/_common/apply-configuration.ps1`).
  We call `winget configure` on `dev-config.winget` directly, so the shim and its helpers are unnecessary.
- The `src/` mirror, tests, pipelines, and CmdPal project — not needed for the installer.

## Line endings

This repo's `.gitattributes` normalizes repo `*.sh` files to `LF`, but scopes everything under `vendor/` to
`-text` so these vendored assets are kept **byte-for-byte** (no line-ending or other normalization). This preserves
the signed `*.ps1` scripts exactly as shipped and keeps re-sync diffs limited to genuine upstream changes.
`comfort-shell-bootstrap.sh` therefore stays CRLF as WDC ships it; `wsl-comfort/install.ps1` strips `\r` before
executing it in WSL, so that is harmless.

## Re-syncing to a newer WDC

1. Clone or pull `microsoft/WindowsDeveloperConfig` and check out the desired commit.
2. Copy verbatim into this folder (from the WDC repo root):
   - `windows-dev-config/dev-config.winget`, `windows-dev-config/README.md`
   - `wsl-comfort/install.ps1`, `wsl-comfort/comfort-shell-bootstrap.sh`, `wsl-comfort/readme.md`
   - `LICENSE`
3. Re-verify `dev-config.winget` is still self-contained (no new sibling-file / `Workloads` dependencies):
   `Select-String -Path windows-dev-config/dev-config.winget -Pattern 'Workloads|apply-configuration|_common'`.
4. Confirm `wsl-comfort/install.ps1` still exposes `-NonInteractive` and `-Distro` (used by our Phase 3).
5. Update the **Pinned commit** SHA above.
