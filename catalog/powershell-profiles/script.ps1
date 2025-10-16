$ErrorActionPreference = 'Stop'
$powershellDir = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Microsoft\Documents\WindowsPowerShell"
$pwshDir       = "$env:HOMEDRIVE$env:HOMEPATH\OneDrive - Microsoft\Documents\PowerShell"
foreach ($dir in @($powershellDir, $pwshDir)) {
  if (-not (Test-Path -Path $dir -PathType Container)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  if (Test-Path -Path "$dir\profile.ps1" -PathType Leaf) {
    Remove-Item -Path "$dir\profile.ps1" -Force
  }
}
Copy-Item -Destination "$powershellDir\profile.ps1" -Path "$PSScriptRoot\..\..\powershell\profile.ps1" -Force
Copy-Item -Destination "$pwshDir\profile.ps1" -Path "$PSScriptRoot\..\..\powershell\pwsh-profile.ps1" -Force
