param(
  [string]$Distro = 'Ubuntu'
)
$ErrorActionPreference = 'Stop'

# Without WSL integration the distro still gets Docker Desktop's CLI symlink
# (/usr/bin/docker), but never /var/run/docker.sock, so every command fails with
# "dial unix /var/run/docker.sock: connect: no such file or directory".
# Integration is on by default, but nothing keeps it on: the setting lives only in
# the per-user settings-store.json, which a reset, an update or a UI toggle can flip.
$installSettings = Join-Path $env:ProgramData 'DockerDesktop\install-settings.json'
$userSettings = Join-Path $env:APPDATA 'Docker\settings-store.json'

if (-not (Test-Path -LiteralPath $installSettings)) {
  Write-Host '[docker-wsl] Docker Desktop not installed; nothing to do'
  return
}
if (-not (Test-Path -LiteralPath $userSettings)) {
  # Docker writes its full settings (SettingsVersion and all) on first launch, and
  # defaults integration to on. Seeding a partial file could upset that migration.
  Write-Warning "[docker-wsl] $userSettings does not exist yet. Launch Docker Desktop once, then re-run this task."
  return
}

$settings = Get-Content -Raw -LiteralPath $userSettings | ConvertFrom-Json
$distros = @($settings.IntegratedWslDistros | Where-Object { $_ })
$defaultOn = ($settings.EnableIntegrationWithDefaultWslDistro -eq $true)
$distroOn = ($distros -contains $Distro)

if ($defaultOn -and $distroOn) {
  Write-Host "[docker-wsl] ok WSL integration enabled for default distro and '$Distro'"
  return
}

# Docker Desktop owns this file while it runs and rewrites it on its next settings
# change, which would silently undo an edit made underneath it.
$running = @(Get-Process -Name 'Docker Desktop', 'com.docker.backend' -ErrorAction SilentlyContinue)
if ($running) {
  Write-Warning "[docker-wsl] WSL integration is off for '$Distro', but Docker Desktop is running. Either enable it in Settings > Resources > WSL Integration (default distro + '$Distro') and Apply & restart, or quit Docker Desktop and re-run this task."
  return
}

Copy-Item -LiteralPath $userSettings -Destination "$userSettings.bak" -Force
$settings | Add-Member -NotePropertyName EnableIntegrationWithDefaultWslDistro -NotePropertyValue $true -Force
$settings | Add-Member -NotePropertyName IntegratedWslDistros -NotePropertyValue ([string[]](@($distros) + $Distro | Select-Object -Unique)) -Force
# UTF-8 without a BOM under both Windows PowerShell and pwsh.
[IO.File]::WriteAllText($userSettings, ($settings | ConvertTo-Json -Depth 32), (New-Object System.Text.UTF8Encoding $false))
Write-Host "[docker-wsl] enabled WSL integration for default distro and '$Distro' (backup: $userSettings.bak); applies on Docker Desktop's next start"
