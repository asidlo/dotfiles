# Plan: Rebase `install.ps1` onto WindowsDeveloperConfig (vendored)

> Implementation plan for reworking the Windows setup so that
> [microsoft/WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig) (WDC) is the **base
> installer** (full setup), with this repo's personal settings layered on top, and `wsl-comfort\install.ps1`
> invoked automatically. Phase 5 then **automatically runs `install.sh` inside WSL**, so one elevated run does the whole cross-platform setup.

## Problem & goal

- Today `install.ps1` is a 194-line imperative script that installs ~21 winget packages and wires up symlinks.
- It never installs base dependencies its own profiles/gitconfig assume (PowerShell 7, Git, gh, VS Code, .NET, Node, uv…).
- WDC already provides a complete, declarative "full setup" via `winget configure` (a 1054-line DSC document) plus a
  `wsl-comfort` orchestrator that sets up a WSL comfort shell and the `"Comfort Shell Dark"` Terminal scheme this repo's
  `powershell/settings.json` already references but never defines.

**Goal:** make WDC the base, layer only the personal delta on top, invoke `wsl-comfort`, and finish by
automatically running the WSL-side `install.sh` inside the distro (one command, no manual step).

## Approach

**Vendor** WDC's needed assets into this repo (user's chosen integration method — no submodule, no runtime `git clone`),
then rewrite `install.ps1` as a **thin, idempotent, phased orchestrator** that drives the vendored WDC config, then
`wsl-comfort`, then this repo's existing `catalog/*` tasks as the personal layer.

### Vendored layout

WDC is **MIT-licensed**, so vendoring requires bundling the license + attribution. `dev-config.winget` is fully
self-contained (all paths resolve to `%LOCALAPPDATA%`/`%TEMP%`/web downloads — no sibling-file dependencies), and
`wsl-comfort\install.ps1` only needs `comfort-shell-bootstrap.sh` beside it. We therefore do **not** need WDC's
`Workloads/_common` shim (we call `winget configure` directly).

```
dotfiles/
  vendor/
    WindowsDeveloperConfig/
      LICENSE                       # copied verbatim from WDC root (MIT)
      PROVENANCE.md                 # source URL + pinned SHA + what/why + re-sync steps
      windows-dev-config/
        dev-config.winget           # the DSC "full setup" config
        README.md                   # reference (optional)
      wsl-comfort/
        install.ps1                 # invoked with -NonInteractive -Distro Ubuntu
        comfort-shell-bootstrap.sh  # must sit beside install.ps1 ($PSScriptRoot)
        readme.md                   # reference (optional)
```

- **Pinned source:** `microsoft/WindowsDeveloperConfig` @ `366712847217e840103ffc8e38c4467fadb24a1d` (branch `main`).
- **Skip** WDC's `windows-dev-config\install.ps1` shim (depends on `..\Workloads\_common\apply-configuration.ps1`).

### New `install.ps1` design

```powershell
[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu',
    [switch]$SkipWdc,
    [switch]$SkipWslComfort,
    [switch]$SkipPersonal,
    [switch]$SkipWsl,           # skip auto-running install.sh inside WSL
    [switch]$IncludeAppxPrune   # appx-prune is aggressive; opt-in (matches the commented-out local behavior)
)
```

| Phase | Action | Notes |
|------|--------|-------|
| 0 — Preflight | Admin guard (existing `S-1-5-32-544` check); assert `winget` present; `winget configure --enable` (idempotent). | Elevation required. |
| 1 — Resolve vendored WDC | Verify `vendor\WindowsDeveloperConfig\...` paths exist; fail fast with a clear message if missing. | No clone (vendored). |
| 2 — WDC full setup | `winget configure -f <vendored dev-config.winget> --accept-configuration-agreements --disable-interactivity` unless `-SkipWdc`. | May reboot on a **fresh** box (WDC's own RunOnce resumes `winget configure`). On this machine (WSL already installed) it won't. |
| 3 — wsl-comfort | `& <vendored wsl-comfort\install.ps1> -NonInteractive -Distro $Distro` unless `-SkipWslComfort`. | Never writes `settings.json` content (Fragment API + mtime-touch) → the symlinked `settings.json` is safe. Supplies `"Comfort Shell Dark"`. |
| 4 — Personal layer | Run existing idempotent `catalog/*` scripts unless `-SkipPersonal`. | See list below. `wsl-bootstrap` is **excluded** (WDC + wsl-comfort now own WSL). |
| 5 — WSL `install.sh` | After WSL + `$Distro` exist, run this repo's `install.sh` **directly** inside the distro, using the same in-WSL exec mechanism `wsl-comfort` uses (`wsl.exe -d $Distro -- bash -lc`), unless `-SkipWsl`. **Not** via `wsl-setup.sh` (reported non-working). | Resolve repo path via `wslpath`; run `install.sh` from the repo so it self-locates (relies on LF endings from the new `.gitattributes`); guard on distro presence (skip + message if not ready, e.g. mid-reboot). |

**Phase 4 catalog order:** `winget-core` → `choco-fonts` → `modules-install` → `path-llvm` → `windows-features` →
`appx-prune` (only if `-IncludeAppxPrune`) → `dev-settings` → `powershell-profiles` → `dotfiles-links` →
`verify-baseline`.

**Re-runnability / reboot:** keep every phase idempotent so the whole script is safe to re-run. On a fresh machine,
after any WDC reboot simply re-run `install.ps1` (Phase 2 becomes a DSC no-op, Phase 3 sees WSL present, Phase 4 tasks
and Phase 5's `install.sh` are idempotent). Optionally detect a pending reboot in Phase 2 and stop with a "reboot, then
re-run me" message.

## Concrete change list

1. **NEW** `vendor\WindowsDeveloperConfig\**` — copy `windows-dev-config\dev-config.winget` (+ its `README.md`) and the
   whole `wsl-comfort\` folder; add WDC's `LICENSE` and a `PROVENANCE.md` (source URL + SHA + re-sync steps).
2. **REWRITE** `install.ps1` — the phased orchestrator above; keep the admin guard; add `-Distro` / `-Skip*` /
   `-SkipWsl` / `-IncludeAppxPrune` params. Preserve the current LLVM-PATH, symlink, and profile behavior by delegating
   to `catalog/*`. Phase 5 runs `install.sh` **directly** in the distro using the same in-WSL exec mechanism `wsl-comfort`
   uses (`wsl.exe -d $Distro -- bash -lc`), after resolving the repo path with `wslpath`. It does **not** use
   `wsl-setup.sh` (the user reports it never worked).
3. **EDIT** `catalog\winget-core\script.ps1` — remove WDC-covered ids (`python3`, `Microsoft.WindowsTerminal`,
   `Microsoft.PowerToys`, `OpenJS.NodeJS.LTS`) and **add `eza-community.eza` + `ajeetdsouza.zoxide`** (required by
   `clink\zshify.lua`). Keep Docker, Starship, fd, bat, ripgrep, Clink, fzf, Neovim, lazygit, Go, vim, azcopy,
   Outlook, Teams, AzureCLI, LLVM, Rustup.
4. **NEW** `.gitattributes` — `*.sh text eol=lf` so the vendored `comfort-shell-bootstrap.sh` (and repo bash) keep LF
   endings on this Windows repo.
5. **EDIT** `README.md** — document the new two-step flow (elevated `install.ps1`, then `install.sh` inside WSL); fix the
   stale `catalog-tasks/` path (it's `catalog/`); add the missing `dev-settings` / `wsl-bootstrap` rows; note WDC is the base.
6. **KEEP** `choco-fonts`, `modules-install`, `path-llvm`, `windows-features` (Containers + Hyper-V), `dev-settings`,
   `powershell-profiles`, `dotfiles-links`, `verify-baseline` — the personal delta.
7. **KEEP `install.sh` unchanged (now auto-invoked):** Phase 5 runs it automatically instead of by hand.
   `wsl-setup.sh` is **not** used (reported non-working) — left in the repo but out of the flow (fix or remove later).
   `wsl-bootstrap` catalog task stays for standalone Dev Box use but is not called by `install.ps1`
   (WDC + wsl-comfort + Phase 5 cover WSL now).

## Decisions to confirm (with recommended defaults)

- **UAC silent-elevation** (`ConsentPromptBehaviorAdmin=0` in `catalog\dev-settings`): WDC instead uses Sudo-inline
  (`Sudo\Enabled=3`). *Recommended default: keep your existing behavior* (no change), but this is the single most
  security-sensitive personal tweak — flagged for a conscious keep/drop.
- **`"Comfort Shell Dark"` scheme**: supplied by `wsl-comfort` at runtime. *Optional:* also add the scheme to
  `powershell\settings.json` `schemes[]` so the terminal renders correctly even before `wsl-comfort` has run.
- **Vendored folder location**: plan uses `vendor\WindowsDeveloperConfig\`. Adjustable (e.g., root-level
  `windows-dev-config\` + `wsl-comfort\`) if preferred.
- **In-WSL run is unattended**: Phase 5 runs `install.sh` via `wsl.exe … bash` (no TTY). Confirm `install.sh` finishes
  without interactive prompts, and that a freshly WDC-installed Ubuntu (installed `--no-launch`) has a usable default
  user — if none exists yet, run the step as `-u root` or trigger first-run init first.

- **`install.sh` needs LF endings & the repo path**: it runs from the repo over the Windows mount (`wslpath`) and
  self-locates via `realpath`, so it needs LF endings (enforced by the new `.gitattributes`; may need a one-time
  `git add --renormalize .`) and symlinks shell configs to the `/mnt/...` repo path.
- **Dropped `wsl-setup.sh` side-effects**: it used to link `/etc/wsl.conf` (from `wsl/wsl.conf`) and win32yank — no
  longer automatic; fold into Phase 5 (needs `sudo`) only if you still want them. Flagged.

## Validation

- Static: syntax-check the rewritten `install.ps1` (PowerShell tokenizer / `[ScriptBlock]::Create`), and lint the edited
  `catalog\winget-core\script.ps1`.
- Config: `winget configure validate -f <vendored dev-config.winget>` (dry validation) if the winget version supports it.
- Runtime: run `catalog\verify-baseline\script.ps1`. Full end-to-end (elevated `winget configure` + `wsl-comfort` +
  reboot behavior) is validated by the user on the actual box.
- WSL step: dry-check path resolution + non-TTY invocation (`wsl -d Ubuntu -- wslpath -a <repo>` and
  `wsl -d Ubuntu -- bash -lc 'echo ok'`); the full `install.sh` run is validated by the user on the box.

## Out of scope

- No **content** changes to `install.sh` / `scripts/*.sh` — Phase 5 now invokes `install.sh` automatically, but its logic
  is untouched. `wsl-setup.sh` is left as-is but unused.
- Not modifying WDC's vendored `dev-config.winget` / `wsl-comfort` content (vendored verbatim; re-sync via `PROVENANCE.md`).

## Todos

Tracked in SQL (`todos` / `todo_deps`). Summary:

1. `vendor-wdc` — Vendoring WDC assets + LICENSE + PROVENANCE into `vendor\WindowsDeveloperConfig\`.
2. `rewrite-install-ps1` — Rewriting `install.ps1` as the phased idempotent orchestrator, incl. Phase 5 that runs `install.sh` **directly** in WSL via the wsl-comfort exec mechanism, not `wsl-setup.sh` (depends on `vendor-wdc`).
3. `trim-winget-core` — Trimming WDC-covered ids and adding `eza` + `zoxide`.
4. `add-gitattributes` — Adding `.gitattributes` (`*.sh text eol=lf`) so vendored bash **and** `install.sh` run correctly in WSL (may need one-time `git add --renormalize .`).
5. `update-readme` — Rewriting `README.md` for the new two-step flow + path fixes.
6. `confirm-decisions` — Confirming UAC keep/drop and optional `settings.json` scheme add (depends on `rewrite-install-ps1`).
7. `validate` — Syntax-check + `winget configure validate` + `verify-baseline` + WSL `wslpath`/non-TTY dry-check (depends on `rewrite-install-ps1`, `trim-winget-core`).
