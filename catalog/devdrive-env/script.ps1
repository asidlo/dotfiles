param(
  [string]$ArtifactRoot = 'Q:\.tools',
  [string]$SrcRoot = 'Q:\src'
)
$ErrorActionPreference = 'Stop'

$variables = @(
  # Consumed by Windows Terminal profiles (powershell\settings.json) as
  # %DEVDRIVE_SRC%, so the profiles follow the Dev Drive instead of hard-coding
  # a drive letter. Windows Terminal expands environment variables in
  # startingDirectory and falls back to the shell's own default when unset.
  @{ Name = 'DEVDRIVE_SRC'; Value = $SrcRoot; Directory = $SrcRoot },
  @{ Name = 'DEVDRIVE_ARTIFACTS'; Value = $ArtifactRoot; Directory = $ArtifactRoot },
  @{ Name = 'NUGET_PACKAGES'; Value = Join-Path $ArtifactRoot '.nuget\packages'; Directory = Join-Path $ArtifactRoot '.nuget\packages' },
  @{ Name = 'NUGET_HTTP_CACHE_PATH'; Value = Join-Path $ArtifactRoot '.nuget\v3-cache'; Directory = Join-Path $ArtifactRoot '.nuget\v3-cache' },
  @{ Name = 'NUGET_PLUGINS_CACHE_PATH'; Value = Join-Path $ArtifactRoot '.nuget\plugins-cache'; Directory = Join-Path $ArtifactRoot '.nuget\plugins-cache' },
  @{ Name = 'npm_config_cache'; Value = Join-Path $ArtifactRoot '.npm'; Directory = Join-Path $ArtifactRoot '.npm' },
  @{ Name = 'npm_config_prefix'; Value = Join-Path $ArtifactRoot '.npm-global'; Directory = Join-Path $ArtifactRoot '.npm-global' },
  @{ Name = 'PNPM_HOME'; Value = Join-Path $ArtifactRoot 'pnpm'; Directory = Join-Path $ArtifactRoot 'pnpm' },
  @{ Name = 'PNPM_STORE_DIR'; Value = Join-Path $ArtifactRoot 'pnpm\store'; Directory = Join-Path $ArtifactRoot 'pnpm\store' },
  @{ Name = 'YARN_CACHE_FOLDER'; Value = Join-Path $ArtifactRoot 'yarn\cache'; Directory = Join-Path $ArtifactRoot 'yarn\cache' },
  @{ Name = 'GOPATH'; Value = Join-Path $ArtifactRoot 'go'; Directory = Join-Path $ArtifactRoot 'go' },
  @{ Name = 'GOMODCACHE'; Value = Join-Path $ArtifactRoot 'go\pkg\mod'; Directory = Join-Path $ArtifactRoot 'go\pkg\mod' },
  @{ Name = 'GOCACHE'; Value = Join-Path $ArtifactRoot 'go\cache'; Directory = Join-Path $ArtifactRoot 'go\cache' },
  @{ Name = 'CARGO_HOME'; Value = Join-Path $ArtifactRoot 'cargo'; Directory = Join-Path $ArtifactRoot 'cargo' },
  @{ Name = 'RUSTUP_HOME'; Value = Join-Path $ArtifactRoot 'rustup'; Directory = Join-Path $ArtifactRoot 'rustup' },
  @{ Name = 'PIP_CACHE_DIR'; Value = Join-Path $ArtifactRoot 'pip'; Directory = Join-Path $ArtifactRoot 'pip' },
  @{ Name = 'UV_CACHE_DIR'; Value = Join-Path $ArtifactRoot 'uv\cache'; Directory = Join-Path $ArtifactRoot 'uv\cache' },
  @{ Name = 'DOTNET_CLI_HOME'; Value = Join-Path $ArtifactRoot 'dotnet'; Directory = Join-Path $ArtifactRoot 'dotnet' },
  @{ Name = 'VCPKG_DEFAULT_BINARY_CACHE'; Value = Join-Path $ArtifactRoot 'vcpkg\bincache'; Directory = Join-Path $ArtifactRoot 'vcpkg\bincache' },
  @{ Name = 'VCPKG_DOWNLOADS'; Value = Join-Path $ArtifactRoot 'vcpkg\downloads'; Directory = Join-Path $ArtifactRoot 'vcpkg\downloads' },
  @{ Name = 'GRADLE_USER_HOME'; Value = Join-Path $ArtifactRoot 'gradle'; Directory = Join-Path $ArtifactRoot 'gradle' },
  @{ Name = 'MAVEN_OPTS'; Value = "-Dmaven.repo.local=$ArtifactRoot\m2\repository"; Directory = Join-Path $ArtifactRoot 'm2\repository' },
  @{ Name = 'DOCKER_CONFIG'; Value = Join-Path $ArtifactRoot 'docker\config'; Directory = Join-Path $ArtifactRoot 'docker\config' },
  @{ Name = 'BUILDX_CONFIG'; Value = Join-Path $ArtifactRoot 'docker\buildx'; Directory = Join-Path $ArtifactRoot 'docker\buildx' }
)

$set = 0
$ok = 0
foreach ($var in $variables) {
  New-Item -ItemType Directory -Force -Path $var.Directory | Out-Null
  Set-Item -Path "Env:$($var.Name)" -Value $var.Value
  $current = [Environment]::GetEnvironmentVariable($var.Name, 'Machine')
  if ($current -eq $var.Value) {
    Write-Host "[devdrive] ok $($var.Name)"
    $ok++
    continue
  }

  [Environment]::SetEnvironmentVariable($var.Name, $var.Value, 'Machine')
  Write-Host "[devdrive] set $($var.Name) = $($var.Value)"
  $set++
}

$pathEntries = @(
  (Join-Path $ArtifactRoot '.npm-global'),
  (Join-Path $ArtifactRoot 'cargo\bin'),
  (Join-Path $ArtifactRoot 'go\bin')
)
foreach ($entry in $pathEntries) {
  New-Item -ItemType Directory -Force -Path $entry | Out-Null
}

function Normalize-PathEntry([string]$Entry) {
  return $Entry.Trim().TrimEnd('\').ToLowerInvariant()
}

$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$existing = @($machinePath -split ';' | Where-Object { $_.Trim() })
$normalized = @{}
foreach ($entry in $existing) {
  $normalized[(Normalize-PathEntry $entry)] = $true
}

$missing = @()
foreach ($entry in $pathEntries) {
  if (-not $normalized.ContainsKey((Normalize-PathEntry $entry))) {
    $missing += $entry
  }
}

if ($missing.Count -eq 0) {
  Write-Host '[devdrive] ok Path'
} else {
  $newPath = @($missing + $existing) -join ';'
  [Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
  $env:Path = @($missing + @($env:Path -split ';' | Where-Object { $_.Trim() })) -join ';'
  Write-Host "[devdrive] prepended Path = $($missing -join ';')"
}

try {
  # Docker Desktop's WSL 2 disk. winget-core sets it at install time via the
  # installer's --wsl-default-data-root (recorded as wslDefaultDataRoot in
  # install-settings.json); settings-store.json's CustomWslDistroDir overrides it
  # once the disk has been moved in the UI. Neither is edited here: pointing Docker
  # at a new folder by hand orphans the existing disk, and settings-store.json does
  # not exist until Docker Desktop's first launch anyway. (The `dataFolder` setting
  # this used to write is the Hyper-V backend's disk, which WSL 2 ignores.)
  $dockerData = Join-Path $ArtifactRoot 'docker\data'
  New-Item -ItemType Directory -Force -Path $dockerData | Out-Null
  $installSettings = Join-Path $env:ProgramData 'DockerDesktop\install-settings.json'
  $userSettings = Join-Path $env:APPDATA 'Docker\settings-store.json'

  if (-not (Test-Path -LiteralPath $installSettings)) {
    Write-Host '[devdrive] Docker Desktop not installed; nothing to relocate'
  } else {
    $dockerDisk = $null
    if (Test-Path -LiteralPath $userSettings) {
      $user = Get-Content -Raw -LiteralPath $userSettings | ConvertFrom-Json
      $dockerDisk = @($user.CustomWslDistroDir, $user.customWslDistroDir) | Where-Object { $_ } | Select-Object -First 1
    }
    if (-not $dockerDisk) {
      $dockerDisk = (Get-Content -Raw -LiteralPath $installSettings | ConvertFrom-Json).wslDefaultDataRoot
    }
    $wanted = $dockerData.TrimEnd('\')

    if ($dockerDisk -and ($dockerDisk.TrimEnd('\') -ieq $wanted)) {
      Write-Host '[devdrive] ok Docker Desktop WSL disk location'
    } else {
      $where = if ($dockerDisk) { $dockerDisk } else { 'its default under %LOCALAPPDATA%\Docker\wsl' }
      if (Test-Path -LiteralPath $userSettings) {
        Write-Warning "[devdrive] Docker Desktop keeps its WSL disk in $where. Move it with Docker Desktop > Settings > Resources > Advanced > Disk image location -> $wanted."
      } else {
        Write-Warning "[devdrive] Docker Desktop was installed without --wsl-default-data-root, so its WSL disk will land in $where. Before first launch: winget uninstall Docker.DockerDesktop, then re-run install.ps1. After: Settings > Resources > Advanced > Disk image location -> $wanted."
      }
    }
  }
} catch {
  Write-Warning "[devdrive] could not check Docker Desktop's disk location: $($_.Exception.Message)"
}

Write-Host "[devdrive] $set variable(s) set, $ok already correct"
if ($set -gt 0) {
  Write-Host '[devdrive] machine variables apply to new processes only; restart Windows Terminal (or sign out) before %DEVDRIVE_SRC% resolves in its profiles.'
}
