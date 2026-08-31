param()
$ErrorActionPreference = 'Stop'
$llvm = 'C:\Program Files\LLVM\bin'
if (Test-Path $llvm) {
  $cur = [Environment]::GetEnvironmentVariable('Path','Machine')
  $entries = @($cur -split ';' | Where-Object { $_ } | ForEach-Object { $_.Trim().TrimEnd('\') })
  # Keep single backslashes; matching a double-backslash literal never matches the real PATH.
  $present = [bool]($entries | Where-Object { [string]::Equals($_, $llvm.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase) })
  if (-not $present) {
    $new = (@($cur, $llvm) | Where-Object { $_ }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $new, 'Machine')
    Write-Host '[llvm] Added to PATH'
  } else { Write-Host '[llvm] Already on PATH' }
} else { Write-Host '[llvm] Not installed' }
