$IsUserAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

if (-not($IsUserAdmin)) {
    Write-Error "You need to run this script as an admin user." -Category AuthenticationError
}

# https://learn.microsoft.com/en-us/windows/configuration/customize-taskbar-windows-11

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

Get-Process -Name Explorer | Stop-Process -Force

# Remove all desktop icons except trashbin
$shortcuts = Get-ChildItem -Path $env:PUBLIC\Desktop
foreach ($shortcut in $shortcuts) {
    Remove-Item -Path $shortcut
}
# $oneDriveDesktopPath = "$env:USERPROFILE\OneDrive - Microsoft\Desktop"
# if (Test-Path -Path $oneDriveDesktopPath -PathType Container) {
#     $shortcuts = Get-ChildItem -Recurse -Path $oneDriveDesktopPath
#     foreach ($shortcut in $shortcuts) {
#         Remove-Item -Recurse -Force -Path $shortcut
#     }
# }

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

# Set background to black color
Set-ItemProperty `
    -Path "HKCU:\Control Panel\Colors" `
    -Name Background `
    -Value '0 0 0' `
    -Force
Set-ItemProperty `
    -Path "HKCU:\Control Panel\Desktop" `
    -Name Wallpaper `
    -Value '' `
    -Force
add-type -typedefinition "using System;`n using System.Runtime.InteropServices;`n public class PInvoke { [DllImport(`"user32.dll`")] public static extern bool SetSysColors(int cElements, int[] lpaElements, int[] lpaRgbValues); }"
[PInvoke]::SetSysColors(1, @(1), @(0x0))

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
Set-ItemProperty `
    -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name TaskbarDa `
    -Value 0 `
    -Force

# Set more pins
# Default StartMenu pins layout 0=Default, 1=More Pins, 2=More Recommendations (requires Windows 11 22H2)
Set-ItemProperty `
    -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced `
    -Name Start_Layout `
    -Value 1 `
    -Force

# Disable show lock screen on login and remove apps from lock screen

# Change explorer view to list for default and group by none
$FT = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderTypes'
Get-ChildItem $FT -Recurse `
| Where-Object Property -Contains 'LogicalVIewMode' `
| ForEach-Object {
    $_.Name -match 'FolderTypes\\(.+)\\TopViews' | out-null
    $matches[1]
} `
| Select-Object -unique `
| ForEach-Object {
    New-Item "HKLM:\SOFTWARE\Microsoft\Windows\Shell\Bags\AllFolders\Shell\$_" -force `
    | Set-ItemProperty -Name 'Mode' -Value 3 -PassThru `
    | Set-ItemProperty -Name 'LogicalViewMode' -Value 1
}

$bagPaths = @(
    'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU',
    'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags'
)
foreach ($path in $bagPaths) {
    if (Test-Path -Path $path -PathType Leaf) {
        Remove-Item -Recurse -Force $path
    }
}