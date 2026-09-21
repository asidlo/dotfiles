# Dotfiles

Personal Windows + WSL developer environment. Setup is built on top of Microsoft's
[WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig) (WDC) as the base "full setup", with this
repo's personal settings layered on top and the WSL side wired up automatically.

> Work in progress, but the top-level `install.ps1` is the supported entry point.

## Quick start

From an **elevated** PowerShell (Run as administrator) on Windows:

```powershell
git clone https://github.com/asidlo/dotfiles Q:\src\dotfiles
cd Q:\src\dotfiles
.\install.ps1
```

That single command runs everything, end to end:

1. Microsoft's WindowsDeveloperConfig base setup (apps, dark/distraction-free desktop, WSL + Ubuntu).
2. The WSL "Comfort Shell" (`wsl-comfort`), including the `"Comfort Shell Dark"` Windows Terminal scheme.
3. This repo's personal layer (winget packages, fonts, Dev Drive redirection, VS 2022, registry tweaks, symlinks).
4. WSL provisioning: create a **non-root** user and (by default) move the distro's VHDX onto the Dev Drive.
5. This repo's WSL-side `install.sh`, run **inside** the distro as that user, automatically.

On a fresh machine the WDC step may reboot (it resumes itself). If it does, just re-run `.\install.ps1` after logging
back in — every phase is idempotent, so re-running is safe.

## What `install.ps1` does (phases)

| Phase | Action |
|------:|--------|
| 0 | Preflight: require admin, assert `winget`, enable `winget configure`, start the transcript. |
| 1 | Resolve the vendored WindowsDeveloperConfig assets under `vendor\WindowsDeveloperConfig\`. |
| 2 | WDC base setup: `winget configure` the vendored `dev-config.winget`. |
| 3 | `wsl-comfort`: WSL + distro + Comfort Shell + Terminal scheme. |
| 4 | Personal layer: the `catalog\*` tasks below (the delta on top of WDC). |
| 5 | WSL provisioning: create the non-root user, clean stale `/root` dotfiles, move the VHDX to the Dev Drive. |
| 6 | Run this repo's `install.sh` inside WSL as that user. |

### Parameters

| Parameter | Default | Effect |
|-----------|---------|--------|
| `-Distro <name>` | `Ubuntu` | WSL distro to target for Phases 3, 5 and 6. |
| `-WslUser <name>` | `$env:USERNAME` (lowercased) | Non-root WSL user to create and run `install.sh` as. |
| `-WslPassword <SecureString>` | prompted | Password for that user. Piped to `chpasswd` over **stdin** — never on a command line, never in the transcript. |
| `-ArtifactRoot <path>` | `Q:\.tools` | Dev Drive root for package caches, toolchains, the WSL VHDX and logs. |
| `-SrcRoot <path>` | `Q:\src` | Where repos are cloned. |
| `-NfvRepoUrl <url>` | `…/One/_git/Networking-nfv` | ADO remote for the Networking-nfv clone. |
| `-NfvRepoPath <path>` | `<SrcRoot>\Networking-nfv` | Clone destination; also where `NFV.vsconfig` is read from. |
| `-VsInstallPath <path>` | `…\Microsoft Visual Studio\2022\Enterprise` | VS 2022 install location (installed **side-by-side**; VS 2026 is never touched). |
| `-LogPath <path>` | `<ArtifactRoot>\logs` | Transcript + JSON ledger destination. |
| `-MoveWslToDevDrive` | `$true` | Move the distro's `ext4.vhdx` off `C:`. Use `-MoveWslToDevDrive:$false` to opt out. |
| `-CleanStaleRootDotfiles` | `$true` | Remove dotfile symlinks a previous root-run left under `/root`. |
| `-WslTempPasswordlessSudo` | `$true` | Grant `-WslUser` NOPASSWD sudo for the duration of the WSL phases (3 onward), then revoke it. See [WSL and sudo](#wsl-and-sudo). |
| `-ContinueOnError` | `$true` | Collect failures and report at the end instead of aborting on the first one. |
| `-RestartExplorer` | off | Let `dev-settings` restart Explorer (off by default so it can't kill Explorer mid-install). |
| `-NonInteractive` | off | Never prompt; skip anything that would need input. |
| `-SkipWdc` / `-SkipWslComfort` / `-SkipPersonal` / `-SkipWsl` | off | Skip Phase 2 / 3 / 4 / 5+6. |
| `-SkipDevDriveEnv` / `-SkipNfvClone` / `-SkipVisualStudio` | off | Skip individual Phase 4 tasks. |

```powershell
# Windows only; run install.sh yourself later inside WSL:
.\install.ps1 -SkipWsl

# Re-apply just the personal layer:
.\install.ps1 -SkipWdc -SkipWslComfort -SkipWsl

# Point the whole thing at a different Dev Drive:
.\install.ps1 -ArtifactRoot 'E:\.tools' -SrcRoot 'E:\src'

# Unattended (no prompts, no VHDX move):
.\install.ps1 -NonInteractive -MoveWslToDevDrive:$false
```

If Phases 5/6 are skipped (or WSL wasn't ready), run the WSL side by hand from inside the distro:

```bash
cd /mnt/q/src/dotfiles   # or wherever the repo lives
bash ./install.sh
```

## Logs & failure reporting

`install.ps1` never reports success while silently installing nothing. Every phase and every catalog task is wrapped in
a ledger that captures **terminating errors, anything written to the error stream, and non-zero exit codes**, then
prints a summary table at the end:

```
=== Run summary ===
Phase Task                     Status      Exit Duration  Message
----- ------------------------ -------- ------- --------- -------
4     winget-core              Ok             0 00:04:12
4     nfv-clone                Failed         1 00:00:08  authentication failed
...
  12 ok, 1 warning(s), 1 failed, 0 skipped
```

Failures are reprinted underneath with the captured output and a remediation hint, and the process **exits non-zero**
so a wrapper or CI job can detect it.

| Artifact | Location |
|----------|----------|
| Windows transcript | `<ArtifactRoot>\logs\install-<yyyyMMdd-HHmmss>.log` |
| Machine-readable ledger | `<ArtifactRoot>\logs\install-<yyyyMMdd-HHmmss>.json` |
| WSL log | `~/.local/state/dotfiles/install-<stamp>.log` (inside the distro) |

Both Windows paths are printed at the start *and* the end of the run.

## Dev Drive layout

The `devdrive-env` task keeps large build artifacts off `C:` by pointing the toolchains at `-ArtifactRoot`
(default `Q:\.tools`) via **machine-scoped** environment variables:

| Toolchain | Variables |
|-----------|-----------|
| NuGet / .NET | `NUGET_PACKAGES`, `NUGET_HTTP_CACHE_PATH`, `NUGET_PLUGINS_CACHE_PATH`, `DOTNET_CLI_HOME` |
| npm / pnpm / yarn | `npm_config_cache`, `npm_config_prefix`, `PNPM_HOME`, `PNPM_STORE_DIR`, `YARN_CACHE_FOLDER` |
| Go | `GOPATH`, `GOMODCACHE`, `GOCACHE` |
| Rust | `CARGO_HOME`, `RUSTUP_HOME` |
| Python | `PIP_CACHE_DIR`, `UV_CACHE_DIR` |
| vcpkg | `VCPKG_DEFAULT_BINARY_CACHE`, `VCPKG_DOWNLOADS` |
| JVM | `GRADLE_USER_HOME`, `MAVEN_OPTS` |
| Docker | `DOCKER_CONFIG`, `BUILDX_CONFIG`, plus `dataFolder` in Docker Desktop's `settings-store.json` |
| Locations | `DEVDRIVE_SRC` (= `-SrcRoot`), `DEVDRIVE_ARTIFACTS` (= `-ArtifactRoot`) |

`DEVDRIVE_SRC` exists so nothing has to hard-code a drive letter. Windows Terminal expands environment variables in
`startingDirectory`, so `powershell\settings.json` uses `%DEVDRIVE_SRC%` and the profiles follow the Dev Drive wherever
it lands (and fall back to the shell's own default directory if the variable is not set yet). Machine-scoped variables
only reach **new** processes, so restart Windows Terminal — or sign out — after a first run.

`…\.npm-global`, `…\cargo\bin` and `…\go\bin` are prepended to PATH. `TEMP`/`TMP` are deliberately **not** redirected.
The WSL distro's `ext4.vhdx` is moved to `<ArtifactRoot>\wsl\<Distro>\` by Phase 5.

### The `Networking-nfv` Terminal profile

`powershell\settings.json` ships a static **Networking-nfv** profile that opens an elevated VS 2022 developer shell in
`%DEVDRIVE_SRC%\Networking-nfv` with the repo's dev modules already loaded. `Command Prompt` is the default profile.

The profile itself carries no paths and no logic — it shells out to
[`powershell\nfv-devshell.ps1`](powershell/nfv-devshell.ps1), which resolves everything at launch. Four things about it
are deliberate:

- **Windows PowerShell 5.1, not `pwsh`.** NFV's `onebox.psm1` and `NFVUT.psm1` call `Get-WmiObject`, which was removed
  in PowerShell 6.
- **`AddModules.ps1` is dot-sourced, never run with `-File`.** It defines shell functions (`root`, `src`), sets
  `REPOROOT`/`OUTPUTROOT` and imports a dozen modules into its *caller's* scope; under `-File` all of it would be
  discarded with the script scope, leaving a prompt with nothing loaded.
- **`vswhere` is pinned to `[17.0,18.0)`.** A bare `-latest` would pick the side-by-side VS 18 install instead.
- **Elevation goes through `sudo`, not `"elevate": true`.** Terminal's own `elevate` cannot put an elevated tab in an
  unelevated window, so it always spawns a *separate* window. `sudo` in inline mode keeps it as a tab — hence the
  `sudo-inline` task. The profile does **not** pass `--inline`, because sudo exits with an error when a mode is
  requested that the machine setting disallows; omitting it degrades to a new window instead of failing outright.

Terminal expands `%VARS%` in `startingDirectory` but **not** in `commandline`, which is why the profile's command line
re-derives `DEVDRIVE_SRC` in PowerShell rather than relying on Terminal to expand it.

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
| `winget-core` | Install personal winget tooling **not** covered by WDC (Docker, Starship, eza, zoxide, fd, bat, ripgrep, Clink, fzf, Neovim, lazygit, Go, vim, AzCopy, Teams, Azure CLI, LLVM, Rustup). | ✅ |
| `choco-fonts` | Install Meslo Nerd Font via Chocolatey (idempotent). | ✅ |
| `modules-install` | Install `Az` & `PSDesiredStateConfiguration` PowerShell modules. | ✅ |
| `devdrive-env` | Point NuGet/npm/Go/Rust/Python/vcpkg/JVM/Docker caches at the Dev Drive (machine scope). | ✅ |
| `nfv-clone` | Clone `Networking-nfv` from ADO into `-NfvRepoPath` (no-op if already present). | ✅ |
| `visualstudio` | Install VS 2022 Enterprise **side-by-side** with VS 2026, then apply `NFV.vsconfig`. | ✅ |
| `path-llvm` | Append `C:\Program Files\LLVM\bin` to PATH if present. | ✅ |
| `windows-features` | Enable VirtualMachinePlatform, Containers, WSL, Hyper-V. | ✅ |
| `agency` | Install the `agency` CLI via `aka.ms/InstallTool.ps1` and rehydrate PATH. | ✅ |
| `copilot-plugins` | Ensure the GitHub Copilot CLI is present and install the `anvil` plugin. | ✅ |
| `wsl-bootstrap` | WSL distro install/config + `etc\wsl.conf` + `win32yank`. | ✅ |
| `dev-settings` | Registry/UX tweaks: UAC, dark theme, taskbar/Start cleanup, clocks, explorer, privacy. | ✅ |
| `sudo-inline` | Put Sudo for Windows into **inline** mode so the elevated `Networking-nfv` profile stays a tab instead of taking over a new window. | ✅ |
| `dotfiles-links` | Symlink gitconfig, starship, clink, nvim, Terminal settings, icons. | ✅ |
| `terminal-profiles` | Clear Windows Terminal's `generatedProfiles` so its fragment/dynamic profiles (Ubuntu, Comfort Shell, Copilot, VS prompts) stop being auto-hidden. | ✅ |
| `verify-baseline` | Post-check that core tools, links, VS 2022, NFV, agency, anvil, dev-drive vars, the WSL user, the Terminal fragment profiles, the NFV profile and sudo's mode are present. | ✅ |
| `appx-prune` | Remove non-essential AppX packages (curated keep-list). | ❌ too destructive; run by hand |
| `powershell-profiles` | Deploy `WindowsPowerShell` & `PowerShell` profile scripts from the repo. | ❌ profiles already sync from OneDrive |

> `anvil` is installed with `copilot plugin install burkeholland/anvil`. That form emits a *"direct plugin installs are
> deprecated"* warning, but no marketplace currently publishes anvil, so there is no `anvil@marketplace` to switch to.
> The warning is allow-listed so it never shows up as a failure.

### Customizing winget packages

`winget-core` takes a real string **array**: `-Packages 'Neovim.Neovim','Microsoft.AzureCLI'`. Omit it to use the
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
  - name: devdrive-env
    parameters:
      artifactRoot: "Q:\\.tools"
  - name: dev-settings
  - name: sudo-inline
  - name: dotfiles-links
  - name: terminal-profiles
  - name: modules-install
  - name: path-llvm
  - name: verify-baseline
```

## WSL side (`install.sh`)

`install.sh` (auto-run by Phase 6, or runnable by hand inside WSL) symlinks shell configs and best-effort installs CLI
tooling (fd, fzf, bat, ripgrep, zoxide, direnv, eza, btop, starship, zsh, gh, az, and — outside codespaces/devcontainers
— rust, lazygit, nvim, go, npm, dotnet, tmux, agency, copilot + anvil). It self-locates via `realpath`, so running it
from the repo (including the `/mnt/...` Windows mount) works. `.gitattributes` keeps repo `*.sh` files `LF` so they run
correctly under WSL.

Like the Windows side, it records every tool install in a ledger and prints a summary at the end rather than aborting on
the first failure; only symlink creation stays fail-fast. It may prompt for your WSL `sudo` password (e.g. `locale-gen`);
run it in an interactive terminal. On Ubuntu, Debian, Mariner, and Azure Linux a root invocation installs `sudo` first
when it is missing (via `scripts/ensure-sudo.sh`); a non-root user without `sudo` must run `scripts/ensure-sudo.sh` as
root once, then rerun `install.sh`.

Each step runs with its **stdin closed**. A step that stops to ask a question has nobody to answer it, and because
stdout is piped through `tee` the prompt can stay buffered while the run just looks frozen — which is what VS Code's
`copilot` shim did with *"Install GitHub Copilot CLI? ['y/N']"*. With `/dev/null` on stdin the same prompt fails
immediately, lands in the step log, and the summary points at it.

`install.sh` also links `pbcopy`, `pbpaste`, `open` and `xdg-open` from `bin/` into `~/.local/bin`. `xdg-open` is there
for the auth flows rather than for you: the NuGet credential providers launch their device-code browser through it and
GCM searches `$PATH` for it before anything else, yet Azure Linux ships no `xdg-utils`. On a display-less remote the
shim hands the URL to the VS Code client's browser helper.

### Windows interop shims

`etc/wsl.conf` sets `appendWindowsPath=false` so the ~15 Windows directories stay out of `$PATH` inside WSL. The side
effect is that Windows executables stop resolving by name, which silently breaks anything that looks them up with
`command -v` — the Agency installer shells out to `cmd.exe` and fails sign-in with *"Error obtaining access token …
Authentication failed"*, `bin/pbcopy` degrades to its OSC52 fallback, and `bin/open`'s `cmd.exe /c start` fallback dies.

`scripts/wsl-interop-shims.sh` (the first step `install.sh` runs) symlinks `cmd.exe`, `clip.exe`, `wsl.exe`,
`powershell.exe` and `explorer.exe` into `~/.local/bin`. That keeps the clean `$PATH`, needs no `sudo`, and leaves
interop itself untouched — the symlinks still execute through `binfmt_misc`. Run it by hand any time:

```bash
bash scripts/wsl-interop-shims.sh
```

It is idempotent and refuses to overwrite a non-symlink of the same name.

### Non-root WSL user

`wsl-comfort` suppresses the Ubuntu OOBE, so a fresh distro has **no user other than `root`** — which is why an earlier
run linked every dotfile into `/root`. Phase 5 fixes that:

1. `scripts\wsl-provision-user.sh` creates `-WslUser` with a zsh shell, adds it to `sudo`/`wheel`/`adm`, sets the
   password from **stdin** (never from a command line), and writes `[user] default=` into `/etc/wsl.conf`.
2. `scripts\wsl-clean-root-dotfiles.sh` removes the stale `/root` symlinks — but **only** entries that are symlinks
   resolving back into this repo. Real files and legitimately-installed trees (`/root/.nvm`, `.cargo`, `.rustup`,
   `.tmux/plugins`, …) are left alone.
3. The distro's `ext4.vhdx` is moved to `<ArtifactRoot>\wsl\<Distro>\` (skipped, not failed, if the drive can't hold it).

Phase 6 then runs `install.sh` as `wsl -d <Distro> -u <WslUser>`.

### WSL and sudo

`Invoke-Step` captures WSL output through a PowerShell pipeline, so the distro is handed **no controlling pty**.
`/dev/tty` still exists as a device node inside WSL, so a naive `[ -e /dev/tty ]` check passes and `sudo -v` prompts on
a terminal nobody can answer — the step then dies on sudo's five-minute `passwd_timeout`. And because sudo's default
`timestamp_type=tty` degrades to `ppid` without a tty, even an answered prompt would not carry into the per-tool
scripts `install.sh` spawns; each would prompt again.

So the run is bracketed instead:

1. `scripts\wsl-sudoers-temp.sh grant <user>` writes `/etc/sudoers.d/99-dotfiles-install` (`0440 root:root`), validated
   with `visudo -cf` **before** it is installed and verified with `runuser … sudo -n true` afterwards.
2. Every WSL step runs. Their `sudo -n true` fast path succeeds, so nothing ever prompts.
3. `scripts\wsl-sudoers-temp.sh revoke` removes it from a `finally` block. A leftover from a killed run is also revoked
   before each grant, and the revoke runs even when `-WslTempPasswordlessSudo:$false`.

The grant is taken **before Phase 3**, not at Phase 6. `wsl-comfort` (Phase 3) authenticates sudo three separate times
of its own — twice in `comfort-shell-bootstrap.sh` and once in the Homebrew installer it spawns — so granting at Phase 6
left those prompting. On a first run the distro or `-WslUser` may not exist that early; the grant then records `Skipped`
and Phase 6 takes it instead. Revocation is idempotent and runs from the script's **top-level** `finally`, so the
drop-in is removed even if a later phase throws.

Use `-WslTempPasswordlessSudo:$false` to opt out; `install.sh` will then require an interactive shell, and now fails in
under a second with instructions instead of hanging for five minutes.

## Idempotency & re-runs

- Every `install.ps1` phase is safe to re-run; re-run the whole script after any WDC reboot.
- Chocolatey bootstrap only runs if `choco` is missing; fonts/modules check before installing.
- LLVM PATH edit only happens if not already present.
- `devdrive-env` skips any variable already pointing at the right place.
- `nfv-clone`, `visualstudio`, `agency` and `copilot-plugins` all no-op when the target is already there.
- `verify-baseline` exits non-zero if any required item is missing (useful in CI/image validation), and `install.ps1`
  propagates that as a failed step.

## Troubleshooting

| Symptom | Resolution |
|---------|------------|
| `winget configure` not available | Update **App Installer** from the Microsoft Store; Phase 0 also runs `winget configure --enable`. |
| WDC step rebooted | Log back in and re-run `.\install.ps1`. |
| A step failed | Read the summary table at the end of the run; each failure lists captured output and a remediation hint. Full detail is in `<ArtifactRoot>\logs\install-<stamp>.log`. |
| `nfv-clone` failed on auth | Sign in to Git Credential Manager, then `git clone <NfvRepoUrl> <NfvRepoPath>` by hand, or re-run `install.ps1`. |
| `visualstudio` skipped the `--config` step | `NFV.vsconfig` wasn't found — fix `nfv-clone` first, then re-run. |
| VS 2026 changed unexpectedly | It shouldn't: the task scopes vswhere to `[17.0,18.0)` and only ever modifies the 2022 install path. |
| Phase 5/6 skipped ("distro not ready") | Ensure the distro exists (`wsl -l -v`), then re-run `.\install.ps1` or run `install.sh` by hand inside WSL. |
| Dotfiles landed in `/root` | An older run had no non-root user. Re-run `install.ps1`; Phase 5 creates the user and cleans the stale `/root` links. |
| VHDX move failed | Free space on the target drive, or `-MoveWslToDevDrive:$false` to leave it on `C:`. |
| `install.sh` errors on `\r` | Ensure `*.sh` files are `LF` (enforced by `.gitattributes`; run `git add --renormalize .` if needed). |
| `wsl-install-sh` failed after ~5 minutes on sudo | Fixed: the run now grants temporary passwordless sudo, see [WSL and sudo](#wsl-and-sudo). If `wsl-sudo-revoke` reported a warning, remove `/etc/sudoers.d/99-dotfiles-install` by hand. |
| Prompted for your WSL sudo password during `wsl-comfort` | Fixed: the grant moved from Phase 6 to before Phase 3. If `wsl-sudo-temp` shows `Skipped`, the distro or user did not exist yet — expected on a first run. |
| Terminal profiles (WSL, Comfort Shell, VS dev shells) missing from the dropdown | Terminal remembers every generated profile in `state.json` and force-hides the ones that are no longer in `settings.json`, so deleting a `profiles.list` entry by hand hides that profile *permanently*. Close **every** Terminal window, run `catalog\terminal-profiles\script.ps1`, then start Terminal again (fragments are only scanned at process start). |
| Terminal wrote new `profiles.list` entries into `powershell\settings.json` | Expected. Terminal persists its own stub for each generated profile, and their GUIDs are machine-specific (the WSL one is derived from the local distro ID). Commit or ignore them, but don't prune them — see the row above. |
| Terminal opens in the wrong drive | `%DEVDRIVE_SRC%` isn't set in that process. Re-run `devdrive-env`, then restart Windows Terminal (machine variables only reach new processes). |
| `Networking-nfv` opens in a **separate window** instead of a tab | Sudo isn't in inline mode on that machine. Run `catalog\sudo-inline\script.ps1` from an elevated shell (`sudo config` reports the current mode). |
| `Networking-nfv` warns "repo not found" or "Visual Studio not found" | The launcher degrades instead of dying, so the tab stays usable. Run `catalog\nfv-clone\script.ps1` or `catalog\visualstudio\script.ps1`, then open a new tab. |
| `Networking-nfv` prompts for UAC every time | Expected — `sudo` elevates per launch. Use the `Developer PowerShell for VS 2022` profile when you don't need admin. |
| `agency` reports "Error obtaining access token" / "Authentication failed" | The Agency installer runs `cmd.exe`, which `appendWindowsPath=false` removes from `$PATH`. Run `bash scripts/wsl-interop-shims.sh`, then `bash scripts/agency.sh` — see [Windows interop shims](#windows-interop-shims). `install.sh` now does both automatically. |
| `pbcopy` doesn't reach the Windows clipboard, or `open` fails in WSL | Same cause as the row above: `clip.exe` / `cmd.exe` aren't on `$PATH`. Run `bash scripts/wsl-interop-shims.sh` and open a new shell. |
| `install.sh` hangs on `copilot.sh` until you press Enter | Fixed. VS Code's Copilot Chat extension puts its own `copilot` shim on `$PATH` in integrated terminals; `command -v` found it, so the script skipped the install and the shim then asked *"Install GitHub Copilot CLI? ['y/N']"* on a stdin nobody was reading. `scripts/copilot.sh` now resolves past that shim, and every step runs with stdin closed. |
| `dotnet.sh` fails with `/usr/local/bin/xdg-open: Permission denied` | Fixed. The devcontainer-credprovider installer writes its own `xdg-open` shim to `/usr/local/bin`, which a non-root user cannot do, and its `set -e` failed the whole step over it. `scripts/dotnet.sh` now links `bin/xdg-open` into `~/.local/bin` and passes `SKIP_XDG_OPEN=true`. |
| Missing tool after `winget-core` | Confirm the winget ID (`winget search <name> --source winget`); re-run with an explicit `-Packages` override. |
| Font not in terminal | Log off / rebuild font cache; verify Meslo under `%WINDIR%\Fonts`. |
| Symlink errors | Ensure the repo path is accessible; check permissions and OneDrive sync state. |
