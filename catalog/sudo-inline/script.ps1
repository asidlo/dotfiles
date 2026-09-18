<#
.SYNOPSIS
  Put Sudo for Windows into inline mode.

.DESCRIPTION
  The "Networking-nfv" Terminal profile launches through `sudo` so the elevated
  shell stays a tab in the current window instead of taking over a new one.
  Sudo picks its mode from the machine setting, and Windows enables it in
  "new window" mode by default.

  The profile deliberately does *not* pass --inline. Sudo exits with an error
  when a mode is requested that the machine setting does not allow, so baking
  the flag into the profile would turn a mis-configured machine into a broken
  profile instead of a degraded one. Fix the machine here; let the profile fall
  back to a new window everywhere else.

  Inline is the least isolated of sudo's modes: the unelevated console stays
  attached to the elevated process. That is the trade for keeping an elevated
  shell in the same window. Set forceNewWindow by hand on machines where that is
  not acceptable.
#>
$ErrorActionPreference = 'Stop'

$sudo = Get-Command sudo.exe -ErrorAction SilentlyContinue
if (-not $sudo) {
  Write-Warning '[sudo] sudo.exe not found (needs Windows 11 24H2+ or Sudo for Windows); skipping.'
  return
}

function Get-SudoMode {
  return (& $sudo.Source config 2>&1 | Out-String).Trim()
}

# Read the mode before demanding elevation: `sudo config` is read-only, so an
# already-correct machine reports ok from an unelevated shell instead of
# warning about a change it does not need to make.
$before = Get-SudoMode
if ($before -match 'Inline') {
  Write-Host "[sudo] ok $before"
  return
}

# --enable writes under HKLM, so it needs elevation. install.ps1 runs elevated;
# guard anyway, because a UAC prompt raised inside a piped step has no window to
# appear over and would just hang the run.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Warning "[sudo] $before; re-run elevated to switch to inline mode."
  return
}

Write-Host "[sudo] current: $before"
$output = & $sudo.Source config --enable normal 2>&1
$exitCode = $LASTEXITCODE
$output | Where-Object { $_ } | ForEach-Object { Write-Host "[sudo] $_" }
if ($exitCode -ne 0) {
  throw "[sudo] 'sudo config --enable normal' failed with exit code $exitCode"
}

$after = Get-SudoMode
if ($after -notmatch 'Inline') {
  throw "[sudo] expected inline mode, got: $after"
}
Write-Host "[sudo] set $after"
