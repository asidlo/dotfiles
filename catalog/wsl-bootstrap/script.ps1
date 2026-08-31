param(
  [string]$Distro = 'Ubuntu'
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
$mergeScript = @'
set -e
src="$1"
sudo mkdir -p /etc
if sudo test -f /etc/wsl.conf && sudo grep -qi '^\[user\]' /etc/wsl.conf; then
  sudo awk '
    BEGIN { skip=0 }
    tolower($0) ~ /^\[user\][[:space:]]*$/ { skip=1; next }
    /^\[/ { skip=0 }
    !skip { print }
  ' "$src" | sudo tee /etc/wsl.conf.dotfiles.base >/dev/null
  sudo awk '
    BEGIN { keep=0 }
    tolower($0) ~ /^\[user\][[:space:]]*$/ { keep=1 }
    /^\[/ && tolower($0) !~ /^\[user\][[:space:]]*$/ && keep { exit }
    keep { print }
  ' /etc/wsl.conf | sudo tee /etc/wsl.conf.dotfiles.user >/dev/null
  sudo sh -c 'cat /etc/wsl.conf.dotfiles.base > /etc/wsl.conf; printf "\n" >> /etc/wsl.conf; cat /etc/wsl.conf.dotfiles.user >> /etc/wsl.conf; rm -f /etc/wsl.conf.dotfiles.base /etc/wsl.conf.dotfiles.user'
else
  sudo cp "$src" /etc/wsl.conf
fi
'@
wsl.exe -d $Distro -- bash -c $mergeScript -- $wslConfLinux
if ($LASTEXITCODE -ne 0) { throw "[wsl] Failed to update /etc/wsl.conf in $Distro (exit $LASTEXITCODE)" }

# Win32yank convenience link when running inside WSL (useful for Neovim clipboard on Windows)
$win32yank = 'C:\tools\neovim\bin\win32yank.exe'
if ((Test-Path $win32yank) -and ($installed -contains $Distro)) {
  Write-Host "[wsl] Creating win32yank symlink inside distro"
  $win32yankLinux = ConvertTo-WslPath -WindowsPath $win32yank
  wsl.exe -d $Distro -- bash -c 'mkdir -p ~/.local/bin && ln -sf "$1" ~/.local/bin/win32yank.exe' -- $win32yankLinux
  if ($LASTEXITCODE -ne 0) { throw "[wsl] Failed to create win32yank symlink in $Distro (exit $LASTEXITCODE)" }
}

Write-Host '[wsl] Bootstrap complete (pending any required reboot).'
$global:LASTEXITCODE = 0
