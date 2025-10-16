$ErrorActionPreference = 'Stop'
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  Write-Host "[choco] bootstrap"
  Set-ExecutionPolicy Bypass -Scope Process -Force
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
} else { Write-Host "[choco] present" }
if (-not (choco list --local-only | Select-String -Pattern '^nerd-fonts-meslo ')) {
  choco install nerd-fonts-meslo -y
} else { Write-Host "[choco] nerd-fonts-meslo already installed" }
