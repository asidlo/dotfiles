# Dotfiles

Personal Windows + WSL developer environment. Setup is built on top of Microsoft's
[WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig) (WDC) as the base "full setup", with this
repo's personal settings layered on top and the WSL side wired up automatically.

> Work in progress, but the top-level `install.ps1` is the supported entry point.

## Quick start

From an **elevated** PowerShell (Run as administrator) on Windows:

```powershell
git clone https://github.com/asidlo/dotfiles D:\src\dotfiles
cd D:\src\dotfiles
.\install.ps1
```

That single command runs everything, end to end:

1. Microsoft's WindowsDeveloperConfig base setup (apps, dark/distraction-free desktop, WSL + Ubuntu).
2. The WSL "Comfort Shell" (`wsl-comfort`), including the `"Comfort Shell Dark"` Windows Terminal scheme.
3. This repo's personal layer (extra winget packages, fonts, registry tweaks, symlinks, profiles).
4. This repo's WSL-side `install.sh`, run **inside** the distro automatically.

On a fresh machine the WDC step may reboot (it resumes itself). If it does, just re-run `.\install.ps1` after logging
back in — every phase is idempotent, so re-running is safe.

## What `install.ps1` does (phases)

| Phase | Action |
|------:|--------|
| 0 | Preflight: require admin, assert `winget`, enable `winget configure`. |
| 1 | Resolve the vendored WindowsDeveloperConfig assets under `vendor\WindowsDeveloperConfig\`. |
| 2 | WDC base setup: `winget configure` the vendored `dev-config.winget`. |
| 3 | `wsl-comfort`: WSL + distro + Comfort Shell + Terminal scheme. |
| 4 | Personal layer: the `catalog\*` tasks below (the delta on top of WDC). |
| 5 | Run this repo's `install.sh` inside WSL (`wsl -d <Distro> -- bash -lc 'cd <repo> && bash ./install.sh'`). |

### Flags

| Flag | Effect |
|------|--------|
| `-Distro <name>` | WSL distro to target for Phases 3 and 5 (default `Ubuntu`). |
| `-SkipWdc` | Skip Phase 2 (WindowsDeveloperConfig base setup). |
| `-SkipWslComfort` | Skip Phase 3 (wsl-comfort). |
| `-SkipPersonal` | Skip Phase 4 (the personal catalog layer). |
| `-SkipWsl` | Skip Phase 5 (don't auto-run `install.sh` in WSL). |
| `-IncludeAppxPrune` | Also run the aggressive `appx-prune` task in Phase 4 (opt-in). |

```powershell
# Windows only; run install.sh yourself later inside WSL:
.\install.ps1 -SkipWsl

# Re-apply just the personal layer:
.\install.ps1 -SkipWdc -SkipWslComfort -SkipWsl
```

If Phase 5 is skipped (or WSL wasn't ready), run the WSL side by hand from inside the distro:

```bash
cd /mnt/d/src/dotfiles   # or wherever the repo lives
bash ./install.sh
```

## Vendored WindowsDeveloperConfig

`vendor\WindowsDeveloperConfig\` contains the WDC assets used as the base (the `dev-config.winget` DSC document and the
`wsl-comfort` orchestrator), copied verbatim and pinned to an upstream commit. WDC is MIT-licensed; its `LICENSE` is
included. See [`vendor\WindowsDeveloperConfig\PROVENANCE.md`](vendor/WindowsDeveloperConfig/PROVENANCE.md) for the exact
source commit, what is vendored, and how to re-sync to a newer WDC.

## Personal layer: catalog tasks (`catalog/`)

Discrete, idempotent tasks that `install.ps1` Phase 4 runs in order. They can also be composed standalone as Dev Box
catalog tasks.

| Task | Purpose | Run by `install.ps1`? |
|------|---------|-----------------------|
| `winget-core` | Install personal winget tooling **not** covered by WDC (Docker, Starship, eza, zoxide, fd, bat, ripgrep, Clink, fzf, Neovim, lazygit, Go, vim, azcopy, Teams, Azure CLI, LLVM, Rustup). | ✅ |
| `choco-fonts` | Install Meslo Nerd Font via Chocolatey (idempotent). | ✅ |
| `modules-install` | Install `Az` & `PSDesiredStateConfiguration` PowerShell modules. | ✅ |
| `path-llvm` | Append `C:\Program Files\LLVM\bin` to PATH if present. | ✅ |
| `windows-features` | Enable VirtualMachinePlatform, Containers, WSL, Hyper-V. | ✅ |
| `appx-prune` | Remove non-essential AppX packages (curated keep-list). | Only with `-IncludeAppxPrune` |
| `dev-settings` | Registry/UX tweaks: UAC, dark theme, taskbar/Start cleanup, clocks, explorer, privacy. | ✅ |
| `powershell-profiles` | Deploy `WindowsPowerShell` & `PowerShell` profile scripts from the repo. | ✅ |
| `dotfiles-links` | Symlink gitconfig, starship, clink, nvim, Terminal settings, icons. | ✅ |
| `verify-baseline` | Post-check that core tools and links are present. | ✅ |
| `wsl-bootstrap` | Standalone WSL distro install/config for Dev Box. Superseded on a full run by WDC + `wsl-comfort` + Phase 5, so **not** invoked by `install.ps1`. | ❌ |

### Customizing winget packages

`winget-core` accepts a space-delimited override: `-packages "Neovim.Neovim Microsoft.AzureCLI"`. Omit it to use the
curated list. Packages already installed by WDC (Python, Node.js, Windows Terminal, PowerToys, Git, VS Code, PowerShell,
uv, …) are intentionally left out of `winget-core`.

## Using tasks in Dev Box

The `catalog/*` tasks can be attached as a Dev Box catalog and referenced declaratively:

```yaml
tasks:
  - name: windows-features
  - name: winget-core
    parameters:
      packages: "Neovim.Neovim Microsoft.AzureCLI"
  - name: choco-fonts
  - name: dev-settings
  - name: powershell-profiles
  - name: dotfiles-links
  - name: modules-install
  - name: path-llvm
  - name: verify-baseline
```

## WSL side (`install.sh`)

`install.sh` (auto-run by Phase 5, or runnable by hand inside WSL) symlinks shell configs and best-effort installs CLI
tooling (fd, fzf, bat, ripgrep, zoxide, direnv, eza, btop, starship, zsh, gh, az, and — outside codespaces/devcontainers
— rust, lazygit, nvim, go, npm, dotnet, tmux). It self-locates via `realpath`, so running it from the repo (including the
`/mnt/...` Windows mount) works. `.gitattributes` keeps repo `*.sh` files `LF` so they run correctly under WSL.

It may prompt for your WSL `sudo` password (e.g. `locale-gen`); run it in an interactive terminal. On Ubuntu,
Debian, Mariner, and Azure Linux, a root invocation installs `sudo` first when it is missing. A non-root user without
`sudo` must run `scripts/ensure-sudo.sh` as root once, then rerun `install.sh` as the normal user.

## Idempotency & re-runs

- Every `install.ps1` phase is safe to re-run; re-run the whole script after any WDC reboot.
- Chocolatey bootstrap only runs if `choco` is missing; fonts/modules check before installing.
- LLVM PATH edit only happens if not already present.
- `verify-baseline` exits non-zero if any required item is missing (useful in CI/image validation).

## Troubleshooting

| Symptom | Resolution |
|---------|------------|
| `winget configure` not available | Update **App Installer** from the Microsoft Store; Phase 0 also runs `winget configure --enable`. |
| WDC step rebooted | Log back in and re-run `.\install.ps1`. |
| Phase 5 skipped ("distro not ready") | Ensure the distro exists (`wsl -l -v`), then re-run `.\install.ps1` or run `install.sh` by hand inside WSL. |
| `install.sh` errors on `\r` | Ensure `*.sh` files are `LF` (enforced by `.gitattributes`; run `git add --renormalize .` if needed). |
| Missing tool after `winget-core` | Confirm the winget ID; re-run with an explicit `-packages` override. |
| Font not in terminal | Log off / rebuild font cache; verify Meslo under `%WINDIR%\Fonts`. |
| Symlink errors | Ensure the repo path is accessible; check permissions and OneDrive sync state. |
