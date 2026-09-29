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

  The VS developer prompts are hidden a second way. VisualStudioGenerator.cpp
  generates a Developer Command Prompt and Developer PowerShell per Visual
  Studio instance, but "hide[s] all but the profiles for the latest instance",
  so with VS 18 installed side-by-side the VS 2022 pair is generated hidden and
  Terminal writes its stub with "hidden": true.

  So this task does three things:

  1. Appends a stub for every fragment profile settings.json doesn't list --
     the same guid/hidden/name/source entry Terminal writes for a profile it
     discovers. A listed profile is never hidden, so this works even while
     Terminal is running. When settings.json is the repo symlink, the stub lands
     in powershell\settings.json, exactly where Terminal itself would put it.
  2. Does the same for every Visual Studio instance's two prompts, with
     "hidden": false, and flips Terminal's own "hidden": true stub for them.
     Their GUIDs are UUIDv5s of the instance ID, worked out here as Terminal
     does. An entry with any setting beyond Terminal's four is treated as
     yours and left alone.
  3. Clears "generatedProfiles" when a remembered profile is still unlisted --
     another dynamic one, whose GUID can't be worked out without Terminal.
     Terminal then treats it as new on its next start and writes its own stub.
     Terminal reads state.json once at startup and writes its in-memory copy
     back, so this half needs every window closed.
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
        try { $json = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch {
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

function New-TerminalProfileGuid([string]$Seed) {
  # Utils::CreateV5Uuid over TERMINAL_PROFILE_NAMESPACE_GUID and the UTF-16LE seed.
  $namespaceBytes = ([guid]'2bde4a90-d05f-401c-9492-e40884ead1d8').ToByteArray()
  # Guid.ToByteArray() is little-endian in its first three fields; RFC 4122
  # hashes and lays out the bytes in network order.
  [Array]::Reverse($namespaceBytes, 0, 4); [Array]::Reverse($namespaceBytes, 4, 2); [Array]::Reverse($namespaceBytes, 6, 2)
  $sha1 = [System.Security.Cryptography.SHA1]::Create()
  try { $hash = $sha1.ComputeHash([byte[]]($namespaceBytes + [System.Text.Encoding]::Unicode.GetBytes($Seed))) } finally { $sha1.Dispose() }
  $bytes = [byte[]]$hash[0..15]
  $bytes[6] = ($bytes[6] -band 0x0F) -bor 0x50
  $bytes[8] = ($bytes[8] -band 0x3F) -bor 0x80
  [Array]::Reverse($bytes, 0, 4); [Array]::Reverse($bytes, 4, 2); [Array]::Reverse($bytes, 6, 2)
  return '{' + (New-Object System.Guid (, $bytes)).ToString() + '}'
}

function Get-VisualStudioProfiles {
  # Keyed by normalised GUID, mirroring VsDevCmdGenerator/VsDevShellGenerator.
  $found = @{}
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (-not (Test-Path -LiteralPath $vswhere)) { return $found }

  # Terminal enumerates launchable instances of every product, prereleases
  # included: vswhere's default set without its product and prerelease filters.
  $previousEncoding = [Console]::OutputEncoding
  # Windows PowerShell turns native stderr into errors even with 2>$null, which
  # 'Stop' would throw; the exit code is checked instead.
  $ErrorActionPreference = 'Continue'
  try {
    try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
    $raw = @(& $vswhere -prerelease -products * -format json -utf8 2>$null)
    $exitCode = $LASTEXITCODE
  } finally {
    try { [Console]::OutputEncoding = $previousEncoding } catch { }
    $ErrorActionPreference = 'Stop'
  }
  $global:LASTEXITCODE = 0
  if ($exitCode -ne 0) {
    Write-Warning "[terminal] vswhere exited with $exitCode; Visual Studio prompts left as they are."
    return $found
  }
  # Assigned first: Windows PowerShell's ConvertFrom-Json emits a JSON array as
  # one object, so @(... | ConvertFrom-Json) would nest it.
  try { $parsed = ($raw -join "`n") | ConvertFrom-Json } catch {
    Write-Warning "[terminal] could not read vswhere output; Visual Studio prompts left as they are."
    return $found
  }
  $instances = @($parsed)

  foreach ($vs in $instances) {
    $id = [string]$vs.instanceId
    $path = [string]$vs.installationPath
    if (-not $id -or -not $path) { continue }

    # VsSetupInstance::BuildProfileNameSuffix: "2022", then " (nickname)" or a
    # " [Preview]"-style tag for a non-Release channel.
    $suffix = [string]$vs.catalog.productLineVersion
    $nickname = if ($vs.properties) { [string]$vs.properties.nickname } else { '' }
    $channel = ([string]$vs.channelId -split '\.')[-1]
    if ($nickname) { $suffix += " ($nickname)" } elseif ($channel -and $channel -ne 'Release') { $suffix += " [$channel]" }
    if (-not $vs.catalog) { $suffix = [string]$vs.installationVersion }

    $version = $null
    [void][version]::TryParse([string]$vs.installationVersion, [ref]$version)

    if (Test-Path -LiteralPath (Join-Path $path 'Common7\Tools\VsDevCmd.bat')) {
      $guid = New-TerminalProfileGuid "VsDevCmd$id"
      $found[$guid] = [pscustomobject]@{ Guid = $guid; Name = "Developer Command Prompt for VS $suffix"; Source = 'Windows.Terminal.VisualStudio'; Hidden = $false }
    }
    # The DevShell module moved in 16.3, and 16.2 is the first release with it at all.
    $module = if ($version -and $version -ge [version]'16.3') { 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll' } else { 'Common7\Tools\vsdevshell\Microsoft.VisualStudio.DevShell.dll' }
    if ($version -and $version -ge [version]'16.2' -and (Test-Path -LiteralPath (Join-Path $path $module))) {
      $guid = New-TerminalProfileGuid "VsDevShell$id"
      $found[$guid] = [pscustomobject]@{ Guid = $guid; Name = "Developer PowerShell for VS $suffix"; Source = 'Windows.Terminal.VisualStudio'; Hidden = $false }
    }
  }
  return $found
}

function Get-ProfileEntries($Json) {
  # Terminal still accepts the legacy form where "profiles" is the list itself.
  $list = if ($Json.profiles -is [array]) { $Json.profiles } else { $Json.profiles.list }
  return @($list | Where-Object { $_ })
}

function Get-ListedProfiles([string]$SettingsFile) {
  # Keyed by normalised GUID. IsStub marks an entry with only the four settings
  # Terminal writes for a generated profile; anything more was customised.
  $listed = @{}
  if (-not (Test-Path -LiteralPath $SettingsFile)) { return $listed }
  $json = Get-Content -LiteralPath $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($entry in Get-ProfileEntries $json) {
    $key = ConvertTo-GuidKey ([string]$entry.guid)
    if (-not $key -or $listed.ContainsKey($key)) { continue }
    $names = @($entry.PSObject.Properties | ForEach-Object { $_.Name })
    $listed[$key] = [pscustomobject]@{
      Guid   = $key
      Name   = [string]$entry.name
      Hidden = ($entry.hidden -eq $true)
      IsStub = (@($names | Where-Object { @('guid', 'hidden', 'name', 'source') -notcontains $_ }).Count -eq 0)
    }
  }
  return $listed
}

function ConvertTo-JsonStringLiteral([string]$Value) {
  $escaped = $Value -replace '\\', '\\' -replace '"', '\"' -replace "`r", '\r' -replace "`n", '\n' -replace "`t", '\t'
  return '"' + $escaped + '"'
}

function Read-ProfileList([string]$Text) {
  # End: index of the ']' closing profiles.list (or a legacy "profiles" array),
  # or -1. Objects: the start and end index of each profile object in it.
  # A scan rather than a ConvertFrom-Json/ConvertTo-Json round-trip: settings.json
  # is normally this repo's tracked copy in Terminal's own formatting, and a
  # round-trip would rewrite every line of it.
  $layout = [pscustomobject]@{ End = -1; Objects = New-Object System.Collections.Generic.List[object] }
  # One entry per open container: the key it was opened under, and '{' or '['.
  $keys = New-Object System.Collections.Generic.List[object]
  $kinds = New-Object System.Collections.Generic.List[char]
  $lastString = $null
  $pendingKey = $null
  $objectStart = -1
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
      if ($j -lt 0) { return $layout }
      $i = $j
      continue
    }
    if ($ch -eq '/' -and ($i + 1) -lt $Text.Length -and $Text[$i + 1] -eq '*') {
      $j = $Text.IndexOf('*/', $i + 2)
      if ($j -lt 0) { return $layout }
      $i = $j + 2
      continue
    }
    if ($ch -eq ':') {
      $pendingKey = $lastString
    } elseif ($ch -eq ',') {
      $pendingKey = $null
    } elseif ($ch -eq '{' -or $ch -eq '[') {
      # Innermost open container is the profile list: "profiles": { "list": [ ... ] },
      # or the legacy "profiles": [ ... ].
      $n = $keys.Count
      $atList = ($n -eq 3 -and $kinds[2] -eq '[' -and $keys[2] -eq 'list' -and $kinds[1] -eq '{' -and $keys[1] -eq 'profiles') -or
                ($n -eq 2 -and $kinds[1] -eq '[' -and $keys[1] -eq 'profiles')
      if ($ch -eq '{' -and $atList) { $objectStart = $i }
      $keys.Add($pendingKey)
      $kinds.Add($ch)
      $pendingKey = $null
    } elseif ($ch -eq '}' -or $ch -eq ']') {
      $n = $keys.Count
      if ($n -eq 0) { return $layout }
      $closing = ($n -eq 3 -and $keys[2] -eq 'list' -and $keys[1] -eq 'profiles' -and $kinds[1] -eq '{') -or
                 ($n -eq 2 -and $keys[1] -eq 'profiles')
      if ($ch -eq ']' -and $kinds[$n - 1] -eq '[' -and $closing) {
        $layout.End = $i
        return $layout
      }
      $keys.RemoveAt($n - 1)
      $kinds.RemoveAt($n - 1)
      if ($ch -eq '}' -and $objectStart -ge 0) {
        $n = $keys.Count
        $backAtList = ($n -eq 3 -and $kinds[2] -eq '[' -and $keys[2] -eq 'list' -and $kinds[1] -eq '{' -and $keys[1] -eq 'profiles') -or
                      ($n -eq 2 -and $kinds[1] -eq '[' -and $keys[1] -eq 'profiles')
        if ($backAtList) {
          $layout.Objects.Add([pscustomobject]@{ Start = $objectStart; End = $i })
          $objectStart = -1
        }
      }
    }
    $i++
  }
  return $layout
}

function Find-ProfileListEnd([string]$Text) {
  return (Read-ProfileList $Text).End
}

function Show-ListedProfiles([string]$Text, [string[]]$Guids) {
  # Flips "hidden": true to false in the listed profile objects with these
  # GUIDs, rewriting only that one token. $null when that isn't clear-cut.
  if (-not $Guids -or $Guids.Count -eq 0) { return $Text }
  $layout = Read-ProfileList $Text
  if ($layout.End -lt 0) { return $null }
  $edits = @()
  foreach ($span in $layout.Objects) {
    $body = $Text.Substring($span.Start, $span.End - $span.Start + 1)
    try { $entry = $body | ConvertFrom-Json } catch { continue }
    $key = ConvertTo-GuidKey ([string]$entry.guid)
    if (-not $key -or $Guids -notcontains $key) { continue }
    $hits = [regex]::Matches($body, '(?<!\\)"hidden"(\s*:\s*)true\b')
    if ($hits.Count -ne 1) { return $null }
    $edits += [pscustomobject]@{ Index = $span.Start + $hits[0].Index; Length = $hits[0].Length; Value = '"hidden"' + $hits[0].Groups[1].Value + 'false' }
  }
  $builder = New-Object System.Text.StringBuilder($Text)
  foreach ($edit in @($edits | Sort-Object Index -Descending)) {
    [void]$builder.Remove($edit.Index, $edit.Length).Insert($edit.Index, $edit.Value)
  }
  return $builder.ToString()
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
$vsProfiles = Get-VisualStudioProfiles
$running = @(Get-Process -Name 'WindowsTerminal' -ErrorAction SilentlyContinue)
$foundTerminal = $false
$needsRestart = @()

foreach ($dir in $terminalDirs) {
  $settingsFile = Join-Path $dir 'settings.json'
  $stateFile = Join-Path $dir 'state.json'
  if (-not (Test-Path -LiteralPath $settingsFile) -and -not (Test-Path -LiteralPath $stateFile)) { continue }
  $foundTerminal = $true

  # --- 1-2. Entries for fragment and Visual Studio profiles -------------------
  $listed = @()
  if (Test-Path -LiteralPath $settingsFile) {
    try { $listedProfiles = Get-ListedProfiles $settingsFile } catch {
      Write-Warning "[terminal] could not parse ${settingsFile}: $($_.Exception.Message)"
      continue
    }
    $listed = @($listedProfiles.Keys)

    $stubs = @(@($fragmentProfiles.Values) + @($vsProfiles.Values) |
        Where-Object { $_ -and -not $listedProfiles.ContainsKey($_.Guid) } | Sort-Object Source, Name)
    # Terminal's own stubs for the instances it chose to hide; a customised entry is left alone.
    $toShow = @($vsProfiles.Values | Where-Object {
        $listedProfiles.ContainsKey($_.Guid) -and $listedProfiles[$_.Guid].Hidden -and $listedProfiles[$_.Guid].IsStub
      } | Sort-Object Name)
    if ($stubs.Count -eq 0 -and $toShow.Count -eq 0) {
      Write-Host "[terminal] ok every fragment and Visual Studio profile is listed in $settingsFile"
    } else {
      $bytes = [System.IO.File]::ReadAllBytes($settingsFile)
      $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
      $text = [System.IO.File]::ReadAllText($settingsFile)
      $updated = Show-ListedProfiles $text @($toShow | ForEach-Object { $_.Guid })
      if ($null -ne $updated) { $updated = Add-ProfileStubs $updated $stubs }

      # Only write what re-parses to the same profiles plus the stubs, with the
      # flipped ones shown; anything else (a trailing comment before the ']',
      # say) would corrupt the user's settings.
      $verified = $false
      if ($updated) {
        try {
          $before = @(Get-ProfileEntries ($text | ConvertFrom-Json))
          $after = @(Get-ProfileEntries ($updated | ConvertFrom-Json))
          $afterByGuid = @{}
          foreach ($entry in $after) { $key = ConvertTo-GuidKey ([string]$entry.guid); if ($key) { $afterByGuid[$key] = $entry } }
          $showGuids = @($toShow | ForEach-Object { $_.Guid })
          $verified = ($after.Count -eq $before.Count + $stubs.Count) -and
            (@($stubs | Where-Object { -not $afterByGuid.ContainsKey($_.Guid) }).Count -eq 0) -and
            (@($showGuids | Where-Object { -not $afterByGuid.ContainsKey($_) -or $afterByGuid[$_].hidden -ne $false }).Count -eq 0) -and
            (@($before | Where-Object {
                  $key = ConvertTo-GuidKey ([string]$_.guid)
                  $key -and ($showGuids -notcontains $key) -and
                    (-not $afterByGuid.ContainsKey($key) -or (($afterByGuid[$key] | ConvertTo-Json -Depth 20 -Compress) -ne ($_ | ConvertTo-Json -Depth 20 -Compress)))
                }).Count -eq 0)
        } catch { $verified = $false }
      }
      if (-not $verified) {
        $manual = @($stubs | ForEach-Object { "add $($_.Name) $($_.Guid)" }) + @($toShow | ForEach-Object { "set `"hidden`": false on $($_.Name) $($_.Guid)" })
        Write-Warning "[terminal] could not update $settingsFile safely; in profiles.list, by hand: $($manual -join '; ')"
      } else {
        Copy-Item -LiteralPath $settingsFile -Destination "$settingsFile.dotfiles.bak" -Force
        # Written in place, not staged and moved: settings.json is usually a
        # symlink into this repo, and a move would replace the link with a copy.
        # WriteAllText rather than Set-Content because Windows PowerShell's
        # -Encoding UTF8 always emits a BOM.
        [System.IO.File]::WriteAllText($settingsFile, $updated, (New-Object System.Text.UTF8Encoding($hasBom)))
        $listed += @($stubs | ForEach-Object { $_.Guid })
        if ($stubs.Count) {
          Write-Host "[terminal] listed $($stubs.Count) profile(s) in ${settingsFile}: $(@($stubs | ForEach-Object { $_.Name }) -join ', ')"
        }
        if ($toShow.Count) {
          Write-Host "[terminal] un-hid $($toShow.Count) Visual Studio profile(s) in ${settingsFile}: $(@($toShow | ForEach-Object { $_.Name }) -join ', ')"
        }
      }
    }
  }

  # --- 3. Remembered profiles that are still unlisted -------------------------
  if (-not (Test-Path -LiteralPath $stateFile)) { continue }
  try { $state = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch {
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
  # and Visual Studio profiles are already safe via steps 1-2; this only
  # affects other dynamic ones.
  Write-Warning '[terminal] Windows Terminal is running and will rewrite state.json, so other dynamic profiles (e.g. Azure Cloud Shell) may stay hidden. Close every Terminal window, re-run catalog\terminal-profiles\script.ps1, then start Terminal again.'
} else {
  Write-Host '[terminal] start Windows Terminal to pick the profiles back up.'
}
