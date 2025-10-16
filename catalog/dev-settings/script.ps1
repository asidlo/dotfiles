param()
$ErrorActionPreference = 'Stop'
$IsUserAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544')
if (-not $IsUserAdmin) { Write-Error 'Run as admin.' -Category AuthenticationError; exit 1 }

# UAC & Developer Mode
Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 1
Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name PromptOnSecureDesktop -Value 0
Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
Set-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1

# Taskbar & desktop cleanup
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0 -Type Dword -Force
$taskbarAppPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"; if (Test-Path $taskbarAppPath) { Remove-Item -Recurse -Force $taskbarAppPath }
$taskbandRegEntry = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'; if (Test-Path $taskbandRegEntry) { Remove-Item -Recurse -Force $taskbandRegEntry }
$publicDesktop = "$env:PUBLIC\Desktop"; if (Test-Path $publicDesktop) { Get-ChildItem -Path $publicDesktop -Filter *.lnk | Remove-Item -Force }
$oneDriveDesktopPath = "$env:USERPROFILE\OneDrive - Microsoft\Desktop"; if (Test-Path $oneDriveDesktopPath) { Get-ChildItem -Path $oneDriveDesktopPath -Filter *.lnk | Remove-Item -Force }

# Theme & appearance
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarAl -Value 0 -Type Dword -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0 -Type Dword -Force
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0 -Type Dword -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Colors' -Name Background -Value '0 0 0' -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value '' -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value 0 -Force
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters ,1 ,True

# Taskbar elements
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchBoxTaskbarMode -Value 0 -Type Dword -Force
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name TaskbarMn -Value 0 -Force
try { New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft' -Name 'Dsh' -Force | Out-Null; Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Value 0 -Force } catch { Write-Warning 'Widgets policy not applied.' }
try { Get-AppxPackage -Name 'MicrosoftWindows.Client.WebExperience' | Remove-AppxPackage -ErrorAction SilentlyContinue } catch { Write-Warning 'Widgets Appx removal failed.' }
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name Start_Layout -Value 1 -Force

# Terminal default & explorer view
try { $terminalAppPath = 'C:\Program Files\WindowsApps\Microsoft.WindowsTerminal_8wekyb3d8bbwe\WindowsTerminal.exe'; if (Test-Path $terminalAppPath) { $regPath = 'HKCU:\Console\%%Startup'; if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }; Set-ItemProperty -Path $regPath -Name DelegationConsole -Value 'WindowsTerminal' } } catch { Write-Warning 'WT default failed.' }
$FT = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes'
Get-ChildItem $FT -Recurse | Where-Object Property -Contains 'LogicalViewMode' | ForEach-Object { $folderType = $_.PSChildName; $shellPath = "HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\Shell\$folderType"; if (-not (Test-Path $shellPath)) { New-Item $shellPath -Force | Out-Null }; Set-ItemProperty -Path $shellPath -Name Mode -Value 3 -Force; Set-ItemProperty -Path $shellPath -Name LogicalViewMode -Value 1 -Force }
$bagPaths = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU','HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'
foreach ($path in $bagPaths) { if (Test-Path $path) { Remove-Item -Recurse -Force $path } }

# Multitasking & file visibility
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name MultiTaskingAltTabFilter -Value 3 -Force
Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name CloudClipboard -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1

# Start menu & privacy
try { $startMenuPath = "$env:APPDATA\Microsoft\Windows\StartMenu\Programs"; if (Test-Path $startMenuPath) { Get-ChildItem -Path $startMenuPath -Recurse -Include *.lnk | Remove-Item -Force }; $startMenuLayout = "$env:USERPROFILE\blankStart.xml"; if (-not (Test-Path $startMenuLayout)) { Export-StartLayout -Path $startMenuLayout }; Import-StartLayout -LayoutPath $startMenuLayout -MountPath $env:SystemDrive\ } catch { Write-Warning 'Could not blank Start Menu.' }
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0 -Force
$siufPath = 'HKCU:\Software\Microsoft\Siuf\Rules'; if (-not (Test-Path $siufPath)) { New-Item -Path $siufPath -Force | Out-Null }; Set-ItemProperty -Path $siufPath -Name 'NumberOfSIUFInPeriod' -Value 0 -Force; Set-ItemProperty -Path $siufPath -Name 'PeriodInNanoSeconds' -Value 0 -Force

# Clipboard & clocks
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name EnableClipboardHistory -Value 1 -Force
$intlPath = 'HKCU:\Control Panel\International\User Profile'
$tzPath = 'HKCU:\Control Panel\International\User Profile\TimeZones'; if (-not (Test-Path $tzPath)) { New-Item -Path $tzPath -Force | Out-Null }
Set-ItemProperty -Path $intlPath -Name 'AddClock1' -Value 1 -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock1DisplayName' -Value 'UTC' -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock1TimeZoneKeyName' -Value 'UTC' -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock2' -Value 1 -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock2DisplayName' -Value 'Mumbai' -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock2TimeZoneKeyName' -Value 'India Standard Time' -Force
Write-Host 'Additional clocks configured.'

# Explorer restart
try { Get-Process -Name Explorer | Stop-Process -Force } catch { Write-Warning 'Explorer restart failed.' }
