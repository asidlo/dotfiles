$ErrorActionPreference = 'Stop'
$PackagesToKeep = @(
  'Microsoft.Windows.Photos',
  'Microsoft.Windows.DevHome',
  'Microsoft.WindowsCalculator',
  'Microsoft.WindowsNotepad',
  'Microsoft.Paint',
  'Microsoft.Todos',
  'Microsoft.WindowsStore',
  'Microsoft.WindowsTerminal',
  'MSTeams',
  'Microsoft.Winget.Source',
  'Microsoft.EpmShellExtension',
  'Microsoft.OutlookForWindows'
)
Get-AppxPackage | Where-Object { -not $_.NonRemovable } | Where-Object { $_.Name -notmatch ($PackagesToKeep -join '|') } | Where-Object { -not $_.IsFramework } | Remove-AppxPackage -ErrorAction SilentlyContinue
