param(
  [string[]]$Packages
)
$ErrorActionPreference = 'Stop'

# [string[]] avoids PowerShell's script-scope type constraint from coercing the
# default array into one space-joined package id.
$wingetPackages = @(
  'Git.Git',
  'Docker.DockerDesktop',
  'Starship.Starship',
  'eza-community.eza',
  'ajeetdsouza.zoxide',
  'sharkdp.fd',
  'sharkdp.bat',
  'BurntSushi.ripgrep.MSVC',
  'chrisant996.Clink',
  'junegunn.fzf',
  'Neovim.Neovim',
  'JesseDuffield.lazygit',
  'GoLang.Go',
  'vim.vim',
  'Microsoft.Azure.AZCopy.10',
  'Microsoft.Teams',
  'Microsoft.AzureCLI',
  'LLVM.LLVM',
  'Rustlang.Rustup'
)
$msstorePackages = @('9NRX63209R7B')

if ($Packages) {
  if (($Packages.Count -eq 1) -and ($Packages[0] -match '\s')) {
    $wingetPackages = $Packages[0].Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
  } else {
    $wingetPackages = $Packages | Where-Object { $_ }
  }
  $msstorePackages = @()
}

function Test-WingetInstalled {
  param([string]$Id, [string]$Source)
  $output = & winget list --id $Id --exact --source $Source --disable-interactivity 2>&1
  $exit = $LASTEXITCODE
  if ($exit -ne 0) { return $false }
  return [bool]($output | Select-String -SimpleMatch $Id)
}

function Get-WingetResult {
  param([int]$ExitCode)
  switch ($ExitCode) {
    0 { return 'Installed' }
    1641 { return 'Reboot pending' }
    3010 { return 'Reboot pending' }
    -1978335189 { return 'Update not applicable' }         # 0x8A15002B APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE
    -1978335135 { return 'Already installed' }            # 0x8A150061 APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED
    -1978334963 { return 'Already installed' }            # 0x8A15010D APPINSTALLER_CLI_ERROR_INSTALL_ALREADY_INSTALLED
    default { return 'Failed' }                            # Includes 0x8A150010 NO_APPLICABLE_INSTALLER, 0x8A150014 NO_APPLICATIONS_FOUND, and other non-zero exits
  }
}

function Install-WingetPackage {
  param([string]$Id, [string]$Source, [switch]$TolerateFailure)

  if (Test-WingetInstalled -Id $Id -Source $Source) {
    Write-Host "[winget] already installed $Id ($Source)"
    return [PSCustomObject]@{ Package = $Id; Source = $Source; Result = 'Already installed'; Exit = 0; Output = @(); Fatal = $false }
  }

  Write-Host "[winget] installing $Id ($Source)"
  $output = & winget install --id $Id --exact --source $Source --accept-source-agreements --accept-package-agreements --disable-interactivity -h 2>&1
  $exit = $LASTEXITCODE
  $result = Get-WingetResult -ExitCode $exit
  $fatal = ($result -eq 'Failed') -and (-not $TolerateFailure)
  return [PSCustomObject]@{ Package = $Id; Source = $Source; Result = $result; Exit = $exit; Output = @($output); Fatal = $fatal }
}

$results = @()
foreach ($p in $wingetPackages) { $results += Install-WingetPackage -Id $p -Source 'winget' }
foreach ($p in $msstorePackages) { $results += Install-WingetPackage -Id $p -Source 'msstore' -TolerateFailure }

foreach ($r in $results.Where({ $_.Result -eq 'Failed' })) {
  $tail = @($r.Output | ForEach-Object { $_.ToString() } | Select-Object -Last 15) -join "`n"
  $message = "[winget] $($r.Package) failed from $($r.Source) (exit $($r.Exit))."
  if ($tail) { $message += "`n$tail" }
  Write-Warning $message
}

$results | Select-Object Package,Source,Result,Exit | Format-Table -AutoSize | Out-String | Write-Host

$failures = @($results | Where-Object { $_.Fatal })
$reboots = @($results | Where-Object { $_.Result -eq 'Reboot pending' })
if ($reboots.Count) { Write-Host "[winget] Reboot pending for: $($reboots.Package -join ', ')" }
if ($failures.Count) { throw "[winget] $($failures.Count) package(s) failed: $($failures.Package -join ', ')" }
$global:LASTEXITCODE = 0
