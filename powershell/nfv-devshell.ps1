<#
.SYNOPSIS
  Enter a Visual Studio 2022 developer shell for Networking-nfv and load the
  repo's dev modules.

.DESCRIPTION
  Backs the "Networking-nfv" Windows Terminal profile in powershell\settings.json.

  Dot-source this; never run it with -File. AddModules.ps1 defines shell
  functions (root, src), sets REPOROOT/OUTPUTROOT and imports a dozen modules
  into its *caller's* scope. Run through -File all of that would be thrown away
  with the script scope, leaving an interactive prompt with none of it loaded.

  Terminal expands %VARS% in startingDirectory but not in commandline, so the
  profile passes no paths at all: everything is resolved here from DEVDRIVE_SRC.

  Nothing here throws. The profile runs powershell.exe -NoExit, so a terminating
  error would leave a live prompt with the reason already scrolled away, while a
  warning leaves a usable shell that says what is missing.

.NOTES
  Windows PowerShell 5.1 on purpose: NFV's onebox.psm1 and NFVUT.psm1 call
  Get-WmiObject, which was removed in PowerShell 6, and the VS developer shell
  is a Windows PowerShell host anyway.
#>
param(
  [string]$SrcRoot = $(if ($env:DEVDRIVE_SRC) { $env:DEVDRIVE_SRC } else { 'Q:\src' }),
  [string]$RepoPath,
  # Pins the developer shell to VS 2022. A bare -latest would pick a newer
  # side-by-side install; this repo installs VS 2022 for NFV specifically.
  [string]$VsVersionRange = '[17.0,18.0)'
)

if (-not $RepoPath) { $RepoPath = Join-Path $SrcRoot 'Networking-nfv' }

$vsPath = $null
# Join-Path throws on a null root rather than returning null, and this script
# must never throw: the profile runs -NoExit, so a terminating error here would
# skip the repo/AddModules work below and leave a bare prompt.
$programFilesX86 = ${env:ProgramFiles(x86)}
if (-not $programFilesX86) { $programFilesX86 = $env:ProgramFiles }
if ($programFilesX86) {
  $vswhere = Join-Path $programFilesX86 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (Test-Path -LiteralPath $vswhere) {
    $vsPath = @(& $vswhere -latest -products * -version $VsVersionRange -property installationPath 2>$null |
        Where-Object { $_ }) | Select-Object -First 1
  }
}

if (-not $vsPath) {
  Write-Warning "[nfv] Visual Studio $VsVersionRange not found; continuing without the developer shell."
} else {
  $devShell = Join-Path $vsPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll'
  if (-not (Test-Path -LiteralPath $devShell)) {
    Write-Warning "[nfv] developer shell module missing: $devShell"
  } else {
    try {
      Import-Module -Force $devShell -ErrorAction Stop
      # -SkipAutomaticLocation keeps the profile's startingDirectory; without it
      # Enter-VsDevShell relocates the session to %USERPROFILE%\Source.
      Enter-VsDevShell -VsInstallPath $vsPath -Arch amd64 -HostArch amd64 `
        -SkipAutomaticLocation -ErrorAction Stop | Out-Null
      Write-Host "[nfv] VS developer shell: $vsPath"
    } catch {
      Write-Warning "[nfv] could not enter the VS developer shell: $($_.Exception.Message)"
    }
  }
}

if (-not (Test-Path -LiteralPath $RepoPath)) {
  Write-Warning "[nfv] repo not found: $RepoPath -- run catalog\nfv-clone\script.ps1"
  return
}
Set-Location -LiteralPath $RepoPath

$addModules = Join-Path $RepoPath 'AddModules.ps1'
if (-not (Test-Path -LiteralPath $addModules)) {
  Write-Warning "[nfv] AddModules.ps1 not found under $RepoPath"
  return
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  # The profile shells out through sudo, so this only shows up when the launcher
  # is dot-sourced by hand or sudo was declined.
  Write-Warning '[nfv] not elevated; onebox/ExBox helpers that require admin will fail.'
}

Write-Host "[nfv] loading $addModules"
. $addModules
