param(
  [string]$RepoUrl = 'https://msazure.visualstudio.com/One/_git/Networking-nfv',
  [string]$RepoPath = 'Q:\src\Networking-nfv'
)
$ErrorActionPreference = 'Stop'

if (Test-Path (Join-Path $RepoPath '.git')) {
  Write-Host "[nfv] already cloned: $RepoPath"
  return
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw '[nfv] git not found on PATH'
}

$longPaths = (& git config --global --get core.longpaths 2>$null)
if ($longPaths -ne 'true') {
  Write-Host '[nfv] enabling git core.longpaths'
  & git config --global core.longpaths true
  if ($LASTEXITCODE -ne 0) {
    throw '[nfv] failed to enable git core.longpaths'
  }
} else {
  Write-Host '[nfv] ok git core.longpaths'
}

$parent = Split-Path -Parent $RepoPath
New-Item -ItemType Directory -Force -Path $parent | Out-Null

Write-Host "[nfv] cloning $RepoUrl -> $RepoPath"
$output = & git clone $RepoUrl $RepoPath 2>&1
$exitCode = $LASTEXITCODE
if ($exitCode -eq 0) {
  $output | ForEach-Object { Write-Host "[nfv] $_" }
  return
}

$output | ForEach-Object { Write-Warning "[nfv] $_" }
Write-Warning "[nfv] clone failed; sign in to Git Credential Manager, then run: git clone $RepoUrl $RepoPath"
# Auth failures are degraded-but-ok for unattended install, so clear LASTEXITCODE after warning.
$global:LASTEXITCODE = 0
