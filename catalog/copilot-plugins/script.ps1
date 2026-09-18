param()
$ErrorActionPreference = 'Stop'

function Update-SessionPath {
  $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

function Write-FilteredOutput($Lines) {
  $Lines |
    Where-Object { $_ -notmatch 'Direct plugin installs .* are deprecated' } |
    ForEach-Object { Write-Host "[copilot] $_" }
}

Update-SessionPath
if (-not (Get-Command copilot -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning '[copilot] winget not found; cannot install GitHub Copilot CLI.'
    return
  }

  Write-Host '[copilot] installing GitHub.Copilot via winget'
  $output = & winget install --id GitHub.Copilot --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity 2>&1
  $exitCode = $LASTEXITCODE
  $output | ForEach-Object { Write-Host "[copilot] $_" }
  if ($exitCode -ne 0) {
    Write-Warning "[copilot] winget install failed with exit code $exitCode; interactive login or manual install may be required."
    $global:LASTEXITCODE = 0
    return
  }

  Update-SessionPath
  if (-not (Get-Command copilot -ErrorAction SilentlyContinue)) {
    Write-Warning '[copilot] copilot not found after install; open a new shell or complete interactive setup.'
    return
  }
}

$plugins = & copilot plugin list 2>&1
$listCode = $LASTEXITCODE
if ($listCode -ne 0) {
  Write-FilteredOutput $plugins
  Write-Warning "[copilot] could not list plugins (exit code $listCode); GitHub login may be required."
  $global:LASTEXITCODE = 0
  return
}

if ($plugins | Select-String 'anvil') {
  Write-Host '[copilot] anvil already installed'
  return
}

Write-Host '[copilot] installing anvil plugin'
# burkeholland/anvil has no marketplace.json and is not in github/copilot-plugins or github/awesome-copilot; keep the direct install and ignore the deprecation warning.
$installOutput = & copilot plugin install burkeholland/anvil 2>&1
$installCode = $LASTEXITCODE
Write-FilteredOutput $installOutput
if ($installCode -ne 0) {
  Write-Warning "[copilot] anvil plugin install failed with exit code $installCode; GitHub login may be required."
  $global:LASTEXITCODE = 0
  return
}

Write-Host '[copilot] anvil installed'
