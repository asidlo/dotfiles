<#
.SYNOPSIS
  Bootstraps a Windows developer workstation in one elevated run.

.DESCRIPTION
  A thin, idempotent, phased orchestrator:

    Phase 0  Preflight ............ admin guard, assert winget, enable configure, start log,
                                    up-front prompts (WSL password, ADO sign-in for nfv-clone)
    Phase 1  Resolve vendored WDC . verify vendored WindowsDeveloperConfig assets
    Phase 2  WDC base setup ....... `winget configure` the vendored dev-config.winget
    Phase 3  wsl-comfort .......... WSL + "Comfort Shell" + Terminal scheme
    Phase 4  Personal layer ....... this repo's catalog/* tasks (the delta)
    Phase 5  WSL provisioning ..... non-root default user, dev-drive move, /root cleanup
    Phase 6  WSL install.sh ....... clone this repo *into* the distro, then run its install.sh
    Phase 7  Updates .............. opt-in (-InstallUpdates): winget upgrades, then Windows Update
    Phase 8  Verify baseline ...... catalog/verify-baseline, once everything above has run

  With -Restart, the machine restarts after a clean run.

  Microsoft's WindowsDeveloperConfig (vendored under vendor\WindowsDeveloperConfig)
  is the base "full setup"; this repo layers only the personal delta on top. Every
  phase is idempotent, so the whole script is safe to re-run -- including after a
  reboot triggered by the WDC base setup on a fresh machine.

  Nothing fails silently. Every phase and every catalog task is wrapped in a
  failure ledger that captures terminating errors, the error stream, and the
  native exit code. The run ends with a summary table, a full transcript, and a
  machine-readable JSON ledger, and exits non-zero if anything failed.

  See vendor\WindowsDeveloperConfig\PROVENANCE.md for what is vendored and how to
  re-sync it.

.PARAMETER Distro
  WSL distro to target for Phases 3, 5 and 6. Default: 'Ubuntu'.

.PARAMETER WslUser
  Non-root default user to create inside the distro. wsl-comfort suppresses the
  Ubuntu OOBE, so without this the distro has no user and install.sh would run as
  root. Default: your Windows username, lower-cased and sanitised -- or, when the
  distro already has a non-root default user, that user. Must be a valid Linux
  user name.

.PARAMETER WslPassword
  Password for -WslUser, as a SecureString. Prompted for during Phase 0 when
  omitted and the session is interactive. It is piped to `chpasswd` over stdin
  and never appears in argv, the transcript, or the ledger.

.PARAMETER WslDotfilesDir
  Where Phase 6 clones this repo inside the distro, relative to -WslUser's home
  unless given as an absolute path. Default: '.local/src/dotfiles'.

  Phase 6 used to run install.sh directly off the Windows checkout, so every
  symlink it created pointed back across the 9p/drvfs boundary at /mnt. Those
  links resolve, but they are slow (a `eza -la --git` listing costs ~17s on
  drvfs against ~90ms on ext4), they break whenever the Dev Drive is not
  mounted, and drvfs reports every file as mode 0777 regardless of the git
  index. A native clone removes the boundary.

.PARAMETER WslDotfilesRepoUrl
  Remote Phase 6 clones -WslDotfilesDir from.
  Default: 'https://github.com/asidlo/dotfiles'.

  Only pushed commits reach the distro. Push first if you want Phase 6 to pick
  up work you just did on the Windows side.

.PARAMETER ArtifactRoot
  Dev Drive root for build/package artifacts and run logs. Every dev-drive
  environment variable (NUGET_PACKAGES, npm_config_cache, GOPATH, CARGO_HOME,
  ...) is derived from this. Default: 'Q:\.tools'.

.PARAMETER SrcRoot
  Dev Drive root for source repositories. Default: 'Q:\src'.

.PARAMETER NfvRepoUrl
  Azure DevOps remote for the Networking-nfv repository.

.PARAMETER NfvRepoPath
  Clone destination for Networking-nfv. Also where NFV.vsconfig is read from.
  Default: "<SrcRoot>\Networking-nfv".

.PARAMETER VsInstallPath
  Install location for Visual Studio 2022 Enterprise. Installed side-by-side
  with any newer Visual Studio; the newer install is never modified.

.PARAMETER LogPath
  Directory for the run transcript and JSON ledger. Default: "<ArtifactRoot>\logs".

.PARAMETER MoveWslToDevDrive
  Relocate the distro's ext4.vhdx off C: to "<ArtifactRoot>\wsl\<Distro>".
  Default: $true. Skipped (not failed) when the target drive lacks the space.
  Disable with -MoveWslToDevDrive:$false.

.PARAMETER CleanStaleRootDotfiles
  Remove the dotfile symlinks a previous root-run of install.sh left under
  /root. Only symlinks resolving into this repo are removed. Default: $true.

.PARAMETER WslTempPasswordlessSudo
  Write /etc/sudoers.d/99-dotfiles-install granting -WslUser NOPASSWD sudo for
  the duration of Phase 6, then remove it. Default: $true.

  Phase 6 runs install.sh through Invoke-Step, which captures its output, so the
  distro gets no controlling pty. Without this, `sudo -v` prompts on a terminal
  nobody can answer and Phase 6 dies on sudo's five-minute passwd_timeout; and
  because sudo's timestamp_type=tty degrades to `ppid` with no tty, an answered
  prompt would not carry into the per-tool scripts install.sh spawns anyway.

  Disable with -WslTempPasswordlessSudo:$false and run install.sh yourself from
  an interactive shell, or grant the user passwordless sudo permanently.

.PARAMETER ContinueOnError
  Collect failures and report them at the end rather than aborting on the first
  one. Default: $true. The process still exits non-zero when anything failed.

.PARAMETER RestartExplorer
  Let the dev-settings task restart Explorer. Off by default -- killing Explorer
  mid-install is disruptive, and the affected settings apply on next sign-in.

.PARAMETER InstallUpdates
  Add Phase 7: upgrade every winget package `winget upgrade` lists
  (catalog/winget-upgrade), then install the updates Windows Update would
  install on its own, plus the feature update Settings offers with "Download &
  install" (catalog/windows-update; optional and preview updates are left
  out). Off by default.

  Packages hosting this run (PowerShell 7, Windows Terminal, VS Code) are held
  back, because upgrading them closes the console the run lives in; upgrade
  them afterwards from another shell. Some Windows updates are only offered
  after the restart the previous round asks for, and a feature update can wait
  for that restart too, so re-run after restarting to pick those up.

.PARAMETER Restart
  Restart the machine 60 seconds after the run finishes (cancel with
  `shutdown /a`). Off by default. Only after a clean run: when a step failed or
  the run stopped early, the machine stays up so the summary stays on screen.

.PARAMETER NonInteractive
  Never prompt. -WslPassword is left unset and the WSL user is created without a
  password (set one later with `sudo passwd <user>`). The Phase 0 Azure DevOps
  sign-in for nfv-clone is skipped too, so the clone relies on a cached credential.

.PARAMETER SkipWdc
  Skip Phase 2 (the vendored WindowsDeveloperConfig base setup).

.PARAMETER SkipWslComfort
  Skip Phase 3 (the vendored wsl-comfort setup).

.PARAMETER SkipPersonal
  Skip Phase 4 (the personal catalog/* layer) and Phase 8 (verify-baseline).

.PARAMETER SkipWsl
  Skip Phases 5 and 6 (WSL provisioning and install.sh).

.PARAMETER SkipDevDriveEnv
  Skip the devdrive-env catalog task.

.PARAMETER SkipNfvClone
  Leave Networking-nfv alone: no check for the clone, no Phase 0 sign-in, and no
  nfv-clone task.

  Without it, Phase 0 checks for "<NfvRepoPath>\.git". When the clone is missing,
  Phase 0 has you sign in to Git Credential Manager (installing Git first
  if needed) so the Phase 4 clone runs unattended. If that sign-in fails, the
  clone is skipped instead of prompting mid-run.

.PARAMETER SkipVisualStudio
  Skip the visualstudio catalog task.

.EXAMPLE
  # Full setup, from an *elevated* PowerShell:
  .\install.ps1

.EXAMPLE
  # Windows only; run install.sh yourself later inside WSL:
  .\install.ps1 -SkipWsl

.EXAMPLE
  # Re-apply just the personal layer, leaving the WSL disk where it is:
  .\install.ps1 -SkipWdc -SkipWslComfort -SkipWsl

.EXAMPLE
  # Personal machine: don't check for, sign in for, or clone Networking-nfv:
  .\install.ps1 -SkipNfvClone -SkipVisualStudio

.EXAMPLE
  # Unattended, artifacts on a different Dev Drive, keep the WSL disk on C::
  .\install.ps1 -NonInteractive -ArtifactRoot 'D:\.tools' -MoveWslToDevDrive:$false

.EXAMPLE
  # New machine: set everything up, install all updates, then restart if nothing failed:
  .\install.ps1 -InstallUpdates -Restart
#>
[CmdletBinding()]
param(
    [string]$Distro = 'Ubuntu',
    [string]$WslUser = $(if ($env:USERNAME) { $env:USERNAME.ToLower() -replace '[^a-z0-9_-]', '' } else { 'dev' }),
    [securestring]$WslPassword,
    [string]$WslDotfilesDir = '.local/src/dotfiles',
    [string]$WslDotfilesRepoUrl = 'https://github.com/asidlo/dotfiles',
    [string]$ArtifactRoot = 'Q:\.tools',
    [string]$SrcRoot = 'Q:\src',
    [string]$NfvRepoUrl = 'https://msazure.visualstudio.com/One/_git/Networking-nfv',
    [string]$NfvRepoPath = (Join-Path $SrcRoot 'Networking-nfv'),
    [string]$VsInstallPath = 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise',
    [string]$LogPath = (Join-Path $ArtifactRoot 'logs'),
    [bool]$MoveWslToDevDrive = $true,
    [bool]$CleanStaleRootDotfiles = $true,
    [bool]$WslTempPasswordlessSudo = $true,
    [bool]$ContinueOnError = $true,
    [switch]$RestartExplorer,
    [switch]$InstallUpdates,
    [switch]$Restart,
    [switch]$NonInteractive,
    [switch]$SkipWdc,
    [switch]$SkipWslComfort,
    [switch]$SkipPersonal,
    [switch]$SkipWsl,
    [switch]$SkipDevDriveEnv,
    [switch]$SkipNfvClone,
    [switch]$SkipVisualStudio
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

# --- Failure ledger --------------------------------------------------------
# The previous version of this script reported success while installing nothing:
# it only caught *terminating* errors, so a task that merely returned a non-zero
# exit code (or wrote to the error stream) looked green. Every step now runs
# through Invoke-Step, which watches all three failure channels.

$script:Ledger = New-Object System.Collections.Generic.List[object]
$script:RunStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$script:TranscriptPath = $null
$script:TranscriptStarted = $false

function Write-Phase([string]$Number, [string]$Message) {
    Write-Host ''
    Write-Host "=== [Phase $Number] $Message ===" -ForegroundColor Cyan
}
function Write-Info([string]$Message) { Write-Host "    $Message" -ForegroundColor DarkGray }

function Add-Result {
    param(
        [Parameter(Mandatory)][string]$Phase,
        [Parameter(Mandatory)][string]$Task,
        [ValidateSet('Ok', 'Warning', 'Failed', 'Skipped')][string]$Status = 'Ok',
        [int]$ExitCode = 0,
        [string]$Message = '',
        [string[]]$Detail = @(),
        [string]$Hint = '',
        [timespan]$Duration = [timespan]::Zero
    )
    $script:Ledger.Add([pscustomobject]@{
            Timestamp = (Get-Date).ToString('o')
            Phase     = $Phase
            Task      = $Task
            Status    = $Status
            ExitCode  = $ExitCode
            Duration  = $Duration.ToString('hh\:mm\:ss')
            Message   = $Message
            Detail    = $Detail
            Hint      = $Hint
        })
}

function Get-StatusColor([string]$Status) {
    switch ($Status) {
        'Ok' { 'Green' }
        'Warning' { 'Yellow' }
        'Failed' { 'Red' }
        'Skipped' { 'DarkGray' }
        default { 'Gray' }
    }
}

<#
  Runs $Action and records exactly what happened.

  Captured failure channels:
    1. Terminating errors      -> try/catch
    2. The error stream (2>)   -> merged into the pipeline and collected
    3. $LASTEXITCODE           -> read after the call

  Non-terminating errors are recorded as 'Warning' rather than 'Failed' because
  plenty of well-behaved native tools (git, dism, winget) write progress to
  stderr. Only a throw, or a non-zero exit on a step marked -ExitCodeIsContract,
  is a real failure.
#>
function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Phase,
        [Parameter(Mandatory)][string]$Task,
        [Parameter(Mandatory)][scriptblock]$Action,
        [string]$Hint = '',
        [switch]$ExitCodeIsContract
    )

    Write-Host ''
    Write-Host "--- $Task ---" -ForegroundColor Green

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $captured = New-Object System.Collections.Generic.List[string]
    $errorLines = New-Object System.Collections.Generic.List[string]
    $status = 'Ok'
    $message = ''
    $global:LASTEXITCODE = 0

    $previousEap = $ErrorActionPreference
    try {
        # 'Continue' here so a native tool's stderr becomes a collectable
        # ErrorRecord instead of a terminating NativeCommandError.
        $ErrorActionPreference = 'Continue'
        & $Action 2>&1 3>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $line = "$($_.Exception.Message)".TrimEnd()
                if ($line) {
                    $errorLines.Add($line)
                    $captured.Add("ERROR: $line")
                    Write-Host "    ! $line" -ForegroundColor Red
                }
            } elseif ($_ -is [System.Management.Automation.WarningRecord]) {
                $line = "$($_.Message)".TrimEnd()
                $captured.Add("WARNING: $line")
                Write-Host "    ~ $line" -ForegroundColor Yellow
            } else {
                $line = "$_"
                $captured.Add($line)
                Write-Host $line
            }
        }
    } catch {
        $status = 'Failed'
        $message = $_.Exception.Message
        $captured.Add("EXCEPTION: $message")
        Write-Host "    ! $message" -ForegroundColor Red
    } finally {
        $ErrorActionPreference = $previousEap
        $sw.Stop()
    }

    $exit = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }

    if ($status -ne 'Failed') {
        if ($ExitCodeIsContract -and $exit -ne 0) {
            $status = 'Failed'
            $message = "exited with code $exit"
        } elseif ($errorLines.Count -gt 0) {
            $status = 'Warning'
            $message = $errorLines[0]
        }
    }

    # Keep the tail of the output for the summary; the transcript has it all.
    $detail = @()
    if ($status -ne 'Ok' -and $captured.Count -gt 0) {
        $take = [Math]::Min(20, $captured.Count)
        $detail = $captured[($captured.Count - $take)..($captured.Count - 1)]
    }

    Add-Result -Phase $Phase -Task $Task -Status $status -ExitCode $exit `
        -Message $message -Detail $detail -Hint $Hint -Duration $sw.Elapsed

    Write-Host ("    [{0}] {1} ({2})" -f $status, $Task, $sw.Elapsed.ToString('hh\:mm\:ss')) `
        -ForegroundColor (Get-StatusColor $status)

    if ($status -eq 'Failed' -and -not $ContinueOnError) {
        throw "Step '$Task' failed and -ContinueOnError is `$false."
    }
    # A step's exit code must not leak into the next step's evaluation.
    $global:LASTEXITCODE = 0
}

function Update-SessionPath {
    # winget/installers update the *registry* PATH but not this running process.
    # Rehydrate so later phases can see freshly installed executables. The old
    # script only did this once per phase, so verify-baseline reported every tool
    # missing even when it had just been installed.
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

# Some installers show modal prompts that no silent switch can suppress (NVM for
# Windows 2.0.0 uses a plain Inno Setup MsgBox rather than SuppressibleMsgBox, so
# winget's /SUPPRESSMSGBOXES is ignored). These block `winget configure` (and an
# upgrade to 2.0.0 in Phase 7) until someone clicks, so a background watcher
# answers exactly these known dialogs.
$AutoConfirmDialogs = @(
    @{ Text = 'An existing NVM for Windows installation was detected'; Button = 6 }  # IDYES
)

function Start-DialogAutoConfirm {
    if (-not ('DotfilesDialogAutoConfirm' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class DotfilesDialogAutoConfirm {
    private delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] private static extern bool EnumChildWindows(IntPtr parent, EnumProc cb, IntPtr lParam);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] private static extern IntPtr GetDlgItem(IntPtr hDlg, int id);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] private static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, IntPtr wParam, StringBuilder lParam, uint flags, uint timeoutMs, out IntPtr result);
    [DllImport("user32.dll")] private static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    private const uint WM_GETTEXT = 0x000D;
    private const uint WM_COMMAND = 0x0111;
    private const uint SMTO_ABORTIFHUNG = 0x0002;

    private static string ClassOf(IntPtr hWnd) {
        var sb = new StringBuilder(256);
        GetClassName(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }

    // WM_GETTEXT (not GetWindowText) is required to read controls owned by another process.
    private static string TextOf(IntPtr hWnd) {
        var sb = new StringBuilder(4096);
        IntPtr ignored;
        SendMessageTimeout(hWnd, WM_GETTEXT, (IntPtr)sb.Capacity, sb, SMTO_ABORTIFHUNG, 1000, out ignored);
        return sb.ToString();
    }

    // Clicks buttonId on every visible dialog (#32770) whose text contains textFragment.
    public static int Confirm(string textFragment, int buttonId) {
        int confirmed = 0;
        EnumWindows((top, _) => {
            if (!IsWindowVisible(top) || ClassOf(top) != "#32770") return true;
            IntPtr button = GetDlgItem(top, buttonId);
            if (button == IntPtr.Zero) return true;
            bool match = false;
            EnumChildWindows(top, (child, __) => {
                if (TextOf(child).IndexOf(textFragment, StringComparison.OrdinalIgnoreCase) >= 0) { match = true; return false; }
                return true;
            }, IntPtr.Zero);
            if (match && PostMessage(top, WM_COMMAND, (IntPtr)buttonId, button)) confirmed++;
            return true;
        }, IntPtr.Zero);
        return confirmed;
    }
}
'@
    }

    $state = [hashtable]::Synchronized(@{ Stop = $false; Confirmed = 0 })
    $ps = [powershell]::Create()
    [void]$ps.AddScript({
            param($state, $dialogs)
            while (-not $state.Stop) {
                foreach ($d in $dialogs) {
                    $state.Confirmed += [DotfilesDialogAutoConfirm]::Confirm($d.Text, $d.Button)
                }
                Start-Sleep -Milliseconds 500
            }
        }).AddArgument($state).AddArgument($AutoConfirmDialogs)
    $handle = $ps.BeginInvoke()
    return @{ State = $state; PowerShell = $ps; Handle = $handle }
}

function Stop-DialogAutoConfirm($Watcher) {
    if (-not $Watcher) { return }
    $Watcher.State.Stop = $true
    try { [void]$Watcher.PowerShell.EndInvoke($Watcher.Handle) } catch { }
    $Watcher.PowerShell.Dispose()
    if ($Watcher.State.Confirmed -gt 0) {
        Write-Host "[dialogs] auto-confirmed $($Watcher.State.Confirmed) installer prompt(s)"
    }
}

# useradd's default NAME_REGEX; also what `wsl.exe -u` can pass through intact.
$LinuxUserPattern = '^[a-z_][a-z0-9_-]{0,31}$'

<#
  Names of the units `winget configure` reported as failed. Each unit prints a
  header ending in "[<name>]" followed by its result line.
#>
function Get-WdcFailedUnits([string[]]$Lines) {
    $unit = $null
    foreach ($line in $Lines) {
        if ($line -match '\[([^\]]+)\]\s*$') { $unit = $Matches[1] }
        elseif ($unit -and $line -match 'configuration unit failed') { $unit; $unit = $null }
    }
}

# Highest machine-installed Node.js MSI version, or $null.
function Get-InstalledNodeVersion {
    $versions = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq 'Node.js' -and $_.DisplayVersion } |
        ForEach-Object { $_.DisplayVersion -as [version] } | Where-Object { $_ }
    $versions | Sort-Object -Descending | Select-Object -First 1
}

# The version `winget install --id <Id>` would install, or $null.
function Get-WingetLatestVersion([string]$Id) {
    $out = @(winget show --id $Id --exact --accept-source-agreements --disable-interactivity 2>$null)
    $global:LASTEXITCODE = 0
    $line = $out | Where-Object { "$_" -match '^\s*Version:\s*(\S+)' } | Select-Object -First 1
    if ($line -and "$line" -match '^\s*Version:\s*(\S+)') { return $Matches[1] -as [version] }
    return $null
}

function ConvertFrom-SecureStringPlain([securestring]$Secure) {
    if (-not $Secure) { return '' }
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function ConvertTo-WslPath([string]$WindowsPath) {
    $probe = (& wsl.exe -d $Distro -u root -- wslpath -a ($WindowsPath -replace '\\', '/') 2>$null | Select-Object -First 1)
    $global:LASTEXITCODE = 0
    if ($probe) { return $probe.Trim() }
    return $null
}

function Get-WslDistroRegistration([string]$Name) {
    Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue |
        ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
        Where-Object { $_.DistributionName -eq $Name } |
        Select-Object -First 1
}

<#
  Grants or revokes the temporary passwordless-sudo drop-in Phase 6 runs behind.

  Invoke-Step captures install.sh's output through a PowerShell pipeline, which
  leaves the distro with no controlling pty: `sudo -v` prompts on a terminal
  nobody can answer and dies on sudo's five-minute passwd_timeout. And with no
  tty, sudo's timestamp_type=tty degrades to `ppid`, so an answered prompt would
  not even carry into the per-tool scripts install.sh spawns.

  -Mode revoke is best-effort and never throws: it runs before every grant (to
  clear a drop-in a killed run left behind) and in Phase 6's finally block.
#>
function Set-WslTempSudo {
    param(
        [Parameter(Mandatory)][ValidateSet('grant', 'revoke')][string]$Mode,
        [switch]$Quiet
    )

    $helperWin = Join-Path $repoRoot 'scripts\wsl-sudoers-temp.sh'
    if (-not (Test-Path -LiteralPath $helperWin)) { throw "Missing helper: $helperWin" }
    $helper = ConvertTo-WslPath $helperWin
    if (-not $helper) { throw "Could not resolve '$helperWin' inside '$Distro'." }

    $sudoArgs = @($Mode)
    if ($Mode -eq 'grant') { $sudoArgs += $WslUser }

    $output = @(& wsl.exe -d $Distro -u root -- bash "$helper" @sudoArgs 2>&1)
    $code = $LASTEXITCODE
    $global:LASTEXITCODE = 0

    if (-not $Quiet) { $output | Where-Object { "$_".Trim() } | ForEach-Object { Write-Host "$_" } }
    return $code
}

<#
.SYNOPSIS
  True when $Distro exists and can run a command as root.
#>
function Test-WslDistroReady {
    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $false }
    $probe = (& wsl.exe -d $Distro -u root -- echo __WSL_OK__ 2>$null)
    $ok = ($LASTEXITCODE -eq 0 -and "$probe" -match '__WSL_OK__')
    $global:LASTEXITCODE = 0
    return $ok
}

<#
.SYNOPSIS
  Installs the temporary passwordless-sudo drop-in. Idempotent per run.

  Called once before Phase 3 and again at Phase 6. Phase 3's wsl-comfort
  authenticates sudo three separate times of its own (comfort-shell-bootstrap.sh
  warms the timestamp up, the Homebrew install it shells out to warms it again,
  and apt needs it), so granting this only at Phase 6 -- as it used to -- left
  the user answering the same prompt several times per run.

  -Optional makes the early attempt skip quietly rather than fail: on a fresh
  machine Phase 3 is what creates the distro, so neither it nor $WslUser
  necessarily exists yet. Phase 6 then grants it instead.
#>
function Grant-WslTempSudo {
    param(
        [Parameter(Mandatory)][string]$Phase,
        [switch]$Optional
    )

    if ($script:WslSudoGranted) { return }

    if ($Optional) {
        if (-not (Test-WslDistroReady)) {
            Add-Result -Phase $Phase -Task 'wsl-sudo-temp' -Status 'Skipped' `
                -Message "distro '$Distro' not ready yet; Phase 6 grants it instead"
            return
        }
        $null = (& wsl.exe -d $Distro -u root -- id -u $WslUser 2>$null)
        $userReady = ($LASTEXITCODE -eq 0)
        $global:LASTEXITCODE = 0
        if (-not $userReady) {
            Add-Result -Phase $Phase -Task 'wsl-sudo-temp' -Status 'Skipped' `
                -Message "user '$WslUser' does not exist yet; Phase 6 grants it instead"
            return
        }
    }

    Invoke-Step -Phase $Phase -Task 'wsl-sudo-temp' `
        -Hint "Grant it by hand: wsl -d $Distro -u root -- bash scripts/wsl-sudoers-temp.sh grant $WslUser" -Action {
        # Clear a drop-in an earlier, killed run may have left behind before
        # writing a fresh one.
        Set-WslTempSudo -Mode revoke -Quiet | Out-Null

        # Mark *before* the attempt: a partial grant (file written, verification
        # failed) still has to be revoked afterwards.
        $script:WslSudoGranted = $true
        $code = Set-WslTempSudo -Mode grant
        if ($code -ne 0) { throw "Could not grant temporary passwordless sudo (exit $code)." }
    }
}

<#
.SYNOPSIS
  Removes the drop-in if this run installed one. Safe to call twice.

  The grant now spans Phases 3-6, so this also runs from the top-level finally:
  that is the only place guaranteed to execute when a phase between them throws.
#>
function Revoke-WslTempSudo {
    param([Parameter(Mandatory)][string]$Phase)

    if (-not $script:WslSudoGranted) { return }

    # This runs from a finally block, so it must never propagate a terminating
    # error -- that would replace the failure that got us here. Invoke-Step
    # rethrows failed steps when -ContinueOnError:$false, and Set-WslTempSudo
    # itself throws on a missing helper or an unresolvable WSL path, so the
    # whole call is bracketed rather than trusted to stay non-terminating.
    try {
        Invoke-Step -Phase $Phase -Task 'wsl-sudo-revoke' `
            -Hint "Remove it by hand: wsl -d $Distro -u root -- rm -f /etc/sudoers.d/99-dotfiles-install" -Action {
            $code = Set-WslTempSudo -Mode revoke
            if ($code -ne 0) {
                # Throw so the step lands as Failed, not Warning: leaving
                # NOPASSWD sudo behind must set a non-zero exit code rather
                # than let the run report success.
                throw "Could not remove /etc/sudoers.d/99-dotfiles-install (exit $code). Remove it by hand."
            }
            $script:WslSudoGranted = $false
        }
    } catch {
        # Already recorded as Failed by Invoke-Step; swallow so the finally
        # unwinds cleanly. WslSudoGranted stays true so a later revoke retries.
        Write-Host "    ! revoke did not complete: $($_.Exception.Message)" -ForegroundColor Red
    }

    if ($script:WslSudoGranted) { $script:ExitCode = 1 }
}

<#
.SYNOPSIS
  Signs in to Azure DevOps during Phase 0 when Networking-nfv still has to be cloned.

  Otherwise Git Credential Manager's sign-in only appears when nfv-clone runs in
  Phase 4, long after whoever started the run has walked away, so the clone
  either waits on an unattended window or fails on auth. `git ls-remote` drives
  the same GCM flow the clone uses, and git stores the credential on success, so
  the Phase 4 clone reuses it without prompting. With a cached credential this
  returns without prompting at all.

  Git normally arrives with the WDC base setup in Phase 2, which is too late, so
  a fresh machine gets Git.Git from winget here first. WDC then finds it present.
#>
function Invoke-NfvSignIn {
    # Mark before the attempt: anything short of a confirmed sign-in skips the
    # Phase 4 clone rather than letting it prompt mid-run.
    $script:NfvSignInFailed = $true

    Invoke-Step -Phase '0' -Task 'nfv-sign-in' `
        -Hint "Sign in by hand with: git ls-remote $NfvRepoUrl HEAD -- then re-run install.ps1 (or pass -SkipNfvClone)" -Action {
        Update-SessionPath
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host '[nfv] git not found; installing Git.Git now so you can sign in before the long phases start'
            $wingetOut = @(& winget install --id Git.Git --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity -h 2>&1)
            $wingetExit = $LASTEXITCODE
            $global:LASTEXITCODE = 0
            Update-SessionPath
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                $tail = @($wingetOut | ForEach-Object { $(if ($_ -is [System.Management.Automation.ErrorRecord]) { "$($_.Exception.Message)" } else { "$_" }) } |
                        Where-Object { $_.Trim() } | Select-Object -Last 5) -join ' | '
                throw "Could not install Git (winget exit $wingetExit): $tail"
            }
        }

        Write-Host "[nfv] $NfvRepoPath is missing; signing in to $NfvRepoUrl now so the Phase 4 clone runs unattended"
        Write-Host '[nfv] complete the Git Credential Manager sign-in if a window opens'
        $gitLines = New-Object System.Collections.Generic.List[string]
        # Streamed rather than collected so a device-code or browser hint from GCM
        # shows up while it is waiting, not after.
        & git ls-remote $NfvRepoUrl HEAD 2>&1 | ForEach-Object {
            # Exception.Message, not "$_": Windows PowerShell renders a blank stderr
            # line as "System.Management.Automation.RemoteException".
            $line = $(if ($_ -is [System.Management.Automation.ErrorRecord]) { "$($_.Exception.Message)" } else { "$_" }).TrimEnd()
            if (-not $line) { return }
            $gitLines.Add($line)
            if ($line -notmatch '^[0-9a-f]{40}\s') { Write-Host "[nfv] $line" }
        }
        $gitExit = $LASTEXITCODE
        $global:LASTEXITCODE = 0
        if ($gitExit -ne 0) {
            $tail = @($gitLines | Select-Object -Last 5) -join ' | '
            throw "Sign-in to $NfvRepoUrl failed (git exit $gitExit); nfv-clone will be skipped. $tail"
        }

        $script:NfvSignInFailed = $false
        Write-Host '[nfv] signed in; repository access confirmed'
    }
}

function Write-RunSummary {
    Write-Host ''
    Write-Host '=== Run summary ===' -ForegroundColor Cyan

    if ($script:Ledger.Count -eq 0) {
        Write-Host '    (nothing ran)' -ForegroundColor DarkGray
        return
    }

    $fmt = '{0,-5} {1,-24} {2,-8} {3,7} {4,-9} {5}'
    Write-Host ($fmt -f 'Phase', 'Task', 'Status', 'Exit', 'Duration', 'Message') -ForegroundColor White
    Write-Host ($fmt -f '-----', '------------------------', '--------', '-------', '---------', '-------') -ForegroundColor DarkGray

    foreach ($r in $script:Ledger) {
        $msg = $r.Message
        if ($msg.Length -gt 70) { $msg = $msg.Substring(0, 67) + '...' }
        Write-Host ($fmt -f $r.Phase, $r.Task, $r.Status, $r.ExitCode, $r.Duration, $msg) `
            -ForegroundColor (Get-StatusColor $r.Status)
    }

    $failed = @($script:Ledger | Where-Object { $_.Status -eq 'Failed' })
    $warned = @($script:Ledger | Where-Object { $_.Status -eq 'Warning' })
    $okay = @($script:Ledger | Where-Object { $_.Status -eq 'Ok' })
    $skipped = @($script:Ledger | Where-Object { $_.Status -eq 'Skipped' })

    if ($failed.Count -or $warned.Count) {
        Write-Host ''
        foreach ($r in ($failed + $warned)) {
            Write-Host ("  [{0}] {1}" -f $r.Status, $r.Task) -ForegroundColor (Get-StatusColor $r.Status)
            if ($r.Message) { Write-Host "      $($r.Message)" -ForegroundColor Gray }
            foreach ($d in $r.Detail) { Write-Host "      | $d" -ForegroundColor DarkGray }
            if ($r.Hint) { Write-Host "      -> $($r.Hint)" -ForegroundColor Cyan }
        }
    }

    $tally = '{0} ok, {1} warning(s), {2} failed, {3} skipped' -f $okay.Count, $warned.Count, $failed.Count, $skipped.Count
    Write-Host ''
    if ($failed.Count) {
        Write-Host "  $tally" -ForegroundColor Red
        Write-Host '  ^ fix the FAILED steps above, then re-run install.ps1 (it is idempotent).' -ForegroundColor Red
    } elseif ($warned.Count) {
        Write-Host "  $tally" -ForegroundColor Yellow
    } else {
        Write-Host "  $tally" -ForegroundColor Green
    }
}

function Save-Ledger {
    if (-not $script:TranscriptPath) { return }
    try {
        $jsonPath = [IO.Path]::ChangeExtension($script:TranscriptPath, '.json')
        $script:Ledger | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
        Write-Host ''
        Write-Info "Transcript : $($script:TranscriptPath)"
        Write-Info "Ledger     : $jsonPath"
    } catch {
        Write-Warning "Could not write the JSON ledger: $($_.Exception.Message)"
    }
}

$script:RestartDelaySeconds = 60

<#
  -Restart. Only after a clean, complete run: when a step failed or the run
  stopped early, the machine stays up so the summary can be read. Runs before
  the summary so the decision is in it and in the JSON ledger.
#>
function Request-Restart {
    $failed = @($script:Ledger | Where-Object { $_.Status -eq 'Failed' })
    $reason = $null
    if (-not $script:RunCompleted) { $reason = 'the run stopped early' }
    elseif ($failed.Count) { $reason = "$($failed.Count) step(s) failed" }
    elseif ($script:ExitCode -ne 0) { $reason = 'the run did not finish cleanly' }
    if ($reason) {
        Add-Result -Phase '-' -Task 'restart' -Status 'Skipped' -Message "-Restart: not restarting because $reason" `
            -Hint 'Fix the failures above, then restart (or re-run with -Restart)'
        return
    }

    $output = @(& shutdown.exe /r /t $script:RestartDelaySeconds /d p:0:0 /c 'install.ps1 finished; restarting to finish setup.' 2>&1 |
            ForEach-Object { "$_" })
    $code = $LASTEXITCODE
    $global:LASTEXITCODE = 0
    if ($code -eq 0) {
        $script:RestartScheduled = $true
        Add-Result -Phase '-' -Task 'restart' -Status 'Ok' `
            -Message "restarting in $($script:RestartDelaySeconds)s; run 'shutdown /a' to cancel"
    } elseif ($code -eq 1190) {
        # ERROR_SHUTDOWN_IS_SCHEDULED
        Add-Result -Phase '-' -Task 'restart' -Status 'Warning' -ExitCode $code `
            -Message 'a restart or shutdown was already scheduled; leaving it in place'
    } else {
        Add-Result -Phase '-' -Task 'restart' -Status 'Warning' -ExitCode $code `
            -Message "shutdown.exe exited with code $code; restart by hand" -Detail $output
    }
}

# ===========================================================================
$script:ExitCode = 0
$script:RunCompleted = $false
$script:RestartScheduled = $false
try {

    # --- Phase 0: Preflight ------------------------------------------------
    Write-Phase '0' 'Preflight (admin, winget, logging)'

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
        if (-not (Test-Path -LiteralPath $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        $script:TranscriptPath = Join-Path $LogPath "install-$($script:RunStamp).log"
        Start-Transcript -LiteralPath $script:TranscriptPath -Force | Out-Null
        $script:TranscriptStarted = $true
        Write-Info "Logging to $($script:TranscriptPath)"
    } catch {
        Write-Warning "Could not start a transcript (continuing without one): $($_.Exception.Message)"
    }

    # If the distro already has a non-root default user (e.g. this repo's
    # etc/wsl.conf pins one) adopt it rather than creating a second, competing
    # account. An explicit -WslUser always wins. Done before the banner so the
    # reported name -- and the password prompt below -- reference the real user.
    if (-not $SkipWsl -and -not $PSBoundParameters.ContainsKey('WslUser') -and (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        # wsl.exe prints its own errors (e.g. "There is no distribution with the
        # supplied name." on a fresh machine, before Phase 3 creates the distro)
        # to *stdout* as UTF-16LE, so 2>$null does not hide them. Trust the output
        # only on exit 0, and only if it is a real Linux user name: adopting that
        # error text once made every later `wsl -u` call fail, because its NUL
        # bytes truncate the command line (`getpwnam("T)`).
        $whoamiOut = @(& wsl.exe -d $Distro -- whoami 2>$null)
        $whoamiOk = ($LASTEXITCODE -eq 0)
        $global:LASTEXITCODE = 0
        $existingUser = ''
        if ($whoamiOk) {
            $existingUser = "$($whoamiOut | Where-Object { "$_".Trim() } | Select-Object -First 1)".Trim()
        }
        if ($existingUser -and $existingUser -ne 'root' -and $existingUser -ne $WslUser) {
            if ($existingUser -cmatch $LinuxUserPattern) {
                Write-Info "Adopting '$Distro' existing default user '$existingUser' (pass -WslUser to override)"
                $WslUser = $existingUser
            } else {
                Write-Warning "Ignoring unexpected 'whoami' output from '$Distro'; keeping WSL user '$WslUser'."
            }
        }
    }

    if (-not $SkipWsl -and $WslUser -cnotmatch $LinuxUserPattern) {
        throw "WSL user '$WslUser' is not a valid Linux user name (must match $LinuxUserPattern). Pass -WslUser <name>."
    }

    Write-Info "Distro       : $Distro"
    Write-Info "WSL user     : $WslUser"
    Write-Info "ArtifactRoot : $ArtifactRoot"
    Write-Info "SrcRoot      : $SrcRoot"
    Write-Info ("NFV repo     : $NfvRepoPath" + $(if ($SkipNfvClone) { ' [-SkipNfvClone]' } else { '' }))

    # Prompt now rather than 40 minutes into the run.
    if (-not $SkipWsl -and -not $WslPassword -and -not $NonInteractive) {
        Write-Host ''
        Write-Host "A password is needed for the WSL user '$WslUser' (leave blank to skip)." -ForegroundColor Cyan
        $WslPassword = Read-Host -Prompt "Password for $WslUser" -AsSecureString
    }

    # Same reasoning for the Azure DevOps sign-in nfv-clone needs in Phase 4.
    $script:NfvSignInFailed = $false
    $nfvWillClone = -not $SkipPersonal -and -not $SkipNfvClone -and
        -not (Test-Path -LiteralPath (Join-Path $NfvRepoPath '.git'))
    if ($nfvWillClone) {
        if ($NonInteractive) {
            Add-Result -Phase '0' -Task 'nfv-sign-in' -Status 'Skipped' `
                -Message '-NonInteractive; nfv-clone will rely on an already-cached credential'
        } else {
            Invoke-NfvSignIn
        }
    }

    Invoke-Step -Phase '0' -Task 'winget-configure-enable' -Hint 'Run: winget configure --enable' -Action {
        winget configure --enable 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "'winget configure --enable' returned exit $LASTEXITCODE (continuing)."
            $global:LASTEXITCODE = 0
        } else {
            Write-Host '[winget] configure enabled'
        }
    }

    # --- Phase 1: Resolve vendored WindowsDeveloperConfig ------------------
    Write-Phase '1' 'Resolve vendored WindowsDeveloperConfig'

    $vendorRoot = Join-Path $repoRoot 'vendor\WindowsDeveloperConfig'
    $wdcConfig = Join-Path $vendorRoot 'windows-dev-config\dev-config.winget'
    $wslComfort = Join-Path $vendorRoot 'wsl-comfort\install.ps1'

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

    # --- Phase 2: WindowsDeveloperConfig base setup ------------------------
    if ($SkipWdc) {
        Write-Phase '2' 'WDC base setup [SKIPPED -SkipWdc]'
        Add-Result -Phase '2' -Task 'wdc-base-setup' -Status 'Skipped' -Message '-SkipWdc'
    } else {
        Write-Phase '2' 'WDC base setup (winget configure)'
        Write-Info 'On a fresh machine this may reboot (WDC resumes itself via RunOnce);'
        Write-Info 'if it does, just re-run install.ps1 afterwards.'
        Invoke-Step -Phase '2' -Task 'wdc-base-setup' -ExitCodeIsContract `
            -Hint "Re-run: winget configure --file `"$wdcConfig`" --accept-configuration-agreements" -Action {
            # Flags mirror WindowsDeveloperConfig's own apply-configuration.ps1.
            # NOTE: --accept-package-agreements is NOT valid on `winget configure`;
            # package consent flows through --accept-configuration-agreements.
            $dialogWatcher = Start-DialogAutoConfirm
            $wdcOutput = New-Object System.Collections.Generic.List[string]
            $wdcExit = 0
            try {
                # Pass every record straight through (so it still streams and
                # Invoke-Step still sees stderr as errors) while keeping a copy
                # to work out which units failed.
                winget configure --file $wdcConfig --accept-configuration-agreements --disable-interactivity 2>&1 |
                    ForEach-Object { $wdcOutput.Add("$_"); $_ }
                $wdcExit = $LASTEXITCODE
            } finally {
                Stop-DialogAutoConfirm $dialogWatcher
            }
            if ($wdcExit -ne 0) {
                $failedUnits = @(Get-WdcFailedUnits $wdcOutput)
                if ($failedUnits.Count -eq 1 -and $failedUnits[0] -eq 'NodeJS') {
                    $nodeVersion = Get-InstalledNodeVersion
                    $ltsVersion = Get-WingetLatestVersion 'OpenJS.NodeJS.LTS'
                    if ($nodeVersion -and $ltsVersion -and $nodeVersion -ge $ltsVersion) {
                        # Non-terminating error: Invoke-Step records the step as a
                        # Warning (visible in the summary) rather than Failed.
                        Write-Error ("WDC NodeJS unit tried to install OpenJS.NodeJS.LTS $ltsVersion over the newer Node.js $nodeVersion already installed; " +
                            "the MSI refuses downgrades ('A later version of Node.js is already installed', 1603). Node.js is present; nothing to fix.")
                        $wdcExit = 0
                    }
                }
            }
            $global:LASTEXITCODE = $wdcExit
        }
        Update-SessionPath
    }

    # --- Temporary passwordless sudo (spans Phases 3-6) --------------------
    # Granted here, ahead of wsl-comfort, because Phase 3 needs sudo several
    # times of its own and used to prompt for each one: the grant only happened
    # at Phase 6. Revocation is in the top-level finally so no failure path
    # between here and Phase 6 can leak the drop-in.
    $script:WslSudoGranted = $false
    if (((-not $SkipWslComfort) -or (-not $SkipWsl)) -and (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        if ($WslTempPasswordlessSudo) {
            Grant-WslTempSudo -Phase '3' -Optional
        } elseif (Test-WslDistroReady) {
            # Disabled, but still clear anything an earlier run left behind --
            # silently leaving passwordless sudo in place is the worst outcome.
            Invoke-Step -Phase '3' -Task 'wsl-sudo-temp' `
                -Hint "Remove it by hand: wsl -d $Distro -u root -- rm -f /etc/sudoers.d/99-dotfiles-install" -Action {
                Write-Host '[wsl] temporary passwordless sudo disabled; sudo will prompt during wsl-comfort and install.sh'
                $code = Set-WslTempSudo -Mode revoke
                if ($code -ne 0) { throw "Could not remove /etc/sudoers.d/99-dotfiles-install (exit $code)." }
            }
        }
    }

    # --- Phase 3: wsl-comfort ----------------------------------------------
    if ($SkipWslComfort) {
        Write-Phase '3' 'wsl-comfort [SKIPPED -SkipWslComfort]'
        Add-Result -Phase '3' -Task 'wsl-comfort' -Status 'Skipped' -Message '-SkipWslComfort'
    } else {
        Write-Phase '3' "wsl-comfort (Comfort Shell + '$Distro')"
        Invoke-Step -Phase '3' -Task 'wsl-comfort' -Hint "Re-run: & `"$wslComfort`" -NonInteractive -Distro $Distro" -Action {
            # wsl-comfort runs wsl.exe/native tools internally and signals real failures
            # by throwing (it sets its own $ErrorActionPreference='Stop'). Its last
            # internal native call may leave a benign non-zero code, so its exit code is
            # deliberately not treated as a contract here.
            & $wslComfort -NonInteractive -Distro $Distro
            $global:LASTEXITCODE = 0
        }
        Update-SessionPath
    }

    # --- Phase 4: Personal catalog layer -----------------------------------
    if ($SkipPersonal) {
        Write-Phase '4' 'Personal layer [SKIPPED -SkipPersonal]'
        Add-Result -Phase '4' -Task 'catalog' -Status 'Skipped' -Message '-SkipPersonal'
    } else {
        Write-Phase '4' 'Personal layer (catalog tasks)'

        # appx-prune is deliberately absent: it is too destructive to run here.
        # powershell-profiles is deliberately absent: the profiles already sync
        # down from OneDrive, so copying them over is redundant.
        # verify-baseline is deliberately absent: it runs as Phase 8, after the
        # WSL phases have created the items it checks.

        $catalogPlan = @(
            @{ Task = 'winget-core'
                # Docker Desktop's WSL disk can only be placed cleanly at install time;
                # devdrive-env then checks it landed there.
                Args = $(if ($SkipDevDriveEnv) { @{} } else { @{ DockerDataRoot = (Join-Path $ArtifactRoot 'docker\data') } })
                Hint = 'Re-run: catalog\winget-core\script.ps1'
            }
            @{ Task = 'choco-fonts'; Args = @{}
                Hint = 'Re-run: catalog\choco-fonts\script.ps1'
            }
            @{ Task = 'modules-install'; Args = @{}
                Hint = 'Re-run: catalog\modules-install\script.ps1'
            }
            @{ Task = 'devdrive-env'; Skip = $SkipDevDriveEnv
                Args = @{ ArtifactRoot = $ArtifactRoot; SrcRoot = $SrcRoot }
                Hint = "Re-run: catalog\devdrive-env\script.ps1 -ArtifactRoot '$ArtifactRoot' -SrcRoot '$SrcRoot'"
            }
            @{ Task = 'nfv-clone'; Skip = ($SkipNfvClone -or $script:NfvSignInFailed)
                SkipMessage = $(if ($SkipNfvClone) { 'skipped by parameter' } else { 'Phase 0 nfv-sign-in failed; not prompting mid-run' })
                Args = @{ RepoUrl = $NfvRepoUrl; RepoPath = $NfvRepoPath }
                Hint = "Sign in to Git Credential Manager, then: git clone $NfvRepoUrl `"$NfvRepoPath`""
            }
            @{ Task = 'visualstudio'; Skip = $SkipVisualStudio
                Args = @{ VsInstallPath = $VsInstallPath; VsConfigPath = (Join-Path $NfvRepoPath 'NFV.vsconfig') }
                Hint = 'Re-run: catalog\visualstudio\script.ps1 (needs nfv-clone to have produced NFV.vsconfig)'
            }
            @{ Task = 'path-llvm'; Args = @{}
                Hint = 'LLVM must be installed by winget-core first'
            }
            @{ Task = 'windows-features'; Args = @{}
                Hint = 'Some features need a reboot before they report as enabled'
            }
            @{ Task = 'agency'; Args = @{}
                Hint = 'May need interactive auth: iex "& { $(irm aka.ms/InstallTool.ps1)} agency"'
            }
            @{ Task = 'copilot-plugins'; Args = @{}
                Hint = 'May need `copilot login` first'
            }
            @{ Task = 'wsl-bootstrap'; Args = @{ Distro = $Distro; WslUser = $WslUser }
                Hint = 'Needs the WSL optional features enabled (reboot pending?)'
            }
            @{ Task = 'dev-settings'; Args = @{ RestartExplorer = [bool]$RestartExplorer }
                Hint = 'Some settings only apply after an Explorer restart or sign-in'
            }
            @{ Task = 'sudo-inline'; Args = @{}
                Hint = 'Re-run elevated: catalog\sudo-inline\script.ps1 (needs Sudo for Windows)'
            }
            @{ Task = 'dotfiles-links'; Args = @{}
                Hint = 'Re-run: catalog\dotfiles-links\script.ps1'
            }
            @{ Task = 'terminal-profiles'; Args = @{}
                Hint = 'Close every Windows Terminal window first, then re-run: catalog\terminal-profiles\script.ps1'
            }
        )

        foreach ($entry in $catalogPlan) {
            $task = $entry.Task
            $taskScript = Join-Path $repoRoot "catalog\$task\script.ps1"

            if ($entry.Skip) {
                $skipMessage = if ($entry.SkipMessage) { [string]$entry.SkipMessage } else { 'skipped by parameter' }
                Write-Host ''
                Write-Host "--- $task [SKIPPED] ---" -ForegroundColor DarkGray
                Add-Result -Phase '4' -Task $task -Status 'Skipped' -Message $skipMessage
                continue
            }
            if (-not (Test-Path -LiteralPath $taskScript)) {
                Write-Host ''
                Write-Host "--- $task ---" -ForegroundColor Green
                Add-Result -Phase '4' -Task $task -Status 'Failed' -Message "task script not found: $taskScript" `
                    -Hint 'The catalog task directory is missing from the repo.'
                Write-Host "    ! task script not found: $taskScript" -ForegroundColor Red
                continue
            }

            $splat = $entry.Args
            $stepArgs = @{
                Phase  = '4'
                Task   = $task
                Hint   = [string]$entry.Hint
                Action = { & $taskScript @splat }.GetNewClosure()
            }
            if ($entry.ExitCodeIsContract) { $stepArgs.ExitCodeIsContract = $true }
            Invoke-Step @stepArgs

            # Rehydrate after *every* task so the next one -- and verify-baseline in
            # particular -- sees what the previous one just put on the PATH.
            Update-SessionPath
        }
    }

    # --- Phase 5: WSL provisioning -----------------------------------------
    if ($SkipWsl) {
        Write-Phase '5' 'WSL provisioning [SKIPPED -SkipWsl]'
        Add-Result -Phase '5' -Task 'wsl-provisioning' -Status 'Skipped' -Message '-SkipWsl'
    } elseif (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Phase '5' 'WSL provisioning'
        Add-Result -Phase '5' -Task 'wsl-provisioning' -Status 'Failed' -Message 'wsl.exe not found' `
            -Hint 'Install WSL (wsl --install) and re-run install.ps1.'
        Write-Warning 'wsl.exe not found; skipping WSL provisioning.'
    } else {
        Write-Phase '5' "WSL provisioning (user, dev-drive move, cleanup) in '$Distro'"

        $script:DistroReady = $false
        Invoke-Step -Phase '5' -Task 'wsl-distro-probe' -Hint "Run: wsl --install -d $Distro" -Action {
            $probe = (& wsl.exe -d $Distro -u root -- echo __WSL_OK__ 2>$null)
            if ($LASTEXITCODE -ne 0 -or ("$probe" -notmatch '__WSL_OK__')) {
                $global:LASTEXITCODE = 0
                throw "WSL distro '$Distro' is not ready (a reboot may be pending, or it is still initialising)."
            }
            $global:LASTEXITCODE = 0
            Write-Host "[wsl] '$Distro' is registered and responding"
            $script:DistroReady = $true
        }
        $distroReady = [bool]$script:DistroReady

        if ($distroReady) {
            # -- 5a. non-root default user ----------------------------------
            Invoke-Step -Phase '5' -Task 'wsl-user' -Hint "Inside the distro run: sudo useradd -m -s /bin/zsh -G sudo $WslUser" -Action {
                $provisionWin = Join-Path $repoRoot 'scripts\wsl-provision-user.sh'
                $provision = ConvertTo-WslPath $provisionWin
                if (-not $provision) { throw "Could not resolve '$provisionWin' inside '$Distro'." }

                # The password goes over stdin only -- never argv, never the transcript.
                $plain = ConvertFrom-SecureStringPlain $WslPassword
                try {
                    if ([string]::IsNullOrEmpty($plain)) {
                        # Send no stdin at all rather than an empty line, so an
                        # omitted -WslPassword leaves any existing password alone.
                        $null | & wsl.exe -d $Distro -u root -- bash "$provision" $WslUser
                    } else {
                        $plain | & wsl.exe -d $Distro -u root -- bash "$provision" $WslUser
                    }
                } finally {
                    $plain = $null
                    [GC]::Collect()
                }
                if ($LASTEXITCODE -ne 0) { throw "wsl-provision-user.sh exited with $LASTEXITCODE." }

                # The default-user change in /etc/wsl.conf needs a distro restart.
                & wsl.exe --terminate $Distro 2>&1 | Out-Null
                $global:LASTEXITCODE = 0
                Write-Host "[wsl] default user is now '$WslUser'"
            }

            # -- 5b. clean the stale /root dotfiles --------------------------
            if ($CleanStaleRootDotfiles) {
                Invoke-Step -Phase '5' -Task 'wsl-clean-root' -Hint 'Harmless to skip; the stale links only affect the root account.' -Action {
                    $cleanWin = Join-Path $repoRoot 'scripts\wsl-clean-root-dotfiles.sh'
                    $clean = ConvertTo-WslPath $cleanWin
                    $repoWsl = ConvertTo-WslPath $repoRoot
                    if (-not $clean -or -not $repoWsl) { throw 'Could not resolve the cleanup script inside the distro.' }

                    # Both places install.sh can have been run from: the Windows
                    # checkout under /mnt, and root's own clone if a root run ever
                    # used the Phase 6 layout. A link from either one is stale.
                    $rootClone = if ($WslDotfilesDir -match '^/') { $WslDotfilesDir } else { "/root/$WslDotfilesDir" }
                    $prefixes = @($repoWsl, $rootClone) -join ':'

                    & wsl.exe -d $Distro -u root -- bash "$clean" "$prefixes" /root
                    if ($LASTEXITCODE -ne 0) { throw "wsl-clean-root-dotfiles.sh exited with $LASTEXITCODE." }
                }
            } else {
                Add-Result -Phase '5' -Task 'wsl-clean-root' -Status 'Skipped' -Message '-CleanStaleRootDotfiles:$false'
            }

            # -- 5c. move the distro disk onto the Dev Drive -----------------
            if ($MoveWslToDevDrive) {
                Invoke-Step -Phase '5' -Task 'wsl-move-devdrive' -Hint "Run manually: wsl --manage $Distro --move `"$ArtifactRoot\wsl\$Distro`"" -Action {
                    $target = Join-Path $ArtifactRoot "wsl\$Distro"
                    $reg = Get-WslDistroRegistration $Distro
                    if (-not $reg) { throw "Could not find the registry registration for '$Distro'." }

                    $current = $reg.BasePath -replace '^\\\\\?\\', ''
                    Write-Host "[wsl] current location: $current"

                    if ($current.TrimEnd('\') -ieq $target.TrimEnd('\')) {
                        Write-Host '[wsl] already on the Dev Drive; nothing to do'
                        return
                    }

                    $vhdx = Join-Path $current 'ext4.vhdx'
                    if (-not (Test-Path -LiteralPath $vhdx)) { throw "ext4.vhdx not found under '$current'." }
                    $sizeBytes = (Get-Item -LiteralPath $vhdx).Length

                    $targetRoot = [IO.Path]::GetPathRoot($target)
                    $free = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($targetRoot.TrimEnd('\'))'" -ErrorAction SilentlyContinue).FreeSpace
                    if ($null -eq $free) { $free = (Get-PSDrive ($targetRoot.Substring(0, 1)) -ErrorAction SilentlyContinue).Free }

                    $needGb = [Math]::Round($sizeBytes / 1GB, 2)
                    $freeGb = if ($free) { [Math]::Round($free / 1GB, 2) } else { 0 }
                    Write-Host "[wsl] disk is ${needGb}GB; ${freeGb}GB free on $targetRoot"

                    # 1.2x headroom: --move copies before it deletes the original.
                    if (-not $free -or $free -lt ($sizeBytes * 1.2)) {
                        Write-Warning "Not enough free space on $targetRoot to move '$Distro' (need ~$([Math]::Round($needGb * 1.2, 2))GB). Skipping."
                        return
                    }

                    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
                    & wsl.exe --shutdown 2>&1 | Out-Null
                    Start-Sleep -Seconds 3
                    Write-Host "[wsl] moving '$Distro' to $target (this copies the whole disk)"

                    # wsl.exe writes its own status messages as UTF-16LE, which
                    # renders as "T h e   o p e r a t i o n ..." unless the console
                    # is told to expect it. Restore the encoding afterwards.
                    $prevEncoding = [Console]::OutputEncoding
                    try {
                        [Console]::OutputEncoding = [Text.Encoding]::Unicode
                        & wsl.exe --manage $Distro --move $target
                    } finally {
                        [Console]::OutputEncoding = $prevEncoding
                    }
                    if ($LASTEXITCODE -ne 0) { throw "wsl --manage --move exited with $LASTEXITCODE." }
                    Write-Host "[wsl] moved '$Distro' to $target"
                }
            } else {
                Add-Result -Phase '5' -Task 'wsl-move-devdrive' -Status 'Skipped' -Message '-MoveWslToDevDrive:$false'
            }
        }
    }

    # --- Phase 6: WSL install.sh -------------------------------------------
    if ($SkipWsl) {
        Write-Phase '6' 'WSL install.sh [SKIPPED -SkipWsl]'
        Add-Result -Phase '6' -Task 'wsl-clone-dotfiles' -Status 'Skipped' -Message '-SkipWsl'
        Add-Result -Phase '6' -Task 'wsl-install-sh' -Status 'Skipped' -Message '-SkipWsl'
    } elseif (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Phase '6' 'WSL install.sh'
        Add-Result -Phase '6' -Task 'wsl-clone-dotfiles' -Status 'Skipped' -Message 'wsl.exe not found'
        Add-Result -Phase '6' -Task 'wsl-install-sh' -Status 'Skipped' -Message 'wsl.exe not found'
    } else {
        Write-Phase '6' "WSL install.sh (inside '$Distro' as '$WslUser')"

        try {
            if ($WslTempPasswordlessSudo) {
                # Usually already granted before Phase 3, in which case this is a
                # no-op. It still matters on a fresh machine, where Phase 3 is
                # what created the distro and the early attempt skipped.
                Grant-WslTempSudo -Phase '6'
            } else {
                # Disabled, but still clear anything an earlier run left behind --
                # and treat a failed clear as a real problem, since silently
                # leaving passwordless sudo in place is the worst outcome here.
                Invoke-Step -Phase '6' -Task 'wsl-sudo-temp' `
                    -Hint "Remove it by hand: wsl -d $Distro -u root -- rm -f /etc/sudoers.d/99-dotfiles-install" -Action {
                    Write-Host '[wsl] temporary passwordless sudo disabled; install.sh will prompt for a password'
                    $code = Set-WslTempSudo -Mode revoke
                    if ($code -ne 0) { throw "Could not remove /etc/sudoers.d/99-dotfiles-install (exit $code)." }
                }
            }

            # -- 6a. give the distro its own checkout ------------------------
            # Running install.sh off the Windows mount pointed every symlink it
            # created back across drvfs: slow, and gone whenever the Dev Drive
            # is not attached. Clone into the distro and install from there.
            $script:WslDotfilesPath = $null

            Invoke-Step -Phase '6' -Task 'wsl-clone-dotfiles' `
                -Hint "Clone it yourself: wsl -d $Distro -u $WslUser -- git clone $WslDotfilesRepoUrl ~/$WslDotfilesDir" -Action {

                $probe = (& wsl.exe -d $Distro -u $WslUser -- echo __WSL_OK__ 2>$null)
                if ($LASTEXITCODE -ne 0 -or ("$probe" -notmatch '__WSL_OK__')) {
                    $global:LASTEXITCODE = 0
                    throw "Distro '$Distro' cannot run as '$WslUser'. If a reboot is pending or the distro is still initialising, re-run install.ps1."
                }
                $global:LASTEXITCODE = 0

                $cloneWin = Join-Path $repoRoot 'scripts\wsl-clone-dotfiles.sh'
                if (-not (Test-Path -LiteralPath $cloneWin)) { throw "Missing helper: $cloneWin" }
                $clone = ConvertTo-WslPath $cloneWin
                if (-not $clone) { throw "Could not resolve '$cloneWin' inside '$Distro'." }

                # Capture rather than stream: the script's last line reports the
                # absolute checkout path, which 6b needs for `wsl --cd`. Deriving
                # it here instead would mean duplicating the $HOME resolution the
                # script already does.
                $cloneOut = @(& wsl.exe -d $Distro -u $WslUser -- bash "$clone" "$WslDotfilesDir" "$WslDotfilesRepoUrl" 2>&1)
                $code = $LASTEXITCODE
                $global:LASTEXITCODE = 0

                $cloneOut | ForEach-Object { "$_" }
                if ($code -ne 0) { throw "wsl-clone-dotfiles.sh exited with $code." }

                $marker = $cloneOut | Where-Object { "$_" -match '^dotfiles-path=' } | Select-Object -Last 1
                if (-not $marker) { throw 'wsl-clone-dotfiles.sh did not report a checkout path.' }
                $script:WslDotfilesPath = ("$marker" -replace '^dotfiles-path=', '').Trim()
            }

            # -- 6b. run install.sh from that checkout -----------------------
            if (-not $script:WslDotfilesPath) {
                Add-Result -Phase '6' -Task 'wsl-install-sh' -Status 'Skipped' `
                    -Message 'no checkout inside the distro (clone step failed)' `
                    -Hint "Fix the clone first, then: wsl -d $Distro -u $WslUser --cd '~/$WslDotfilesDir' -- bash -lc 'bash ./install.sh'"
            } else {
                Invoke-Step -Phase '6' -Task 'wsl-install-sh' -ExitCodeIsContract `
                    -Hint "Run it yourself: wsl -d $Distro -u $WslUser --cd '$script:WslDotfilesPath' -- bash -lc 'bash ./install.sh'" -Action {

                    # `wsl --cd` takes the path from a *native* argv, so it is
                    # never interpolated into a shell string -- immune to spaces,
                    # quotes and shell injection (unlike `bash -lc "cd '<path>'"`).
                    Write-Host "[wsl] running install.sh from $script:WslDotfilesPath"
                    & wsl.exe -d $Distro -u $WslUser --cd $script:WslDotfilesPath -- bash -lc 'bash ./install.sh'
                }
            }
        } finally {
            Revoke-WslTempSudo -Phase '6'
        }
    }

    # --- Phase 7: Updates ---------------------------------------------------
    # Opt-in. After setup, so an upgrade that restarts WSL or an app cannot
    # disturb the phases above, but before verify-baseline, so the verify sees
    # the machine as the updates left it.
    if (-not $InstallUpdates) {
        Write-Phase '7' 'Updates [SKIPPED; pass -InstallUpdates to run]'
    } else {
        Write-Phase '7' 'Updates (winget upgrades, then Windows Update)'

        $upgradeScript = Join-Path $repoRoot 'catalog\winget-upgrade\script.ps1'
        Invoke-Step -Phase '7' -Task 'winget-upgrade' -Hint 'Re-run: catalog\winget-upgrade\script.ps1' -Action {
            $dialogWatcher = Start-DialogAutoConfirm
            try { & $upgradeScript } finally { Stop-DialogAutoConfirm $dialogWatcher }
        }
        Update-SessionPath

        $windowsUpdateScript = Join-Path $repoRoot 'catalog\windows-update\script.ps1'
        Invoke-Step -Phase '7' -Task 'windows-update' `
            -Hint 'Re-run: catalog\windows-update\script.ps1, or use Settings > Windows Update' -Action {
            & $windowsUpdateScript
        }
    }

    # --- Phase 8: Verify baseline ------------------------------------------
    # Last, not in Phase 4: it checks the WSL default user and the VHDX
    # location, which Phase 5 only creates -- so inside Phase 4 it failed on
    # every fresh machine.
    if ($SkipPersonal) {
        Write-Phase '8' 'Verify baseline [SKIPPED -SkipPersonal]'
        Add-Result -Phase '8' -Task 'verify-baseline' -Status 'Skipped' -Message '-SkipPersonal'
    } else {
        Write-Phase '8' 'Verify baseline'

        # Anything the caller opted out of must not be reported as a missing
        # baseline item, or an intentional -Skip turns into a false failure.
        $verifySkips = @()
        if ($SkipVisualStudio) { $verifySkips += 'VS 2022 Enterprise', 'NFV.vsconfig present' }
        if ($SkipNfvClone) { $verifySkips += 'Networking-nfv repo', 'NFV.vsconfig present' }
        if ($SkipDevDriveEnv) { $verifySkips += 'Dev-drive env vars', 'Dev-drive src var' }
        if ($SkipWsl) { $verifySkips += 'WSL default user non-root', 'WSL VHDX off C:' }
        if (-not $MoveWslToDevDrive) { $verifySkips += 'WSL VHDX off C:' }
        $verifySkips = @($verifySkips | Select-Object -Unique)

        $verifyScript = Join-Path $repoRoot 'catalog\verify-baseline\script.ps1'
        $verifyArgs = @{ ArtifactRoot = $ArtifactRoot; SrcRoot = $SrcRoot; VsInstallPath = $VsInstallPath; NfvRepoPath = $NfvRepoPath; Distro = $Distro; SkipChecks = $verifySkips }
        Update-SessionPath
        Invoke-Step -Phase '8' -Task 'verify-baseline' -ExitCodeIsContract `
            -Hint 'Missing items above were not installed; check the earlier task failures' -Action {
            & $verifyScript @verifyArgs
        }
    }

    $script:RunCompleted = $true
} catch {
    $script:ExitCode = 1
    Write-Host ''
    Write-Host "FATAL: $($_.Exception.Message)" -ForegroundColor Red
    Add-Result -Phase '-' -Task 'install.ps1' -Status 'Failed' -Message $_.Exception.Message `
        -Detail @("$($_.ScriptStackTrace)" -split "`n")
} finally {
    # Last line of defence: the drop-in now spans Phases 3-6, so a throw in any
    # of them would otherwise skip Phase 6's own revoke and leak passwordless
    # sudo. No-op when Phase 6 already cleaned up.
    Revoke-WslTempSudo -Phase '6'

    if ($Restart) { Request-Restart }

    Write-RunSummary
    Save-Ledger

    Write-Host ''
    Write-Host '=== install.ps1 finished ===' -ForegroundColor Cyan
    Write-Info 'If the WDC base setup reboots the machine, re-run install.ps1 after logging back in.'
    if ($script:RestartScheduled) {
        Write-Host "Restarting in $($script:RestartDelaySeconds) seconds. Run 'shutdown /a' to cancel." -ForegroundColor Yellow
    }

    if ($script:Ledger | Where-Object { $_.Status -eq 'Failed' }) { $script:ExitCode = 1 }

    if ($script:TranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch { }
    }
}

exit $script:ExitCode
