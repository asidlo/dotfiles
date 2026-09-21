param()
$ErrorActionPreference = 'Stop'

$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
if (Get-Command agency -ErrorAction SilentlyContinue) {
  Write-Host '[agency] already installed'
  return
}

try {
  Write-Host '[agency] installing agency'
  # iex on a remote script is the vendor-documented install path for this internal tool.
  iex "& { $(irm aka.ms/InstallTool.ps1)} agency"
} catch {
  Write-Warning "[agency] install failed: $($_.Exception.Message)"
}

$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')
if (Get-Command agency -ErrorAction SilentlyContinue) {
  Write-Host '[agency] installed'
  return
}

Write-Warning '[agency] agency not found after install; interactive auth or a new shell may be required.'
