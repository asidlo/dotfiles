param(
  [string]$Distro = 'Ubuntu',
  # Distro user that should own user-scoped artifacts (win32yank shim). Empty
  # means "whatever the distro's default user is", which on a fresh machine is
  # still root because Phase 5 has not created the user yet.
  [string]$WslUser = ''
)
$ErrorActionPreference = 'Stop'

function Get-WslDistros {
  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return @() }
  return @(& wsl.exe --list --quiet 2>$null | ForEach-Object { ($_.Trim() -replace "`0", '') } | Where-Object { $_ })
}

function ConvertTo-WslPath {
  param([string]$WindowsPath)
  $forwardPath = $WindowsPath -replace '\\', '/'
  $linuxPath = & wsl.exe -d $Distro -- wslpath -a $forwardPath 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $linuxPath) { throw "[wsl] Could not translate path for $Distro`: $WindowsPath" }
  return $linuxPath.Trim()
}

if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
  Write-Warning '[wsl] wsl.exe not found; WSL may require a reboot or Windows feature enablement.'
  $global:LASTEXITCODE = 0
  return
}

# Ensure WSL optional components are enabled (idempotent)
$features = @('VirtualMachinePlatform','Microsoft-Windows-Subsystem-Linux')
foreach ($f in $features) {
  dism.exe /online /enable-feature /featurename:$f /all /norestart | Out-Null
  if (($LASTEXITCODE -ne 0) -and ($LASTEXITCODE -ne 3010)) { throw "[wsl] Failed to enable feature $f (exit $LASTEXITCODE)" }
}

$installed = Get-WslDistros
if ($installed -notcontains $Distro) {
  Write-Host "[wsl] Installing distro: $Distro"
  wsl.exe --install -d $Distro
  Write-Host '[wsl] Distro installation initiated. A reboot may be required.'
  $installed = Get-WslDistros
}

if ($installed -notcontains $Distro) {
  Write-Warning "[wsl] Distro not yet registered: $Distro. Reboot or first-run setup may be pending."
  $global:LASTEXITCODE = 0
  return
}
Write-Host "[wsl] Distro already installed: $Distro"

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$wslConfSource = Join-Path $repoRoot 'etc\wsl.conf'
if (-not (Test-Path $wslConfSource)) { throw "[wsl] Missing repo wsl.conf: $wslConfSource" }

Write-Host "[wsl] Attempting to push wsl.conf into $Distro"
$wslConfLinux = ConvertTo-WslPath -WindowsPath $wslConfSource

# The merge lives in scripts/wsl-merge-conf.sh rather than an inline `bash -c`
# here-string: PowerShell here-strings are CRLF, and a single \r turns `set -e`
# into "set: - : invalid option" and breaks every if/fi. Invoking a real .sh by
# path (LF-pinned via .gitattributes) removes that whole class of failure.
# Running it with -u root also avoids a sudo password prompt that an unattended
# run has no way to answer -- previously this timed out after five minutes.
$mergeScriptWin = Join-Path $repoRoot 'scripts\wsl-merge-conf.sh'
if (-not (Test-Path $mergeScriptWin)) { throw "[wsl] Missing merge helper: $mergeScriptWin" }
$mergeScriptLinux = ConvertTo-WslPath -WindowsPath $mergeScriptWin

wsl.exe -d $Distro -u root -- bash $mergeScriptLinux $wslConfLinux /etc/wsl.conf
if ($LASTEXITCODE -ne 0) { throw "[wsl] Failed to update /etc/wsl.conf in $Distro (exit $LASTEXITCODE)" }

# Win32yank convenience link when running inside WSL (useful for Neovim clipboard on Windows)
$win32yank = 'C:\tools\neovim\bin\win32yank.exe'
if ((Test-Path $win32yank) -and ($installed -contains $Distro)) {
  $win32yankLinux = ConvertTo-WslPath -WindowsPath $win32yank
  # Target the real user when we know it, so the shim does not land in /root on
  # a first run (Phase 5 creates the user only after this task has completed).
  $userArgs = @()
  if ($WslUser) {
    & wsl.exe -d $Distro -u root -- id -u $WslUser 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $userArgs = @('-u', $WslUser) }
  }
  $target = if ($userArgs) { $WslUser } else { 'default user' }
  Write-Host "[wsl] Creating win32yank symlink inside distro for $target"
  wsl.exe -d $Distro @userArgs -- bash -c 'mkdir -p ~/.local/bin && ln -sf "$1" ~/.local/bin/win32yank.exe' -- $win32yankLinux
  if ($LASTEXITCODE -ne 0) { throw "[wsl] Failed to create win32yank symlink in $Distro (exit $LASTEXITCODE)" }
}

Write-Host '[wsl] Bootstrap complete (pending any required reboot).'
$global:LASTEXITCODE = 0
