$ErrorActionPreference = 'Stop'
$llvm = 'C:\\Program Files\\LLVM\\bin'
if (Test-Path $llvm) {
  $cur = [Environment]::GetEnvironmentVariable('Path','Machine')
  if ($cur -notlike '*LLVM\\bin*') {
    $new = $cur + ';' + $llvm
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $new
    Write-Host '[llvm] Added to PATH'
  } else { Write-Host '[llvm] Already on PATH' }
} else { Write-Host '[llvm] Not installed' }
