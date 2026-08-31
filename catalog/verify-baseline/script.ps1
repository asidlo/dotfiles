param(
  [string]$ArtifactRoot = 'Q:\.tools',
  [string]$VsInstallPath = 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise',
  [string]$NfvRepoPath = 'Q:\src\Networking-nfv',
  [string]$Distro = 'Ubuntu',
  # Check names the caller deliberately opted out of (e.g. -SkipVisualStudio).
  # Reported as "Skipped" instead of counting as a missing baseline item.
  [string[]]$SkipChecks = @()
)
$ErrorActionPreference = 'Continue'

$machinePath = [Environment]::GetEnvironmentVariable('Path','Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path','User')
$env:Path = (@($machinePath, $userPath) | Where-Object { $_ }) -join ';'

function Test-VS2022Enterprise {
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (Test-Path $vswhere) {
    $paths = @(& $vswhere -products * -version '[17.0,18.0)' -property installationPath 2>$null | Where-Object { $_ })
    if ($paths | Where-Object { Test-Path (Join-Path $_ 'Common7\IDE\devenv.exe') }) { return $true }
  }
  return (Test-Path (Join-Path $VsInstallPath 'Common7\IDE\devenv.exe'))
}

function Test-ArtifactMachineEnv {
  $names = @('NUGET_PACKAGES','npm_config_cache','GOPATH','CARGO_HOME')
  foreach ($name in $names) {
    $value = [Environment]::GetEnvironmentVariable($name, 'Machine')
    if (-not $value) { return $false }
    if (-not $value.StartsWith($ArtifactRoot, [System.StringComparison]::OrdinalIgnoreCase)) { return $false }
  }
  return $true
}

function Get-WslDistroInfo {
  Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DistributionName -eq $Distro } |
    Select-Object -First 1
}

function Test-WslDefaultUserNonRoot {
  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $false }
  if (-not (Get-WslDistroInfo)) { return $false }
  $whoami = (& wsl.exe -d $Distro -- whoami 2>$null | Select-Object -First 1)
  return (($LASTEXITCODE -eq 0) -and $whoami -and ($whoami.Trim() -ne 'root'))
}

function Test-WslVhdxOffC {
  $info = Get-WslDistroInfo
  if (-not $info -or -not $info.BasePath) { return $false }
  return ($info.BasePath -notmatch '^(\\\\\?\\)?C:')
}

$checks = @(
  @{ Name='Docker'; Test={ Get-Command docker -ErrorAction SilentlyContinue } },
  @{ Name='Neovim'; Test={ Get-Command nvim -ErrorAction SilentlyContinue } },
  @{ Name='Az CLI'; Test={ Get-Command az -ErrorAction SilentlyContinue } },
  @{ Name='Node'; Test={ Get-Command node -ErrorAction SilentlyContinue } },
  @{ Name='Go'; Test={ Get-Command go -ErrorAction SilentlyContinue } },
  @{ Name='Rustup'; Test={ Get-Command rustup -ErrorAction SilentlyContinue } },
  @{ Name='PowerToys'; Test={ Test-Path 'C:\Program Files\PowerToys\PowerToys.exe' } },
  @{ Name='Meslo Nerd Font'; Test={ (Get-ChildItem "$env:WINDIR\Fonts" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Meslo' }) } },
  @{ Name='Gitconfig link'; Test={ Test-Path "$env:HOMEDRIVE$env:HOMEPATH\.gitconfig" } },
  @{ Name='Starship config'; Test={ Test-Path "$env:HOMEDRIVE$env:HOMEPATH\.config\starship.toml" } },
  @{ Name='VS 2022 Enterprise'; Test={ Test-VS2022Enterprise } },
  @{ Name='Networking-nfv repo'; Test={ Test-Path (Join-Path $NfvRepoPath '.git') } },
  @{ Name='NFV.vsconfig present'; Test={ Test-Path (Join-Path $NfvRepoPath 'NFV.vsconfig') } },
  @{ Name='agency'; Test={ Get-Command agency -ErrorAction SilentlyContinue } },
  @{ Name='copilot CLI'; Test={ Get-Command copilot -ErrorAction SilentlyContinue } },
  @{ Name='anvil plugin'; Test={ if (Get-Command copilot -ErrorAction SilentlyContinue) { & copilot plugin list 2>&1 | Select-String 'anvil' -Quiet } else { $false } } },
  @{ Name='Dev-drive env vars'; Test={ Test-ArtifactMachineEnv } },
  @{ Name='WSL default user non-root'; Test={ Test-WslDefaultUserNonRoot } },
  @{ Name='WSL VHDX off C:'; Test={ Test-WslVhdxOffC } }
)
$results = foreach ($c in $checks) {
  if ($SkipChecks -contains $c.Name) {
    [PSCustomObject]@{ Item = $c.Name; Present = $true; Status = 'Skipped' }
  } else {
    $present = [bool](& $c.Test)
    [PSCustomObject]@{ Item = $c.Name; Present = $present; Status = $(if ($present) { 'Present' } else { 'MISSING' }) }
  }
}
$results | Format-Table Item, Status -AutoSize | Out-String | Write-Host
$missing = @($results | Where-Object { -not $_.Present })
if ($missing.Count -eq 0) {
  Write-Host '[verify] All baseline items present.'
  $global:LASTEXITCODE = 0
} else {
  Write-Host '[verify] Missing items:'
  $missing | ForEach-Object { Write-Host " - $($_.Item)" }
  exit 1
}
