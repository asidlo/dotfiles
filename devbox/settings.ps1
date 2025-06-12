$ErrorActionPreference = "Stop"

$IsUserAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

if (-not($IsUserAdmin)) {
    Write-Error "You need to run this script as an admin user." -Category AuthenticationError
    exit 1
}

# (Never notify) Change user account settings to not prompt for admin
Set-ItemProperty `
    -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
    -Name EnableLUA `
    -Value 1
Set-ItemProperty `
    -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
    -Name PromptOnSecureDesktop `
    -Value 0
Set-ItemProperty `
    -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System `
    -Name ConsentPromptBehaviorAdmin `
    -Value 0

# Enable developer settings and powershell scripts
Set-ItemProperty `
    -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock `
    -Name AllowDevelopmentWithoutDevLicense `
    -Value 1

# Remove Taskview
Set-ItemProperty `
    -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name ShowTaskViewButton `
    -Value 0 `
    -Type Dword `
    -Force

# Pin / Unpin apps from start and taskbar
# &"$PSScriptRoot\UnpinAllTaskbarItems.bat"
$taskbarAppPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
if (Test-Path -Path $taskbarAppPath -PathType Container) {
    Remove-Item -Recurse -Force -Path $taskbarAppPath
}
$taskbandRegEntry = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
if (Test-Path -Path $taskbandRegEntry -PathType Container) {
    Remove-Item -Recurse -Force -Path $taskbandRegEntry
}

# Remove all desktop icons except Recycle Bin (safer, only removes .lnk files)
$publicDesktop = "$env:PUBLIC\Desktop"
if (Test-Path $publicDesktop) {
    Get-ChildItem -Path $publicDesktop -Filter *.lnk | Remove-Item -Force
}
$oneDriveDesktopPath = "$env:USERPROFILE\OneDrive - Microsoft\Desktop"
if (Test-Path $oneDriveDesktopPath) {
    Get-ChildItem -Path $oneDriveDesktopPath -Filter *.lnk | Remove-Item -Force
}

# Left align taskbar (0 left; 1 center)
Set-ItemProperty `
    -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name TaskbarAl `
    -Value 0 `
    -Type Dword `
    -Force

# Set to dark theme
Set-ItemProperty `
    -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize `
    -Name AppsUseLightTheme  `
    -Value 0 `
    -Type Dword `
    -Force
Set-ItemProperty `
    -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize `
    -Name SystemUsesLightTheme `
    -Value 0 `
    -Type Dword `
    -Force

# Set background to black color (robust method)
Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name Background -Value '0 0 0' -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value '' -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value 0 -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value 0 -Force
# Force refresh of desktop to apply background
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters ,1 ,True

# Remove search and weather 
# 0 – Shows icon and text
# 1 – Show only icon
# 2 – Hide News and Interests)
# Set-ItemProperty `
#     -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds `
#     -Name ShellFeedsTaskbarViewMode  `
#     -Value 2 `
#     -Type Dword `
#     -Force
Set-ItemProperty `
    -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search `
    -Name SearchBoxTaskbarMode  `
    -Value 0 `
    -Type Dword `
    -Force

# Remove chat
Set-ItemProperty `
    -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name TaskbarMn `
    -Value 0 `
    -Force

# Remove widgets
# Attempt to disable Widgets via Group Policy registry (requires admin)
try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Dsh" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Force
} catch {
    Write-Warning "Could not set Group Policy registry to disable Widgets. You may need to do this manually or via Group Policy Editor."
}

# Optionally, try to remove the Widgets appx package (may not be available on all builds)
try {
    Get-AppxPackage -Name "MicrosoftWindows.Client.WebExperience" | Remove-AppxPackage -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Could not remove Widgets Appx package."
}

# Set more pins
# Default StartMenu pins layout 0=Default, 1=More Pins, 2=More Recommendations (requires Windows 11 22H2)
Set-ItemProperty `
    -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name Start_Layout `
    -Value 1 `
    -Force

# Set Windows Terminal as the default terminal (Windows 11 22H2+)
try {
    $terminalAppPath = "C:\\Program Files\\WindowsApps\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\WindowsTerminal.exe"
    if (Test-Path $terminalAppPath) {
        $regPath = "HKCU:\\Console\\%%Startup"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name DelegationConsole -Value "WindowsTerminal"
    }
} catch {
    Write-Warning "Could not set Windows Terminal as default terminal."
}

# Change explorer view to list for default and group by none (improved, more robust)
$FT = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes'
Get-ChildItem $FT -Recurse |
    Where-Object Property -Contains 'LogicalViewMode' |
    ForEach-Object {
        $folderType = $_.PSChildName
        $shellPath = "HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\Shell\$folderType"
        if (-not (Test-Path $shellPath)) {
            New-Item $shellPath -Force | Out-Null
        }
        Set-ItemProperty -Path $shellPath -Name 'Mode' -Value 3 -Force
        Set-ItemProperty -Path $shellPath -Name 'LogicalViewMode' -Value 1 -Force
    }

# Remove old explorer folder view settings (fix path type check)
$bagPaths = @(
    'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU',
    'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'
)
foreach ($path in $bagPaths) {
    if (Test-Path -Path $path) {
        Remove-Item -Recurse -Force $path
    }
}

# 0 = Show open windows and all tabs in Microsoft Edge
# 1 = Show Open windows and 5 most recent tabs in Microsoft Edge
# 2 = Show Open windows and 3 most recent Edge tabs
# 3 = Disable alt+tab
# Disable multitasking (Alt+Tab shows only open windows, disables Edge tabs)
Set-ItemProperty `
    -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name MultiTaskingAltTabFilter `
    -Value 3 `
    -Force
# Also disable Task Switcher cloud suggestions (optional, for privacy)
Set-ItemProperty `
    -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name CloudClipboard `
    -Value 0 `
    -Force

# Remove all Start Menu pins (Windows 11 22H2+)
try {
    $startMenuPath = "$env:APPDATA\Microsoft\Windows\StartMenu\Programs"
    if (Test-Path $startMenuPath) {
        Get-ChildItem -Path $startMenuPath -Recurse -Include *.lnk | Remove-Item -Force
    }
    # Remove all Start Menu pins for current user (requires Windows 11 22H2+)
    $startMenuLayout = "$env:USERPROFILE\blankStart.xml"
    if (-not (Test-Path $startMenuLayout)) {
        # Export a blank layout if not present (user should manually unpin all first for true blank)
        Export-StartLayout -Path $startMenuLayout
    }
    Import-StartLayout -LayoutPath $startMenuLayout -MountPath $env:SystemDrive\
} catch {
    Write-Warning "Could not remove all Start Menu pins automatically. For a truly blank Start Menu, manually unpin all tiles and re-run this script."
}

# Show file extensions and hidden files by default
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name Hidden -Value 1

# Step 4: Performance & Privacy Tweaks
# Disable Cortana
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0 -Force
# Disable Windows tips and suggestions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0 -Force
# Disable feedback requests (create key if missing)
$siufPath = 'HKCU:\Software\Microsoft\Siuf\Rules'
if (-not (Test-Path $siufPath)) {
    New-Item -Path $siufPath -Force | Out-Null
}
Set-ItemProperty -Path $siufPath -Name 'NumberOfSIUFInPeriod' -Value 0 -Force
Set-ItemProperty -Path $siufPath -Name 'PeriodInNanoSeconds' -Value 0 -Force

# Step 6: Clipboard & Snipping
# Enable clipboard history (already set above, but ensure it's present)
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -Name EnableClipboardHistory -Value 1 -Force

# Add additional clocks: UTC and Mumbai (India Standard Time)
# This sets up additional clocks in the Windows taskbar clock flyout
# Note: Normally requires logoff/logon, but we can try to force a refresh
$intlPath = 'HKCU:\Control Panel\International\User Profile'
$tzPath = 'HKCU:\Control Panel\International\User Profile\TimeZones'
if (-not (Test-Path $tzPath)) {
    New-Item -Path $tzPath -Force | Out-Null
}
# Set first additional clock: UTC
Set-ItemProperty -Path $intlPath -Name 'AddClock1' -Value 1 -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock1DisplayName' -Value 'UTC' -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock1TimeZoneKeyName' -Value 'UTC' -Force
# Set second additional clock: Mumbai (India Standard Time)
Set-ItemProperty -Path $intlPath -Name 'AddClock2' -Value 1 -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock2DisplayName' -Value 'Mumbai' -Force
Set-ItemProperty -Path $intlPath -Name 'AddClock2TimeZoneKeyName' -Value 'India Standard Time' -Force

Write-Host "Additional clocks for UTC and Mumbai have been configured. Please log off and log back in to see them in the taskbar clock flyout."

# Restart explorer to try and simulate a logout/login for settings to take effect
Get-Process -Name Explorer | Stop-Process -Force