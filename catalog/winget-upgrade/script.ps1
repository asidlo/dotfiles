<#
  Upgrades every package `winget upgrade` lists, one at a time rather than with
  `winget upgrade --all`, so each gets its own result and a package hosting this
  script can be held back. Packages that need explicit targeting, are pinned, or
  have an unknown installed version are left alone, as `--all` would leave them.
#>
param(
  # Package ids to leave alone, on top of the ones held back automatically.
  [string[]]$Exclude
)
$ErrorActionPreference = 'Stop'

# Upgrading one of these closes it, and with it the console running this script.
$hostPackages = @{
  'pwsh.exe'            = @('Microsoft.PowerShell', 'Microsoft.PowerShell.Preview')
  'windowsterminal.exe' = @('Microsoft.WindowsTerminal', 'Microsoft.WindowsTerminal.Preview')
  'code.exe'            = @('Microsoft.VisualStudioCode')
  'code - insiders.exe' = @('Microsoft.VisualStudioCode.Insiders')
}

function Get-AncestorProcessNames {
  $byId = @{}
  foreach ($p in @(Get-CimInstance Win32_Process -Property ProcessId, ParentProcessId, Name -ErrorAction SilentlyContinue)) {
    $byId[[int]$p.ProcessId] = $p
  }
  $id = $PID
  $seen = @{}
  while ($byId.ContainsKey($id) -and -not $seen.ContainsKey($id)) {
    $seen[$id] = $true
    $byId[$id].Name.ToLowerInvariant()
    $id = [int]$byId[$id].ParentProcessId
  }
}

function Invoke-Winget([string[]]$Arguments) {
  # Function-local: Windows PowerShell turns native stderr into a terminating
  # error under 'Stop'.
  $ErrorActionPreference = 'Continue'
  $output = @(& winget @Arguments 2>&1 | ForEach-Object { "$_" })
  [pscustomobject]@{ Exit = $LASTEXITCODE; Output = $output }
}

<#
  Reads the table of upgrades `winget upgrade` prints. That table is the one
  closed by the "N upgrades available." line. Any other table (packages that
  need explicit targeting, pinned packages) is skipped, because `--all` skips
  them too. When nothing else is upgradable, the explicit-targeting table is
  the only one printed, so "first table" would be wrong. Rows are read from the
  right: Ids never contain spaces, but names do, and so can versions
  ("< 17.14.39"). The Source column only appears when more than one source is
  configured.

  Recognized is $false when a table was printed but none could be identified as
  the upgrade list (e.g. a non-English winget), so the caller can say so rather
  than report everything as up to date.
#>
function ConvertFrom-WingetUpgradeList([string[]]$Lines) {
  $packages = @()
  $unparsed = @()
  $found = $false
  $sawTable = $false
  $noneInstalled = $false
  $header = $null
  $inTable = $false
  $hasSource = $false
  $rows = $null
  $bad = $null

  foreach ($raw in $Lines) {
    # winget redraws its spinner with CRs; keep what a console would show.
    $line = ("$raw" -split "`r")[-1].TrimEnd()
    if ($line -match 'No installed package found matching input criteria') { $noneInstalled = $true }
    if (-not $inTable) {
      if ($header -and $line -match '^-{10,}$') {
        $hasSource = (@($header.Trim() -split '\s+').Count -ge 5)
        $inTable = $true
        $sawTable = $true
        $rows = [System.Collections.Generic.List[object]]::new()
        $bad = [System.Collections.Generic.List[string]]::new()
      } else {
        $header = $line
      }
      continue
    }
    if ($line -match '^\d+\s+upgrades?\s+available') {
      $packages = $rows.ToArray()
      $unparsed = $bad.ToArray()
      $found = $true
      break
    }
    if (-not $line.Trim()) { $inTable = $false; $header = $null; continue }
    if ($line.TrimStart().StartsWith('<')) { continue }

    $t = @($line.Trim() -split '\s+')
    $i = $t.Count - 1
    $source = $null
    if ($hasSource) { $source = $t[$i]; $i-- }
    if ($i -lt 3) { $bad.Add($line); continue }
    $available = $t[$i]; $i--
    $version = $t[$i]; $i--
    if ($i -ge 2 -and ($t[$i] -eq '<' -or $t[$i] -eq '>')) { $version = "$($t[$i]) $version"; $i-- }
    $id = $t[$i]; $i--
    # A truncated Id ends in an ellipsis; only whole, printable-ASCII Ids are trusted.
    if ($i -lt 0 -or $id -notmatch '^[\x21-\x7E]+$') { $bad.Add($line); continue }
    $rows.Add([pscustomobject]@{
        Name      = ($t[0..$i] -join ' ')
        Id        = $id
        Version   = $version
        Available = $available
        Source    = $source
      })
  }
  [pscustomobject]@{
    Packages   = $packages
    Unparsed   = $unparsed
    Recognized = ($found -or $noneInstalled -or -not $sawTable)
  }
}

function Get-UpgradeResult([int]$ExitCode) {
  switch ($ExitCode) {
    0 { 'Upgraded' }
    1641 { 'Upgraded; restart pending' }
    3010 { 'Upgraded; restart pending' }
    -1978334967 { 'Upgraded; restart pending' }  # 0x8A150109 INSTALL_REBOOT_REQUIRED_TO_FINISH
    -1978334965 { 'Upgraded; restart pending' }  # 0x8A15010B INSTALL_REBOOT_INITIATED
    -1978334966 { 'Retry after restart' }        # 0x8A15010A INSTALL_REBOOT_REQUIRED_FOR_INSTALL
    -1978335189 { 'Not applicable' }             # 0x8A15002B UPDATE_NOT_APPLICABLE
    -1978335153 { 'Not applicable' }             # 0x8A15004F UPGRADE_VERSION_NOT_NEWER
    -1978335128 { 'Pinned' }                     # 0x8A150068 PACKAGE_IS_PINNED
    -1978335090 { 'Needs reinstall' }            # 0x8A15008E UPDATE_INSTALL_TECHNOLOGY_MISMATCH
    default { 'Failed' }
  }
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw '[winget] winget not found on PATH'
}

# winget writes UTF-8; Windows PowerShell would otherwise decode it with the OEM
# code page and mangle any non-ASCII name. There is no console under some hosts.
$previousEncoding = $null
try { $previousEncoding = [Console]::OutputEncoding; [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
try {
  Write-Host '[winget] checking for upgrades'
  $list = Invoke-Winget @('upgrade', '--accept-source-agreements', '--disable-interactivity')
  $parsed = ConvertFrom-WingetUpgradeList $list.Output
  if ($list.Exit -ne 0 -and -not $parsed.Packages.Count) {
    $tail = @($list.Output | Select-Object -Last 15) -join "`n"
    throw "[winget] 'winget upgrade' failed (exit $($list.Exit)).`n$tail"
  }
  foreach ($line in $parsed.Unparsed) {
    Write-Error -ErrorAction Continue "[winget] could not read this 'winget upgrade' row, so it was not upgraded: $($line.Trim())"
  }
  if (-not $parsed.Recognized) {
    Write-Error -ErrorAction Continue "[winget] could not find the list of upgrades in the 'winget upgrade' output, so nothing was upgraded; run 'winget upgrade' to check."
  }

  $held = @{}
  foreach ($id in @($Exclude | Where-Object { $_ })) { $held[$id] = @{ Reason = 'excluded by -Exclude'; Warn = $false } }
  $hostNames = @(Get-AncestorProcessNames)
  if ($env:WT_SESSION) { $hostNames += 'windowsterminal.exe' }
  foreach ($name in $hostNames) {
    foreach ($id in @($hostPackages[$name])) {
      if ($id -and -not $held.ContainsKey($id)) { $held[$id] = @{ Reason = "hosts this script ($name)"; Warn = $true } }
    }
  }
  if (-not $held.ContainsKey('Microsoft.AppInstaller')) {
    $held['Microsoft.AppInstaller'] = @{ Reason = 'is winget itself; the Microsoft Store updates it'; Warn = $false }
  }

  $seen = @{}
  $pending = @($parsed.Packages | Where-Object {
      $key = "$($_.Id)|$($_.Source)"
      if ($seen.ContainsKey($key)) { $false } else { $seen[$key] = $true; $true }
    })
  $toUpgrade = @($pending | Where-Object { -not $held.ContainsKey($_.Id) })
  if (-not $pending.Count) {
    Write-Host '[winget] every package is up to date'
  } else {
    Write-Host "[winget] $($pending.Count) upgrade(s) available; upgrading $($toUpgrade.Count)"
  }

  $results = [System.Collections.Generic.List[object]]::new()
  $n = 0
  foreach ($pkg in $pending) {
    $entry = [pscustomobject]@{ Package = $pkg.Id; From = $pkg.Version; To = $pkg.Available; Result = ''; Exit = 0; Note = ''; Output = @() }
    if ($held.ContainsKey($pkg.Id)) {
      $entry.Result = 'Held back'
      $entry.Note = $held[$pkg.Id].Reason
      Write-Host "[winget] holding back $($pkg.Id): $($entry.Note)"
      $results.Add($entry)
      continue
    }
    $n++
    Write-Host "[winget] ($n/$($toUpgrade.Count)) upgrading $($pkg.Id) $($pkg.Version) -> $($pkg.Available)"
    $upgradeArgs = @('upgrade', '--id', $pkg.Id, '--exact')
    if ($pkg.Source) { $upgradeArgs += @('--source', $pkg.Source) }
    $upgradeArgs += @('--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity', '--silent')
    $run = Invoke-Winget $upgradeArgs
    $entry.Exit = $run.Exit
    $entry.Output = $run.Output
    $entry.Result = Get-UpgradeResult $run.Exit
    $results.Add($entry)
  }
} finally {
  if ($previousEncoding) { try { [Console]::OutputEncoding = $previousEncoding } catch { } }
}

if ($results.Count) {
  $results | Select-Object Package, From, To, Result, Exit | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
}

$failed = @($results | Where-Object { $_.Result -eq 'Failed' })
foreach ($r in $failed) {
  $tail = @($r.Output | Select-Object -Last 15) -join "`n"
  $message = "[winget] $($r.Package) failed to upgrade (exit $($r.Exit))."
  if ($tail) { $message += "`n$tail" }
  Write-Warning $message
}

$heldWarn = @($results | Where-Object { $_.Result -eq 'Held back' -and $held[$_.Package].Warn })
if ($heldWarn.Count) {
  Write-Error -ErrorAction Continue ("[winget] held back $($heldWarn.Package -join ', ') because upgrading would close the console running this script. " +
    "Upgrade from a different shell: winget upgrade --id <id>")
}
$retry = @($results | Where-Object { $_.Result -eq 'Retry after restart' })
if ($retry.Count) {
  Write-Error -ErrorAction Continue "[winget] $($retry.Package -join ', ') can only upgrade after a restart; restart, then re-run."
}
$reinstall = @($results | Where-Object { $_.Result -eq 'Needs reinstall' })
if ($reinstall.Count) {
  Write-Error -ErrorAction Continue "[winget] $($reinstall.Package -join ', ') switched installer technology; uninstall and reinstall to upgrade."
}
$restartPending = @($results | Where-Object { $_.Result -eq 'Upgraded; restart pending' })
if ($restartPending.Count) { Write-Host "[winget] restart pending for: $($restartPending.Package -join ', ')" }
if ($failed.Count) { throw "[winget] $($failed.Count) package(s) failed to upgrade: $($failed.Package -join ', ')" }
$global:LASTEXITCODE = 0
