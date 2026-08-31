param(
  [string]$VsInstallPath = 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise',
  [string]$VsConfigPath = 'Q:\src\Networking-nfv\NFV.vsconfig'
)
$ErrorActionPreference = 'Stop'

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$setup = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe'
$successCodes = @(0, 1641, 3010)
$wingetSuccessCodes = @(0, -1978335189, -1978335135, -1978334972, 1641, 3010)

if (-not (Test-Path $vswhere)) {
  throw "[vs] vswhere not found at $vswhere"
}

function Get-Vs2022Path {
  $paths = & $vswhere -products * -version '[17.0,18.0)' -prerelease -all -property installationPath -format value
  if ($LASTEXITCODE -ne 0) {
    throw "[vs] vswhere failed with exit code $LASTEXITCODE"
  }

  return [string](@($paths | Where-Object { $_ })[0])
}

$resolvedPath = Get-Vs2022Path
if ($resolvedPath) {
  Write-Host "[vs] Visual Studio 2022 found: $resolvedPath"
} else {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw '[vs] winget not found on PATH'
  }

  Write-Host '[vs] installing Microsoft.VisualStudio.2022.Enterprise via winget'
  $installOutput = & winget install --id Microsoft.VisualStudio.2022.Enterprise --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity 2>&1
  $installCode = $LASTEXITCODE
  $installOutput | ForEach-Object { Write-Host "[vs] $_" }
  if ($wingetSuccessCodes -notcontains $installCode) {
    throw "[vs] winget install failed with exit code $installCode"
  }

  $resolvedPath = Get-Vs2022Path
  if (-not $resolvedPath) {
    $resolvedPath = $VsInstallPath
    Write-Warning "[vs] vswhere did not return VS 2022 after install; falling back to $resolvedPath"
  }
}

if ($resolvedPath -match '\\Microsoft Visual Studio\\18\\') {
  throw "[vs] refusing to modify Visual Studio 2026 install: $resolvedPath"
}

if (-not (Test-Path $VsConfigPath)) {
  Write-Warning "[vs] NFV.vsconfig not found at $VsConfigPath; skipping workload import (run the nfv-clone task first)."
  return
}

if (-not (Test-Path $setup)) {
  throw "[vs] Visual Studio Installer setup.exe not found at $setup"
}

Write-Host "[vs] applying config $VsConfigPath to $resolvedPath"
# setup.exe modify --config is additive only; it adds missing components and never removes components.
$setupArgs = @(
  'modify',
  '--installPath', $resolvedPath,
  '--config', $VsConfigPath,
  '--passive',
  '--norestart',
  '--nocache'
)
$process = Start-Process -FilePath $setup -ArgumentList $setupArgs -Wait -PassThru
if ($successCodes -notcontains $process.ExitCode) {
  throw "[vs] setup.exe modify failed with exit code $($process.ExitCode)"
}

Write-Host "[vs] config applied; setup.exe exit code $($process.ExitCode)"
