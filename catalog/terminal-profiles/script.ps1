<#
.SYNOPSIS
  Stop Windows Terminal from hiding its dynamic and fragment profiles
  (Ubuntu/WSL, Comfort Shell, GitHub Copilot, the VS developer prompts).

.DESCRIPTION
  Terminal records every dynamic/fragment profile it has ever generated in
  state.json under "generatedProfiles". On each launch,
  SettingsLoader::DisableDeletedProfiles() walks the generated profiles and, for
  any whose GUID is already in that list but is *absent* from settings.json,
  forces Deleted/Hidden = true -- it assumes the user removed it on purpose.

  dotfiles-links replaces settings.json with this repo's curated copy, which
  only lists the static profiles. Every fragment profile is therefore "missing"
  from settings.json while still being remembered in state.json, so Terminal
  silently drops Ubuntu, Comfort Shell and friends from the new-tab dropdown.

  Clearing "generatedProfiles" makes Terminal treat them as newly discovered on
  its next start, so they show up again -- and Terminal writes its own stubs for
  them back into settings.json. Those stubs carry machine-specific GUIDs (the
  WSL profile GUID is derived from the local distro ID); leave them alone. If
  they ever get pruned from powershell\settings.json, re-run this task.

  Terminal only enumerates fragments at process start and rewrites state.json as
  it runs, so every window must be closed for this to take effect.
#>
param(
  # Skip the "Terminal is running" warning; the reset itself always happens.
  [switch]$Force
)
$ErrorActionPreference = 'Stop'

$localAppData = "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local"

$stateFiles = @(
  "$localAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\state.json",
  "$localAppData\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\state.json",
  "$localAppData\Microsoft\Windows Terminal\state.json"
) | Where-Object { Test-Path -LiteralPath $_ }

$fragmentRoots = @(
  "$localAppData\Microsoft\Windows Terminal\Fragments",
  "$env:ProgramData\Microsoft\Windows Terminal\Fragments"
) | Where-Object { Test-Path -LiteralPath $_ }

function Get-FragmentProfiles {
  # Fragment profiles are the ones this repo actually cares about; report them by
  # name so the run log shows what should come back after a restart.
  $found = @{}
  foreach ($root in $fragmentRoots) {
    foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.json' -ErrorAction SilentlyContinue) {
      try { $json = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json } catch {
        Write-Warning "[terminal] unreadable fragment: $($file.FullName)"
        continue
      }
      foreach ($entry in @($json.profiles)) {
        # A fragment entry with "updates" patches an existing profile instead of
        # declaring a new one, so it has no GUID of its own to un-hide.
        if ($entry.guid -and -not $entry.updates) { $found[[string]$entry.guid] = [string]$entry.name }
      }
    }
  }
  return $found
}

if ($stateFiles.Count -eq 0) {
  Write-Host '[terminal] no Windows Terminal state.json found; nothing to reset.'
  return
}

$fragmentProfiles = Get-FragmentProfiles
$running = @(Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue)
$cleared = 0

foreach ($stateFile in $stateFiles) {
  try { $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json } catch {
    Write-Warning "[terminal] could not parse ${stateFile}: $($_.Exception.Message)"
    continue
  }

  # An absent property still yields a single $null through @(...), which would
  # make an already-clean state file look like it had one profile to drop.
  $rememberedProperty = $state.PSObject.Properties['generatedProfiles']
  $remembered = @()
  if ($rememberedProperty) { $remembered = @($rememberedProperty.Value | Where-Object { $_ }) }
  if ($remembered.Count -eq 0) {
    Write-Host "[terminal] ok no remembered profiles in $stateFile"
    continue
  }

  $suppressed = @($remembered |
      Where-Object { $fragmentProfiles.ContainsKey([string]$_) } |
      ForEach-Object { $fragmentProfiles[[string]$_] })
  if ($suppressed.Count -gt 0) {
    Write-Host "[terminal] fragment profiles to restore: $($suppressed -join ', ')"
  }

  # state.json is regenerable, but it also holds window layouts and recent
  # commands, so keep a copy rather than deleting the file outright.
  Copy-Item -LiteralPath $stateFile -Destination "$stateFile.dotfiles.bak" -Force
  $state.PSObject.Properties.Remove('generatedProfiles')

  # Stage, re-parse, then swap. A half-written state.json would take Terminal's
  # window layouts and recent commands down with it. WriteAllText rather than
  # Set-Content because Windows PowerShell's -Encoding UTF8 emits a BOM.
  $staged = "$stateFile.dotfiles.tmp"
  try {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($staged, ($state | ConvertTo-Json -Depth 100), $encoding)
    $null = Get-Content -LiteralPath $staged -Raw | ConvertFrom-Json
    Move-Item -LiteralPath $staged -Destination $stateFile -Force
  } finally {
    if (Test-Path -LiteralPath $staged) { Remove-Item -LiteralPath $staged -Force -ErrorAction SilentlyContinue }
  }
  Write-Host "[terminal] cleared $($remembered.Count) remembered profile(s) from $stateFile"
  $cleared++
}

if ($cleared -eq 0) {
  Write-Host '[terminal] nothing to clear.'
  return
}

if ($running.Count -gt 0 -and -not $Force) {
  # Terminal flushes its in-memory state on exit, which puts the GUIDs straight
  # back. Warn instead of pretending the reset stuck.
  Write-Warning '[terminal] Windows Terminal is running and will rewrite state.json when it exits. Close every Terminal window, re-run catalog\terminal-profiles\script.ps1, then start Terminal again.'
} else {
  Write-Host '[terminal] start Windows Terminal to pick the profiles back up (fragments are only enumerated at process start).'
}
