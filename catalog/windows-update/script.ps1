<#
  Installs the updates Windows Update would install on its own (security,
  quality, driver and definition updates; optional and preview updates are
  left out) through the Windows Update Agent API, one update at a time so each
  gets its own result. Needs an elevated session.

  One pass: some updates are only offered after the restart the previous
  round asks for, so re-run after restarting to pick those up.
#>
param(
  # Windows Update Agent search criteria. BrowseOnly=1 would add the optional
  # updates Settings lists under "Optional updates".
  [string]$Criteria = 'IsInstalled=0 and IsHidden=0 and BrowseOnly=0'
)
$ErrorActionPreference = 'Stop'

$hresultHints = @{
  '0x80070005' = 'access denied; run from an elevated session'
  '0x80070422' = 'the Windows Update service (wuauserv) is disabled'
  '0x80240016' = 'another Windows Update install is already running; retry once it finishes'
  '0x8024402C' = 'could not reach Windows Update; check the network or proxy'
  '0x80072EE7' = 'could not reach Windows Update; check the network or proxy'
}

function Format-HResult([int]$HResult) { '0x{0:X8}' -f $HResult }

function Get-HResultText([int]$HResult) {
  $hex = Format-HResult $HResult
  if ($hresultHints.ContainsKey($hex)) { return "$hex, $($hresultHints[$hex])" }
  $hex
}

# COM failures surface wrapped in a MethodInvocationException.
function Get-InnermostException($ErrorRecord) {
  $e = $ErrorRecord.Exception
  while ($e.InnerException) { $e = $e.InnerException }
  $e
}

$session = New-Object -ComObject Microsoft.Update.Session
$session.ClientApplicationID = 'dotfiles windows-update'

Write-Host "[wu] searching for updates ($Criteria)"
try {
  $search = $session.CreateUpdateSearcher().Search($Criteria)
} catch {
  $e = Get-InnermostException $_
  throw "[wu] Windows Update search failed ($(Get-HResultText $e.HResult)): $($e.Message)"
}

$updates = @(foreach ($u in $search.Updates) { $u })
if (-not $updates.Count) {
  Write-Host '[wu] no updates to install'
} else {
  Write-Host "[wu] $($updates.Count) update(s) to install"
}

$results = [System.Collections.Generic.List[object]]::new()
$i = 0
foreach ($u in $updates) {
  $i++
  $tag = "[wu] ($i/$($updates.Count))"
  $entry = [pscustomobject]@{ Title = [string]$u.Title; Result = ''; Detail = ''; RebootRequired = $false }
  $results.Add($entry)

  if ($u.InstallationBehavior.CanRequestUserInput) {
    $entry.Result = 'Needs input'
    Write-Host "$tag skipping $($entry.Title): it can prompt for input"
    continue
  }

  try {
    if (-not $u.EulaAccepted) { $u.AcceptEula() }
    $batch = New-Object -ComObject Microsoft.Update.UpdateColl
    [void]$batch.Add($u)

    if (-not $u.IsDownloaded) {
      Write-Host ("$tag downloading $($entry.Title) (up to {0:N0} MB)" -f ([double]$u.MaxDownloadSize / 1MB))
      $downloader = $session.CreateUpdateDownloader()
      $downloader.Updates = $batch
      $download = $downloader.Download()
      # 2 = succeeded, 3 = succeeded with errors
      if ($download.ResultCode -ne 2 -and $download.ResultCode -ne 3) {
        $entry.Result = 'Failed'
        $entry.Detail = "download result $($download.ResultCode) ($(Get-HResultText $download.HResult))"
        Write-Host "$tag download failed: $($entry.Detail)"
        continue
      }
    }

    Write-Host "$tag installing $($entry.Title)"
    $installer = $session.CreateUpdateInstaller()
    $installer.Updates = $batch
    try { $installer.ForceQuiet = $true } catch { }
    $outcome = $installer.Install().GetUpdateResult(0)
    $entry.RebootRequired = [bool]$outcome.RebootRequired
    switch ([int]$outcome.ResultCode) {
      2 { $entry.Result = 'Installed' }
      3 { $entry.Result = 'Installed with errors'; $entry.Detail = Get-HResultText $outcome.HResult }
      5 { $entry.Result = 'Failed'; $entry.Detail = "aborted ($(Get-HResultText $outcome.HResult))" }
      default { $entry.Result = 'Failed'; $entry.Detail = "result $($outcome.ResultCode) ($(Get-HResultText $outcome.HResult))" }
    }
  } catch {
    $e = Get-InnermostException $_
    $entry.Result = 'Failed'
    $entry.Detail = "$(Get-HResultText $e.HResult): $($e.Message)"
  }
  if ($entry.RebootRequired -and $entry.Result -ne 'Failed') { $entry.Result += '; restart pending' }
  Write-Host "$tag $($entry.Result)$(if ($entry.Detail) { ": $($entry.Detail)" })"
}

if ($results.Count) {
  $results | Select-Object Title, Result, Detail | Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Host
}

$needsInput = @($results | Where-Object { $_.Result -eq 'Needs input' })
if ($needsInput.Count) {
  Write-Error -ErrorAction Continue "[wu] $($needsInput.Count) update(s) can prompt for input, so they were left for Settings > Windows Update: $($needsInput.Title -join '; ')"
}
$withErrors = @($results | Where-Object { $_.Result -like 'Installed with errors*' })
if ($withErrors.Count) {
  Write-Error -ErrorAction Continue "[wu] installed with errors: $($withErrors.Title -join '; ')"
}

$rebootRequired = $false
try { $rebootRequired = [bool](New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired } catch { }
if ($rebootRequired -or ($results | Where-Object { $_.RebootRequired })) {
  Write-Host '[wu] a restart is required to finish installing updates'
}

$failed = @($results | Where-Object { $_.Result -eq 'Failed' })
if ($failed.Count) {
  throw "[wu] $($failed.Count) update(s) failed: $(@($failed | ForEach-Object { "$($_.Title) ($($_.Detail))" }) -join '; ')"
}
$global:LASTEXITCODE = 0
