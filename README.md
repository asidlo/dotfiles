# Dotfiles

Warning this repo is constantly a work in progress, and should currently just be used as a reference. Hopefully, in the
future there will be more info about installation and usage.

## Dev Box Catalog Tasks

This repository now exposes discrete Dev Box catalog tasks derived from the original `install.ps1` so you can compose
environment setup declaratively.

## Task Inventory (under `catalog-tasks/`)

| Task Name | Purpose | Script |
|-----------|---------|--------|
| appx-prune | Remove non-essential AppX packages (keep curated allowlist) | `appx-prune/script.ps1` |
| windows-features | Enable WSL, Hyper-V, Containers features | `windows-features/script.ps1` |
| winget-core | Install core developer tooling (parameter override supported) | `winget-core/script.ps1` |
| choco-fonts | Install Meslo Nerd Font via Chocolatey (idempotent) | `choco-fonts/script.ps1` |
| powershell-profiles | Deploy WindowsPowerShell & PowerShell profile scripts from repo | `powershell-profiles/script.ps1` |
| dotfiles-links | Create symlinks for gitconfig, starship, clink, nvim, terminal settings, icons | `dotfiles-links/script.ps1` |
| modules-install | Install Az & PSDesiredStateConfiguration modules | `modules-install/script.ps1` |
| path-llvm | Append LLVM bin to PATH if present | `path-llvm/script.ps1` |
| verify-baseline | Post-check to verify presence of core tools and links | `verify-baseline/script.ps1` |

## Using Tasks in Dev Box

1. Attach this repository as a catalog in the Dev Box portal.
2. Reference tasks in `imagedefinition.yaml` or `devbox.customizations.yaml`:

```yaml
tasks:
  - name: windows-features
  - name: winget-core
    parameters:
      packages: "Neovim.Neovim Microsoft.AzureCLI"
  - name: choco-fonts
  - name: dotfiles-links
  - name: modules-install
  - name: path-llvm
  - name: verify-baseline
```

## Customizing Winget Packages

Override the default set by passing a space-delimited list via `packages:` parameter. If omitted, the curated list from
the original script is used.

## Idempotency Notes

- Chocolatey bootstrap happens only if `choco` is missing.
- Fonts and modules check for prior installation to avoid repeated work.
- PATH modification only occurs if LLVM not already present.
- Verification task exits non-zero if any required item is missing (useful in CI or image build validation).

## Migrating from install.ps1

Instead of a single monolithic PowerShell run:

| Old Step | New Task |
|----------|----------|
| AppX removals | appx-prune |
| Feature enablement | windows-features |
| Winget installs | winget-core (overrideable) |
| Nerd Font install | choco-fonts |
| Profiles copy | powershell-profiles |
| Symlink assets | dotfiles-links |
| Module installs | modules-install |
| LLVM PATH edit | path-llvm |
| Sanity validation | verify-baseline |

This modularity improves debugging, reuse across pools, and selective updates (e.g., refresh only `winget-core`).

## Next Enhancements

- Add `wsl-bootstrap` task to automate distro install and config.
- Add `optimize-defender` task for Defender tuning (placeholder in original script).
- Introduce `pin-start-menu` task for desired app pinning.
- Integrate CI pipeline to run `verify-baseline` after task changes.

## Troubleshooting

| Symptom | Resolution |
|---------|------------|
| Missing tool after `winget-core` | Confirm winget ID; re-run task with explicit `packages:` override. |
| Font not appearing in terminal | Log off or force font cache rebuild; verify Meslo listed in `%WINDIR%\Fonts`. |
| Symlink errors | Ensure repo path accessible; check permissions and OneDrive sync state. |
| Modules not loading | Open new PowerShell session; ensure `PSModulePath` includes CurrentUser modules. |

---
Generated from original `install.ps1` for maintainable, reviewable Dev Box provisioning.
