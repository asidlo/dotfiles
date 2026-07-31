<#
.SYNOPSIS
  Bootstraps a Windows developer workstation in one elevated run.

.DESCRIPTION
  A thin, idempotent, phased orchestrator:

    Phase 0  Preflight ............ admin guard, assert winget, enable configure
    Phase 1  Resolve vendored WDC . verify vendored WindowsDeveloperConfig assets
    Phase 2  WDC base setup ....... `winget configure` the vendored dev-config.winget
    Phase 3  wsl-comfort .......... WSL + "Comfort Shell" + Terminal scheme
    Phase 4  Personal layer ....... this repo's catalog/* tasks (the delta)
    Phase 5  WSL install.sh ....... run this repo's install.sh inside the distro

  Microsoft's WindowsDeveloperConfig (vendored under vendor\WindowsDeveloperConfig)
  is the base "full setup"; this repo layers only the personal delta on top. Every
  phase is idempotent, so the whole script is safe to re-run -- including after a
  reboot triggered by the WDC base setup on a fresh machine.

  See vendor\WindowsDeveloperConfig\PROVENANCE.md for what is vendored and how to
  re-sync it.

.PARAMETER Distro
  WSL distro to target for Phases 3 and 5. Default: 'Ubuntu'.

.PARAMETER SkipWdc
  Skip Phase 2 (the vendored WindowsDeveloperConfig base setup).

.PARAMETER SkipWslComfort
  Skip Phase 3 (the vendored wsl-comfort setup).

.PARAMETER SkipPersonal
  Skip Phase 4 (the personal catalog/* layer).

.PARAMETER SkipWsl
  Skip Phase 5 (auto-running install.sh inside WSL).

.PARAMETER IncludeAppxPrune
  Include the aggressive appx-prune task in Phase 4 (opt-in; it removes most
  provisioned Appx packages that are not on the keep-list).

.EXAMPLE
  # Full setup, from an *elevated* PowerShell:
  .\install.ps1

.EXAMPLE
  # Windows only; run install.sh yourself later inside WSL:
  .\install.ps1 -SkipWsl

.EXAMPLE
  # Re-apply just the personal layer:
  .\install.ps1 -SkipWdc -SkipWslComfort -SkipWsl
#>
[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu',
    [switch]$SkipWdc,
    [switch]$SkipWslComfort,
    [switch]$SkipPersonal,
    [switch]$SkipWsl,
    [switch]$IncludeAppxPrune
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

function Write-Phase([string]$Number, [string]$Message) {
    Write-Host ''
    Write-Host "=== [Phase $Number] $Message ===" -ForegroundColor Cyan
}
function Write-Info([string]$Message) { Write-Host "    $Message" -ForegroundColor DarkGray }

function Update-SessionPath {
    # winget/installers update the *registry* PATH but not this running process.
    # Rehydrate so later phases can see freshly installed executables.
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

# --- Phase 0: Preflight ----------------------------------------------------
Write-Phase '0' 'Preflight (admin, winget, configure enable)'

$IsUserAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544')
if (-not $IsUserAdmin) {
    Write-Error 'You need to run this script as an admin user.' -Category AuthenticationError
    exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error @'
winget (App Installer) was not found on PATH. Install "App Installer" from the
Microsoft Store (or the latest MSIX from
https://github.com/microsoft/winget-cli/releases/latest), then re-run this script.
'@ -Category NotInstalled
    exit 1
}

try {
    Write-Info 'Ensuring "winget configure" is enabled...'
    winget configure --enable 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "'winget configure --enable' returned exit $LASTEXITCODE (continuing)."
    }
} catch {
    Write-Warning "Could not run 'winget configure --enable' (continuing): $($_.Exception.Message)"
}

# --- Phase 1: Resolve vendored WindowsDeveloperConfig ----------------------
Write-Phase '1' 'Resolve vendored WindowsDeveloperConfig'

$vendorRoot  = Join-Path $repoRoot 'vendor\WindowsDeveloperConfig'
$wdcConfig   = Join-Path $vendorRoot 'windows-dev-config\dev-config.winget'
$wslComfort  = Join-Path $vendorRoot 'wsl-comfort\install.ps1'

foreach ($p in @($wdcConfig, $wslComfort)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Write-Error @"
Vendored WindowsDeveloperConfig asset missing:
  $p
Restore it per vendor\WindowsDeveloperConfig\PROVENANCE.md, then re-run.
"@ -Category ObjectNotFound
        exit 1
    }
}
Write-Info "WDC config : $wdcConfig"
Write-Info "wsl-comfort: $wslComfort"

# --- Phase 2: WindowsDeveloperConfig base setup ----------------------------
if ($SkipWdc) {
    Write-Phase '2' 'WDC base setup [SKIPPED -SkipWdc]'
} else {
    Write-Phase '2' 'WDC base setup (winget configure)'
    Write-Info 'On a fresh machine this may reboot (WDC resumes itself via RunOnce);'
    Write-Info 'if it does, just re-run install.ps1 afterward.'
    # Flags mirror WindowsDeveloperConfig's own apply-configuration.ps1.
    # NOTE: --accept-package-agreements is NOT valid on `winget configure`;
    # package consent flows through --accept-configuration-agreements.
    winget configure --file $wdcConfig --accept-configuration-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget configure (WDC base setup) failed with exit code $LASTEXITCODE."
    }
    Update-SessionPath
}

# --- Phase 3: wsl-comfort --------------------------------------------------
if ($SkipWslComfort) {
    Write-Phase '3' 'wsl-comfort [SKIPPED -SkipWslComfort]'
} else {
    Write-Phase '3' "wsl-comfort (Comfort Shell + '$Distro')"
    # wsl-comfort runs wsl.exe/native tools internally and signals real failures by
    # throwing (it sets its own $ErrorActionPreference='Stop'), so rely on try/catch.
    # We deliberately do NOT check $LASTEXITCODE here: a benign non-zero from its last
    # internal native call would otherwise be misread as a failure.
    try {
        & $wslComfort -NonInteractive -Distro $Distro
    } catch {
        Write-Warning "wsl-comfort failed (continuing): $($_.Exception.Message)"
    }
    Update-SessionPath
}

# --- Phase 4: Personal catalog layer ---------------------------------------
if ($SkipPersonal) {
    Write-Phase '4' 'Personal layer [SKIPPED -SkipPersonal]'
} else {
    Write-Phase '4' 'Personal layer (catalog tasks)'

    $catalogTasks = @(
        'winget-core',
        'choco-fonts',
        'modules-install',
        'path-llvm',
        'windows-features'
    )
    if ($IncludeAppxPrune) { $catalogTasks += 'appx-prune' }
    $catalogTasks += @(
        'dev-settings',
        'powershell-profiles',
        'dotfiles-links',
        'verify-baseline'
    )

    foreach ($task in $catalogTasks) {
        $taskScript = Join-Path $repoRoot "catalog\$task\script.ps1"
        if (-not (Test-Path -LiteralPath $taskScript)) {
            Write-Warning "[skip] catalog task '$task' not found ($taskScript)."
            continue
        }
        Write-Host ''
        Write-Host "--- catalog: $task ---" -ForegroundColor Green
        # Reset first so verify-baseline's fall-through success (it only `exit 1`s on
        # failure, and never `exit 0`s) isn't misread as a prior task's stale exit code.
        $global:LASTEXITCODE = 0
        try {
            & $taskScript
            # Only verify-baseline uses its exit code as a pass/fail contract. Other
            # tasks may leave benign non-zero native codes (dism 3010 = reboot-required,
            # winget "already installed"), so a generic non-zero is NOT a failure here.
            if ($task -eq 'verify-baseline' -and $LASTEXITCODE -ne 0) {
                Write-Warning "verify-baseline found missing items (exit $LASTEXITCODE); re-run install.ps1 if needed."
            }
        } catch {
            Write-Warning "catalog task '$task' failed (continuing): $($_.Exception.Message)"
        }
    }
    Update-SessionPath
}

# --- Phase 5: WSL install.sh -----------------------------------------------
if ($SkipWsl) {
    Write-Phase '5' 'WSL install.sh [SKIPPED -SkipWsl]'
} else {
    Write-Phase '5' "WSL install.sh (inside '$Distro')"

    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Warning 'wsl.exe not found; skipping install.sh. Re-run install.ps1 once WSL is installed.'
    } else {
        # Verify the distro is registered and can run a shell before invoking install.sh.
        $probe = (& wsl.exe -d $Distro -- bash -lc 'echo __WSL_OK__' 2>$null)
        if ($LASTEXITCODE -ne 0 -or ("$probe" -notmatch '__WSL_OK__')) {
            Write-Warning @"
WSL distro '$Distro' is not ready (exit=$LASTEXITCODE). Skipping install.sh.
If a reboot is pending or the distro is still initializing, re-run install.ps1
(or run it yourself): wsl -d $Distro --cd '<repo>' -- bash -lc 'bash ./install.sh'
"@
        } else {
            # Resolve this repo's path as WSL sees it (Linux mount path) for the working
            # directory and an informational line. Forward slashes keep wslpath happy;
            # fall back to the Windows path if resolution fails.
            $repoWsl = (& wsl.exe -d $Distro -- wslpath -a ($repoRoot -replace '\\', '/') 2>$null | Select-Object -First 1)
            if ($repoWsl) { $repoWsl = $repoWsl.Trim() }
            $cdTarget = if ([string]::IsNullOrWhiteSpace($repoWsl)) { $repoRoot } else { $repoWsl }

            if ($repoWsl) { Write-Info "Repo path in WSL: $repoWsl" }
            Write-Info 'Running install.sh (it may prompt for your WSL sudo password)...'
            # `wsl --cd` sets the working directory from a *native* argv, so the repo
            # path is never interpolated into a shell string -- immune to spaces,
            # quotes, and shell injection (unlike `bash -lc "cd '<path>' && ..."`).
            & wsl.exe -d $Distro --cd $cdTarget -- bash -lc 'bash ./install.sh'
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "install.sh exited with code $LASTEXITCODE inside '$Distro'."
            } else {
                Write-Info 'install.sh completed.'
            }
        }
    }
}

Write-Host ''
Write-Host '=== install.ps1 finished ===' -ForegroundColor Cyan
Write-Info 'If the WDC base setup reboots the machine, re-run install.ps1 after logging back in.'
