<#
.SYNOPSIS
  Stop Windows Terminal from hiding its dynamic and fragment profiles
  (Ubuntu/WSL, Comfort Shell, GitHub Copilot, the VS developer prompts).

.DESCRIPTION
  Terminal records every dynamic/fragment profile it has ever generated in
  state.json under "generatedProfiles". On each settings load,
  SettingsLoader::DisableDeletedProfiles() walks the generated profiles that
  have no entry in settings.json and, for any whose GUID is already in that
  list, forces Deleted/Hidden = true -- it assumes the user removed it on purpose.

  dotfiles-links replaces settings.json with this repo's copy. By then Terminal
  has usually seen the WSL distro's fragment (wsl-comfort touches settings.json
  to make it reload) and written its stub into the file that just got replaced.
  The WSL profile GUID is derived from the local distro ID, so the repo copy only
  carries other machines' Ubuntu stubs, and Terminal hides this machine's.

  So this task does two things:

  1. Appends a stub for every fragment profile settings.json doesn't list --
     the same guid/hidden/name/source entry Terminal writes for a profile it
     discovers. A listed profile is never hidden, so this works even while
     Terminal is running. When settings.json is the repo symlink, the stub lands
     in powershell\settings.json, exactly where Terminal itself would put it.
  2. Clears "generatedProfiles" when a remembered profile is still unlisted --
     a dynamic one such as a VS developer prompt, whose GUID can't be worked out
     without Terminal. Terminal then treats it as new on its next start and
     writes its own stub. Terminal reads state.json once at startup and writes
     its in-memory copy back, so this half needs every window closed.
#>
param(
  # Skip the "Terminal is running" warning; the reset itself always happens.
  [switch]$Force
)
$ErrorActionPreference = 'Stop'

$localAppData = "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local"

# Stable, Preview and unpackaged installs each keep their own state/settings pair.
$terminalDirs = @(
  "$localAppData\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState",
  "$localAppData\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState",
  "$localAppData\Microsoft\Windows Terminal"
)

$fragmentRoots = @(
  "$localAppData\Microsoft\Windows Terminal\Fragments",
  "$env:ProgramData\Microsoft\Windows Terminal\Fragments"
) | Where-Object { Test-Path -LiteralPath $_ }

function ConvertTo-GuidKey([string]$Value) {
  $parsed = [guid]::Empty
  if ([guid]::TryParse($Value, [ref]$parsed)) { return "{$parsed}" }
  return $null
}

function Get-FragmentProfiles {
  # Keyed by normalised GUID. Terminal reads <root>\<source>\*.json, and uses the
  # <source> folder name as the profile's "source", so mirror that layout exactly.
  $found = @{}
  foreach ($root in $fragmentRoots) {
    foreach ($folder in Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue) {
      foreach ($file in Get-ChildItem -LiteralPath $folder.FullName -File -Filter '*.json' -ErrorAction SilentlyContinue) {
        try { $json = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json } catch {
          Write-Warning "[terminal] unreadable fragment: $($file.FullName)"
          continue
        }
        foreach ($entry in @($json.profiles)) {
          # A fragment entry with "updates" patches an existing profile instead of
          # declaring a new one, so it has no GUID of its own to un-hide.
          if (-not $entry -or $entry.updates) { continue }
          $key = ConvertTo-GuidKey ([string]$entry.guid)
          if (-not $key -or $found.ContainsKey($key)) { continue }
          $found[$key] = [pscustomobject]@{
            Guid   = $key
            Name   = [string]$entry.name
            Source = $folder.Name
            Hidden = [bool]$entry.hidden
          }
        }
      }
    }
  }
  return $found
}

function Get-ListedProfileGuids([string]$SettingsFile) {
  if (-not (Test-Path -LiteralPath $SettingsFile)) { return @() }
  $json = Get-Content -LiteralPath $SettingsFile -Raw | ConvertFrom-Json
  # Terminal still accepts the legacy form where "profiles" is the list itself.
  $list = if ($json.profiles -is [array]) { $json.profiles } else { $json.profiles.list }
  return @($list | ForEach-Object { ConvertTo-GuidKey ([string]$_.guid) } | Where-Object { $_ })
}

function ConvertTo-JsonStringLiteral([string]$Value) {
  $escaped = $Value -replace '\\', '\\' -replace '"', '\"' -replace "`r", '\r' -replace "`n", '\n' -replace "`t", '\t'
  return '"' + $escaped + '"'
}

function Find-ProfileListEnd([string]$Text) {
  # Index of the ']' closing profiles.list (or a legacy "profiles" array), or -1.
  # A scan rather than a ConvertFrom-Json/ConvertTo-Json round-trip: settings.json
  # is normally this repo's tracked copy in Terminal's own formatting, and a
  # round-trip would rewrite every line of it.
  $keys = New-Object System.Collections.Generic.List[object]
  $lastString = $null
  $pendingKey = $null
  $i = 0
  while ($i -lt $Text.Length) {
    $ch = $Text[$i]
    if ($ch -eq '"') {
      $j = $i + 1
      while ($j -lt $Text.Length -and $Text[$j] -ne '"') {
        if ($Text[$j] -eq '\') { $j++ }
        $j++
      }
      $lastString = $Text.Substring($i + 1, [Math]::Min($j, $Text.Length) - $i - 1)
      $i = $j + 1
      continue
    }
    if ($ch -eq '/' -and ($i + 1) -lt $Text.Length -and $Text[$i + 1] -eq '/') {
      $j = $Text.IndexOf("`n", $i)
      if ($j -lt 0) { return -1 }
      $i = $j
      continue
    }
    if ($ch -eq '/' -and ($i + 1) -lt $Text.Length -and $Text[$i + 1] -eq '*') {
      $j = $Text.IndexOf('*/', $i + 2)
      if ($j -lt 0) { return -1 }
      $i = $j + 2
      continue
    }
    if ($ch -eq ':') {
      $pendingKey = $lastString
    } elseif ($ch -eq ',') {
      $pendingKey = $null
    } elseif ($ch -eq '{' -or $ch -eq '[') {
      $keys.Add($pendingKey)
      $pendingKey = $null
    } elseif ($ch -eq '}' -or $ch -eq ']') {
      if ($keys.Count -eq 0) { return -1 }
      if ($ch -eq ']') {
        $top = $keys[$keys.Count - 1]
        if (($keys.Count -eq 3 -and $top -eq 'list' -and $keys[1] -eq 'profiles') -or
            ($keys.Count -eq 2 -and $top -eq 'profiles')) {
          return $i
        }
      }
      $keys.RemoveAt($keys.Count - 1)
    }
    $i++
  }
  return -1
}

function Add-ProfileStubs([string]$Text, [object[]]$Stubs) {
  if (-not $Stubs -or $Stubs.Count -eq 0) { return $Text }
  $close = Find-ProfileListEnd $Text
  if ($close -lt 0) { return $null }

  $nl = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
  $lineStart = $Text.LastIndexOf("`n", $close) + 1
  $lineIndent = [regex]::Match($Text.Substring($lineStart), '^[ \t]*').Value
  $closeOnOwnLine = -not $Text.Substring($lineStart, $close - $lineStart).Trim()
  $itemIndent = $lineIndent + '    '
  $propIndent = $itemIndent + '    '

  $entries = foreach ($stub in $Stubs) {
    $props = @("$propIndent`"guid`": $(ConvertTo-JsonStringLiteral $stub.Guid)")
    $props += "$propIndent`"hidden`": $(if ($stub.Hidden) { 'true' } else { 'false' })"
    if ($stub.Name) { $props += "$propIndent`"name`": $(ConvertTo-JsonStringLiteral $stub.Name)" }
    $props += "$propIndent`"source`": $(ConvertTo-JsonStringLiteral $stub.Source)"
    "$itemIndent{$nl" + ($props -join ",$nl") + "$nl$itemIndent}"
  }

  $last = $close - 1
  while ($last -ge 0 -and [char]::IsWhiteSpace($Text[$last])) { $last-- }
  $separator = if ($last -ge 0 -and $Text[$last] -eq '[') { '' } else { ',' }
  # When ']' shares its line with content (an empty "[]", say), move it to its own line.
  $tail = if ($closeOnOwnLine) { '' } else { "$nl$lineIndent" }
  return $Text.Substring(0, $last + 1) + $separator + $nl + ($entries -join ",$nl") + $tail + $Text.Substring($last + 1)
}

$fragmentProfiles = Get-FragmentProfiles
$running = @(Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue)
$foundTerminal = $false
$needsRestart = @()

foreach ($dir in $terminalDirs) {
  $settingsFile = Join-Path $dir 'settings.json'
  $stateFile = Join-Path $dir 'state.json'
  if (-not (Test-Path -LiteralPath $settingsFile) -and -not (Test-Path -LiteralPath $stateFile)) { continue }
  $foundTerminal = $true

  # --- 1. Stubs for unlisted fragment profiles --------------------------------
  $listed = @()
  if (Test-Path -LiteralPath $settingsFile) {
    try { $listed = @(Get-ListedProfileGuids $settingsFile) } catch {
      Write-Warning "[terminal] could not parse ${settingsFile}: $($_.Exception.Message)"
      continue
    }

    $stubs = @($fragmentProfiles.Values | Where-Object { $listed -notcontains $_.Guid } | Sort-Object Source, Name)
    if ($stubs.Count -eq 0) {
      Write-Host "[terminal] ok every fragment profile is listed in $settingsFile"
    } else {
      $bytes = [System.IO.File]::ReadAllBytes($settingsFile)
      $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
      $text = [System.IO.File]::ReadAllText($settingsFile)
      $updated = Add-ProfileStubs $text $stubs

      # Only write what re-parses and now lists every stub; anything else (a
      # trailing comment before the ']', say) would corrupt the user's settings.
      $verified = $false
      if ($updated) {
        try {
          $reparsed = $updated | ConvertFrom-Json
          $list = if ($reparsed.profiles -is [array]) { $reparsed.profiles } else { $reparsed.profiles.list }
          $nowListed = @($list | ForEach-Object { ConvertTo-GuidKey ([string]$_.guid) })
          $verified = @($stubs | Where-Object { $nowListed -notcontains $_.Guid }).Count -eq 0
        } catch { $verified = $false }
      }
      if (-not $verified) {
        Write-Warning "[terminal] could not add profile entries to $settingsFile safely; add these to profiles.list by hand: $(@($stubs | ForEach-Object { "$($_.Name) $($_.Guid)" }) -join ', ')"
      } else {
        Copy-Item -LiteralPath $settingsFile -Destination "$settingsFile.dotfiles.bak" -Force
        # Written in place, not staged and moved: settings.json is usually a
        # symlink into this repo, and a move would replace the link with a copy.
        # WriteAllText rather than Set-Content because Windows PowerShell's
        # -Encoding UTF8 always emits a BOM.
        [System.IO.File]::WriteAllText($settingsFile, $updated, (New-Object System.Text.UTF8Encoding($hasBom)))
        $listed += @($stubs | ForEach-Object { $_.Guid })
        Write-Host "[terminal] listed $($stubs.Count) fragment profile(s) in ${settingsFile}: $(@($stubs | ForEach-Object { $_.Name }) -join ', ')"
      }
    }
  }

  # --- 2. Remembered profiles that are still unlisted -------------------------
  if (-not (Test-Path -LiteralPath $stateFile)) { continue }
  try { $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json } catch {
    Write-Warning "[terminal] could not parse ${stateFile}: $($_.Exception.Message)"
    continue
  }

  # An absent property still yields a single $null through @(...), which would
  # make an already-clean state file look like it had one profile to drop.
  $rememberedProperty = $state.PSObject.Properties['generatedProfiles']
  $remembered = @()
  if ($rememberedProperty) { $remembered = @($rememberedProperty.Value | ForEach-Object { ConvertTo-GuidKey ([string]$_) } | Where-Object { $_ }) }
  $hidden = @($remembered | Where-Object { $listed -notcontains $_ })
  if ($hidden.Count -eq 0) {
    Write-Host "[terminal] ok no remembered profile is missing from settings.json in $dir"
    continue
  }

  # state.json is regenerable, but it also holds window layouts and recent
  # commands, so keep a copy rather than deleting the file outright.
  Copy-Item -LiteralPath $stateFile -Destination "$stateFile.dotfiles.bak" -Force
  $state.PSObject.Properties.Remove('generatedProfiles')

  # Stage, re-parse, then swap. A half-written state.json would take Terminal's
  # window layouts and recent commands down with it.
  $staged = "$stateFile.dotfiles.tmp"
  try {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($staged, ($state | ConvertTo-Json -Depth 100), $encoding)
    $null = Get-Content -LiteralPath $staged -Raw | ConvertFrom-Json
    Move-Item -LiteralPath $staged -Destination $stateFile -Force
  } finally {
    if (Test-Path -LiteralPath $staged) { Remove-Item -LiteralPath $staged -Force -ErrorAction SilentlyContinue }
  }
  Write-Host "[terminal] cleared $($remembered.Count) remembered profile(s) from $stateFile ($($hidden.Count) not in settings.json)"
  $needsRestart += $stateFile
}

if (-not $foundTerminal) {
  Write-Host '[terminal] no Windows Terminal settings found; nothing to do.'
  return
}

if ($needsRestart.Count -eq 0) { return }

if ($running.Count -gt 0 -and -not $Force) {
  # Terminal flushes its in-memory state as it runs and on exit, which puts the
  # GUIDs straight back. Warn instead of pretending the reset stuck. Fragment
  # profiles are already safe via step 1; this only affects dynamic ones.
  Write-Warning '[terminal] Windows Terminal is running and will rewrite state.json, so dynamic profiles (e.g. VS developer prompts) may stay hidden. Close every Terminal window, re-run catalog\terminal-profiles\script.ps1, then start Terminal again.'
} else {
  Write-Host '[terminal] start Windows Terminal to pick the profiles back up.'
}
