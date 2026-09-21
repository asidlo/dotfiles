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
  $dockerData = Join-Path $ArtifactRoot 'docker\data'
  New-Item -ItemType Directory -Force -Path $dockerData | Out-Null
  $settings = @(
    (Join-Path $env:APPDATA 'Docker\settings-store.json'),
    (Join-Path $env:APPDATA 'Docker\settings.json')
  ) | Where-Object { Test-Path $_ }

  # Docker Desktop rewrites its settings file on shutdown, so editing it while the
  # app is running silently loses the change. Warn instead of pretending it worked.
  $dockerRunning = @(Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue).Count -gt 0

  if ($settings.Count -eq 0) {
    Write-Warning '[devdrive] Docker Desktop settings not found; re-run after Docker Desktop is installed/configured to move its WSL data disk.'
  } elseif ($dockerRunning) {
    Write-Warning "[devdrive] Docker Desktop is running; not editing its settings (it would overwrite them on exit). Quit Docker Desktop and re-run this task, or set Settings > Resources > Disk image location to $dockerData."
  } else {
    foreach ($path in $settings) {
      $json = Get-Content -Raw -Path $path | ConvertFrom-Json
      if ($json.PSObject.Properties.Name -contains 'dataFolder') {
        $json.dataFolder = $dockerData
      } else {
        $json | Add-Member -NotePropertyName dataFolder -NotePropertyValue $dockerData
      }

      $json | ConvertTo-Json -Depth 32 | Set-Content -Path $path -Encoding UTF8
      Write-Host "[devdrive] set Docker dataFolder = $dockerData ($path)"
    }
    Write-Host '[devdrive] restart Docker Desktop for the new data folder to take effect.'
  }
} catch {
  Write-Warning "[devdrive] could not update Docker Desktop dataFolder: $($_.Exception.Message)"
}

Write-Host "[devdrive] $set variable(s) set, $ok already correct"
if ($set -gt 0) {
  Write-Host '[devdrive] machine variables apply to new processes only; restart Windows Terminal (or sign out) before %DEVDRIVE_SRC% resolves in its profiles.'
}
