param(
  [string]$ArtifactRoot = 'Q:\.tools',
  [string]$SrcRoot = 'Q:\src',
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
    # -all matters here: after `setup.exe modify` returns 3010 the instance is
    # flagged incomplete/reboot-required, and plain vswhere hides it entirely.
    $paths = @(& $vswhere -products * -version '[17.0,18.0)' -prerelease -all -property installationPath 2>$null | Where-Object { $_ })
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

function Test-DevDriveSrcEnv {
  # Windows Terminal profiles use %DEVDRIVE_SRC% as their startingDirectory, so
  # this missing is what makes Command Prompt open somewhere unexpected.
  $value = [Environment]::GetEnvironmentVariable('DEVDRIVE_SRC', 'Machine')
  return ($value -and ($value.TrimEnd('\') -ieq $SrcRoot.TrimEnd('\')))
}

function Get-WslDistroInfo {
  # Collect fully before selecting: `Select-Object -First 1` tears the pipeline
  # down with a StopUpstreamCommandsException, which surfaces in transcripts as
  # "The pipeline has been stopped" and leaves $LASTEXITCODE unreliable.
  $all = @(
    Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction SilentlyContinue |
      ForEach-Object { Get-ItemProperty $_.PSPath } |
      Where-Object { $_.DistributionName -eq $Distro }
  )
  if ($all.Count -eq 0) { return $null }
  return $all[0]
}

function Test-WslDefaultUserNonRoot {
  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return $false }
  if (-not (Get-WslDistroInfo)) { return $false }
  # Capture the whole output and the exit code before filtering, so the pipeline
  # is never stopped underneath wsl.exe -- that made this check flaky.
  $output = @(& wsl.exe -d $Distro -- whoami 2>$null)
  $code = $LASTEXITCODE
  if ($code -ne 0) { return $false }
  $whoami = @($output | Where-Object { $_ -and $_.Trim() })[0]
  return ($whoami -and ($whoami.Trim() -ne 'root'))
}

function Test-NodeInstalled {
  if (Get-Command node -ErrorAction SilentlyContinue) { return $true }
  # nvm4w (installed by the WDC base setup) exposes node through a junction whose
  # directory is added to the *user* PATH, and the junction only appears once a
  # version has been activated. Fall back to the location it points at.
  $candidates = @(
    [Environment]::GetEnvironmentVariable('NVM_SYMLINK', 'Machine'),
    [Environment]::GetEnvironmentVariable('NVM_SYMLINK', 'User'),
    'C:\nvm4w\nodejs',
    "$env:ProgramFiles\nodejs"
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path (Join-Path $c 'node.exe'))) { return $true }
  }
  return $false
}

function Test-PowerToysInstalled {
  # PowerToys defaults to a per-user install; only the (rarer) machine-wide
  # installer lands under Program Files.
  $candidates = @(
    "$env:LOCALAPPDATA\PowerToys\PowerToys.exe",
    "$env:ProgramFiles\PowerToys\PowerToys.exe",
    "${env:ProgramFiles(x86)}\PowerToys\PowerToys.exe"
  )
  foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) { return $true }
  }
  return $false
}

function Test-WslVhdxOffC {
  $info = Get-WslDistroInfo
  if (-not $info -or -not $info.BasePath) { return $false }
  return ($info.BasePath -notmatch '^(\\\\\?\\)?C:')
}

function Test-TerminalFragmentProfiles {
  # Windows Terminal force-hides any generated profile it still remembers in
  # state.json but can no longer find in settings.json. Because dotfiles-links
  # replaces settings.json with this repo's copy, that is what silently drops
  # Ubuntu and Comfort Shell from the new-tab dropdown.
  $localAppData = "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local"

  $fragments = @{}
  $roots = @(
    "$localAppData\Microsoft\Windows Terminal\Fragments",
    "$env:ProgramData\Microsoft\Windows Terminal\Fragments"
  ) | Where-Object { Test-Path -LiteralPath $_ }
  foreach ($root in $roots) {
    foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.json' -ErrorAction SilentlyContinue) {
      try { $json = Get-Content -Raw -LiteralPath $file.FullName | ConvertFrom-Json } catch { continue }
      foreach ($entry in @($json.profiles)) {
        # "updates" entries patch another profile and have no GUID of their own.
        if (-not $entry.guid -or $entry.updates) { continue }
        $fragments[([string]$entry.guid).ToLowerInvariant()] = $true
      }
    }
  }
  if ($fragments.Count -eq 0) { return $true }

  # Stable, Preview and unpackaged installs each keep their own pair of files.
  $terminalDirs = @(
    "$localAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState",
    "$localAppData\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState",
    "$localAppData\Microsoft\Windows Terminal"
  )
  foreach ($dir in $terminalDirs) {
    $stateFile = Join-Path $dir 'state.json'
    $settingsFile = Join-Path $dir 'settings.json'
    if (-not (Test-Path -LiteralPath $stateFile) -or -not (Test-Path -LiteralPath $settingsFile)) { continue }
    try {
      $remembered = @((Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json).generatedProfiles |
          ForEach-Object { ([string]$_).ToLowerInvariant() })
      $listed = @((Get-Content -Raw -LiteralPath $settingsFile | ConvertFrom-Json).profiles.list |
          ForEach-Object { ([string]$_.guid).ToLowerInvariant() })
    } catch { return $false }
    foreach ($guid in $remembered) {
      if ($fragments.ContainsKey($guid) -and ($listed -notcontains $guid)) { return $false }
    }
  }
  return $true
}

function Test-NfvTerminalProfile {
  # The profile is a static entry in this repo's settings.json, which
  # dotfiles-links symlinks into Terminal's LocalState -- so a missing entry
  # means the link is gone, not that Terminal hid it.
  $launcher = Join-Path $PSScriptRoot '..\..\powershell\nfv-devshell.ps1'
  if (-not (Test-Path -LiteralPath $launcher)) { return $false }

  $localAppData = "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local"
  $settingsFiles = @(
    "$localAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$localAppData\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
    "$localAppData\Microsoft\Windows Terminal\settings.json"
  ) | Where-Object { Test-Path -LiteralPath $_ }
  if ($settingsFiles.Count -eq 0) { return $false }

  foreach ($file in $settingsFiles) {
    try { $json = Get-Content -Raw -LiteralPath $file | ConvertFrom-Json } catch { continue }
    if (@($json.profiles.list | Where-Object { $_.name -eq 'Networking-nfv' }).Count -gt 0) { return $true }
  }
  return $false
}

function Test-SudoInlineMode {
  # Not fatal to the NFV profile -- sudo just falls back to a new window -- but
  # it is the difference between an elevated tab and an elevated window.
  $sudo = Get-Command sudo.exe -ErrorAction SilentlyContinue
  if (-not $sudo) { return $false }
  return ((& $sudo.Source config 2>&1 | Out-String) -match 'Inline')
}

$checks = @(
  @{ Name='Docker'; Test={ Get-Command docker -ErrorAction SilentlyContinue } },
  @{ Name='Neovim'; Test={ Get-Command nvim -ErrorAction SilentlyContinue } },
  @{ Name='Az CLI'; Test={ Get-Command az -ErrorAction SilentlyContinue } },
  @{ Name='Node'; Test={ Test-NodeInstalled } },
  @{ Name='Go'; Test={ Get-Command go -ErrorAction SilentlyContinue } },
  @{ Name='Rustup'; Test={ Get-Command rustup -ErrorAction SilentlyContinue } },
  @{ Name='PowerToys'; Test={ Test-PowerToysInstalled } },
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
  @{ Name='Dev-drive src var'; Test={ Test-DevDriveSrcEnv } },
  @{ Name='WSL default user non-root'; Test={ Test-WslDefaultUserNonRoot } },
  @{ Name='WSL VHDX off C:'; Test={ Test-WslVhdxOffC } },
  @{ Name='Terminal fragment profiles'; Test={ Test-TerminalFragmentProfiles } },
  @{ Name='NFV terminal profile'; Test={ Test-NfvTerminalProfile } },
  @{ Name='Sudo inline mode'; Test={ Test-SudoInlineMode } }
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
