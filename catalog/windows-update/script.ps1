<#
  Installs the updates Windows Update would install on its own (security,
  quality, driver and definition updates; optional and preview updates are
  left out), plus the feature update Settings offers with "Download & install"
  (e.g. "Windows 11, version 26H2"), through the Windows Update Agent API, one
  update at a time so each gets its own result. Needs an elevated session,
  except with -ListOnly.

  Windows 11's own update orchestrator installs OS and feature updates from
  the "DCat Flighting Prod" service, so that is searched as well as the default
  Microsoft Update service. Settings' "Download & install" offers are optional
  installations, which a search for regular updates never returns, so those get
  a search of their own. The feature update is installed last.

  One pass: some updates are only offered after the restart the previous
  round asks for, and a feature update can refuse to install while a restart
  is pending, so re-run after restarting to pick those up.
#>
param(
  # Windows Update Agent search criteria. Settings' "Optional updates" (previews,
  # optional drivers) are DeploymentAction='OptionalInstallation' or BrowseOnly=1.
  [string]$Criteria = 'IsInstalled=0 and IsHidden=0 and BrowseOnly=0',
  # Leave out the feature update Settings offers with "Download & install".
  [switch]$SkipFeatureUpdate,
  # Only list what would be installed. Needs no elevation.
  [switch]$ListOnly
)
$ErrorActionPreference = 'Stop'

# The service Windows 11's own update orchestrator installs OS updates from.
$dcatServiceId = '8b24b027-1dee-babb-9a95-3517dfb9c552'
$upgradesCategoryId = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5'
$driversCategoryId = 'ebfc1fc5-71a4-4f7b-9aca-3b9a503104a0'
# "Download & install" offers are optional installations, which $Criteria
# (implicitly DeploymentAction='Installation') never returns.
$offerCriteria = "IsInstalled=0 and IsHidden=0 and DeploymentAction='OptionalInstallation' or IsInstalled=0 and IsHidden=0 and BrowseOnly=1"

$hresultHints = @{
  '0x80070005' = 'access denied; run from an elevated session'
  '0x80070422' = 'the Windows Update service (wuauserv) is disabled'
  '0x80240016' = 'another Windows Update install is running or a restart is pending; restart, then retry'
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

function Get-CategoryIds($Update) {
  @(foreach ($category in $Update.Categories) { ([string]$category.CategoryID).ToLowerInvariant() })
}

function Test-FeatureUpdate($Update) {
  (Get-CategoryIds $Update) -contains $upgradesCategoryId -or
    [string]$Update.Title -match '^(Feature update to Windows 1\d\b|Windows 1\d, version \w+)'
}

# DCat labels its drivers Software (Type 1), so the category is what marks them.
function Test-DriverUpdate($Update) {
  [int]$Update.Type -eq 2 -or (Get-CategoryIds $Update) -contains $driversCategoryId
}

# Group Policy, or its MDM (Intune) equivalent.
function Test-DriversExcluded {
  foreach ($key in 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate', 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Update') {
    $policy = Get-ItemProperty -LiteralPath $key -Name 'ExcludeWUDriversInQualityUpdate' -ErrorAction SilentlyContinue
    if ($policy -and [int]$policy.ExcludeWUDriversInQualityUpdate -eq 1) { return $true }
  }
  $false
}

function Test-RestartPending {
  try { [bool](New-Object -ComObject Microsoft.Update.SystemInfo).RebootRequired } catch { $false }
}

function Search-Updates($Session, [string]$SearchCriteria, [string]$ServiceId) {
  $searcher = $Session.CreateUpdateSearcher()
  if ($ServiceId) {
    $searcher.ServerSelection = 3  # ssOthers: the service named by ServiceID
    $searcher.ServiceID = $ServiceId
  }
  $found = $searcher.Search($SearchCriteria)
  @(foreach ($u in $found.Updates) { $u })
}

$candidates = [System.Collections.Generic.List[object]]::new()
$seenIds = @{}
$seenKbs = @{}
function Add-Candidate($Update, [string]$Source, [bool]$Feature) {
  $id = [string]$Update.Identity.UpdateID
  if ($id -and $seenIds.ContainsKey($id)) { return }
  # Both services can carry the same KB under different update IDs.
  $kbs = @(foreach ($kb in $Update.KBArticleIDs) { [string]$kb })
  foreach ($kb in $kbs) { if ($seenKbs.ContainsKey($kb) -and $seenKbs[$kb] -ne $Source) { return } }
  if ($id) { $seenIds[$id] = $true }
  foreach ($kb in $kbs) { if (-not $seenKbs.ContainsKey($kb)) { $seenKbs[$kb] = $Source } }
  $candidates.Add([pscustomobject]@{
      Update  = $Update
      Title   = [string]$Update.Title
      Source  = $Source
      Feature = $Feature
      Driver  = (Test-DriverUpdate $Update)
      KB      = @($kbs | ForEach-Object { "KB$_" }) -join ', '
      SizeMB  = [int][math]::Round([double]$Update.MaxDownloadSize / 1MB)
    })
}

$session = New-Object -ComObject Microsoft.Update.Session
$session.ClientApplicationID = 'dotfiles windows-update'

$sources = @([pscustomobject]@{ Name = 'Microsoft Update'; ServiceId = '' })
$dcatRegistered = $false
try {
  foreach ($service in (New-Object -ComObject Microsoft.Update.ServiceManager).Services) {
    $isDcat = [string]$service.ServiceID -eq $dcatServiceId
    if ($service.IsDefaultAUService) { $sources[0].Name = [string]$service.Name }
    if ($isDcat) { $dcatRegistered = $true }
    if ($isDcat -and -not $service.IsDefaultAUService) {
      $sources += [pscustomobject]@{ Name = [string]$service.Name; ServiceId = $dcatServiceId }
    }
  }
} catch { }
if (-not $dcatRegistered) {
  Write-Host "[wu] the Windows 11 OS update service ($dcatServiceId) isn't registered; searching $($sources[0].Name) only"
}

foreach ($source in $sources) {
  Write-Host "[wu] searching $($source.Name) ($Criteria)"
  try { $found = Search-Updates $session $Criteria $source.ServiceId } catch {
    $e = Get-InnermostException $_
    $message = "[wu] searching $($source.Name) failed ($(Get-HResultText $e.HResult)): $($e.Message)"
    if (-not $source.ServiceId) { throw $message }
    Write-Error -ErrorAction Continue $message
    continue
  }
  foreach ($u in $found) { Add-Candidate $u $source.Name (Test-FeatureUpdate $u) }
}

if (-not $SkipFeatureUpdate) {
  # DCat when it is registered; the default service otherwise.
  $offerSource = $sources[-1]
  Write-Host "[wu] searching $($offerSource.Name) for a feature update offer"
  try {
    foreach ($u in (Search-Updates $session $offerCriteria $offerSource.ServiceId)) {
      if (Test-FeatureUpdate $u) { Add-Candidate $u $offerSource.Name $true }
    }
  } catch {
    $e = Get-InnermostException $_
    Write-Error -ErrorAction Continue "[wu] searching for a feature update failed ($(Get-HResultText $e.HResult)): $($e.Message)"
  }
}

$excludeDrivers = Test-DriversExcluded
$drivers = @($candidates | Where-Object { $excludeDrivers -and $_.Driver -and -not $_.Feature })
if ($drivers.Count) {
  Write-Host "[wu] leaving out $($drivers.Count) driver update(s): policy ExcludeWUDriversInQualityUpdate is set"
}
$selected = @($candidates | Where-Object {
    -not ($excludeDrivers -and $_.Driver -and -not $_.Feature) -and -not ($SkipFeatureUpdate -and $_.Feature)
  })

# The feature update last, so a failure there can't hold back the rest.
$updates = @($selected | Where-Object { -not $_.Feature }) + @($selected | Where-Object { $_.Feature })
$restartPendingAtStart = Test-RestartPending

if ($ListOnly) {
  if ($updates.Count) {
    $updates | Select-Object Title,
      @{ Name = 'Kind'; Expression = { if ($_.Feature) { 'feature update' } elseif ($_.Driver) { 'driver' } else { 'update' } } },
      Source, KB, @{ Name = 'MB'; Expression = { $_.SizeMB } } |
      Format-Table -AutoSize -Wrap | Out-String -Width 200 | Write-Host
  } else {
    Write-Host '[wu] no updates to install'
  }
  if ($restartPendingAtStart) { Write-Host '[wu] a restart is pending from an earlier install' }
  Write-Host '[wu] -ListOnly: nothing was installed'
  $global:LASTEXITCODE = 0
  return
}

if (-not $updates.Count) {
  Write-Host '[wu] no updates to install'
} else {
  Write-Host "[wu] $($updates.Count) update(s) to install"
}

$results = [System.Collections.Generic.List[object]]::new()
$i = 0
foreach ($candidate in $updates) {
  $i++
  $u = $candidate.Update
  $tag = "[wu] ($i/$($updates.Count))"
  $entry = [pscustomobject]@{ Title = $candidate.Title; Result = ''; Detail = ''; RebootRequired = $false }
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
      }
    }

    if ($entry.Result -ne 'Failed') {
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
    }
  } catch {
    $e = Get-InnermostException $_
    $entry.Result = 'Failed'
    $entry.Detail = "$(Get-HResultText $e.HResult): $($e.Message)"
  }
  # A feature update commonly waits for the restart the updates before it
  # asked for; that is the next run's job, not a failure.
  if ($candidate.Feature -and $entry.Result -eq 'Failed' -and
      ($restartPendingAtStart -or @($results | Where-Object { $_.RebootRequired }).Count -or (Test-RestartPending))) {
    $entry.Result = 'Deferred'
    $entry.Detail = @(@($entry.Detail, 'a restart is pending, so run this again after restarting') | Where-Object { $_ }) -join '; '
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
$deferred = @($results | Where-Object { $_.Result -eq 'Deferred' })
if ($deferred.Count) {
  Write-Error -ErrorAction Continue "[wu] left for after the restart: $($deferred.Title -join '; '); run catalog\windows-update\script.ps1 again once restarted"
}

if ((Test-RestartPending) -or ($results | Where-Object { $_.RebootRequired })) {
  Write-Host '[wu] a restart is required to finish installing updates'
}

$failed = @($results | Where-Object { $_.Result -eq 'Failed' })
if ($failed.Count) {
  throw "[wu] $($failed.Count) update(s) failed: $(@($failed | ForEach-Object { "$($_.Title) ($($_.Detail))" }) -join '; ')"
}
$global:LASTEXITCODE = 0
