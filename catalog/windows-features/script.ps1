$ErrorActionPreference = 'Stop'
# Enable Windows features idempotently
$features = @(
  'VirtualMachinePlatform',
  'Containers',
  'Microsoft-Windows-Subsystem-Linux',
  'Microsoft-Hyper-V-All'
)
foreach ($f in $features) {
  Write-Host "[feature] enabling $f"
  dism.exe /online /enable-feature /featurename:$f /all /norestart | Out-Null
}
