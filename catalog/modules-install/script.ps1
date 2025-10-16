$ErrorActionPreference = 'Stop'
$modules = @('PSDesiredStateConfiguration','Az')
foreach ($m in $modules) {
  if (-not (Get-Module -ListAvailable -Name $m)) {
    Write-Host "[module] installing $m"
    Install-Module -Name $m -Force -Scope CurrentUser
  } else { Write-Host "[module] $m already present" }
}
