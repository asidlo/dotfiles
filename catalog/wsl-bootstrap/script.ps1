param(
  [string]$distro = 'Ubuntu',
  [string]$username
)
$ErrorActionPreference = 'Stop'

# Ensure WSL optional components are enabled (idempotent)
$features = @('VirtualMachinePlatform','Microsoft-Windows-Subsystem-Linux')
foreach ($f in $features) { dism.exe /online /enable-feature /featurename:$f /all /norestart | Out-Null }

# Check installed distros
$installed = & wsl.exe --list --quiet 2>$null | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($installed -notcontains $distro) {
  Write-Host "[wsl] Installing distro: $distro"
  # Using --install without -n to allow progression; some Dev Box contexts may require restart.
  wsl.exe --install -d $distro
  Write-Host "[wsl] Distro installation initiated. A reboot may be required."
} else { Write-Host "[wsl] Distro already installed: $distro" }

# Generate wsl.conf in repo-managed location and copy into distro if possible
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$wslConfSource = Join-Path $repoRoot 'wsl' 'wsl.conf'
if (-not (Test-Path $wslConfSource)) {
  New-Item -ItemType Directory -Path (Split-Path $wslConfSource) -Force | Out-Null
  @"
[automount]
options = "metadata"
root = /
[interop]
appendWindowsPath = false
"@ | Set-Content -Path $wslConfSource -Encoding UTF8
}

if ($installed -contains $distro) {
  Write-Host "[wsl] Attempting to push wsl.conf into $distro"
  wsl.exe -d $distro bash -c "sudo mkdir -p /etc && sudo cp /mnt/c/$(echo $wslConfSource -replace ':','') /etc/wsl.conf" 2>$null
}

# Win32yank convenience link when running inside WSL (useful for Neovim clipboard on Windows)
$win32yank = 'C:\\tools\\neovim\\bin\\win32yank.exe'
if (Test-Path $win32yank -and $installed -contains $distro) {
  Write-Host "[wsl] Creating win32yank symlink inside distro"
  wsl.exe -d $distro bash -c "mkdir -p ~/.local/bin && ln -sf /mnt/c/tools/neovim/bin/win32yank.exe ~/.local/bin/win32yank.exe" 2>$null
}

Write-Host '[wsl] Bootstrap complete (pending any required reboot).'
