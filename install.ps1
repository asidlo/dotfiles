<#
.SYNOPSIS
    Automatically setup user desktop.

.DESCRIPTION
    Installs packages and modifies user system settings to create a consistent
    dev environment across environments.

.PARAMETER Packages
    A file path corresponding to a list of json chocolately packages into install.

    [
        {
            "pkg": "git",
            "params": "/GitAndUnixToolsOnPath",
            "version": "",
            "install": true
        }
    ]

.LINK
    https://devbox.microsoft.com

.EXAMPLE
    MsftDevSetup.ps1 -Packages ./packages.json
#>
param(
    [string] $Packages = $null
)

$defaultPackages = @(
    @{pkg = "docker-desktop" },
    @{pkg = "sysinternals" },
    @{pkg = "office365business" },
    @{pkg = "nerd-fonts-meslo" },
    @{pkg = "neovim" },
    @{pkg = "fzf" },
    @{pkg = "starship" },
    @{
        pkg    = "vscode"
        params = "/NoDesktopIcon /NoQuicklaunchIcon"
    }
)

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
$oneDriveDesktopPath = "$env:USERPROFILE\OneDrive - Microsoft\Desktop"
if (Test-Path -Path $oneDriveDesktopPath -PathType Container) {
    $shortcuts = Get-ChildItem -Recurse -Path $oneDriveDesktopPath
    foreach ($shortcut in $shortcuts) {
        Remove-Item -Recurse -Force -Path $shortcut
    }
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

# Enable features for Containers, Hyper-V, Telnet, VirtualMachinePlatform, Windows Subsystem for Linux 
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:Containers /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart

# Install wsl
wsl --install -d Ubuntu
wsl --set-default Ubuntu

# Check if choco installed, if not install choco .exe and add choco to PATH
Get-Command choco -ErrorAction SilentlyContinue -ErrorVariable ChocoError | Out-Null
if ($ChocoError) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

if ([string]::IsNullOrEmpty($Packages)) {
    $pkgs = $defaultPackages
}
else {
    $pkgs = Get-Content -Raw -Path $Packages | ConvertFrom-Json
}

ForEach ($pkg in $pkgs) {
    if ($pkg.params) {
        if ($pkg.version) {
            choco install $pkg.pkg --params $pkg.params --version $pkg.version -y
        }
        else {
            choco install $pkg.pkg --params $pkg.params -y
        }
    }
    else {
        if ($pkg.version) {
            choco install $pkg.pkg --version $pkg.version -y
        }
        else {
            choco install $pkg.pkg -y
        }
    }
}

code --install-extension ms-vscode-remote.vscode-remote-extensionpack --force

# Terminal settings
$settingsPath = "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
New-Item -ItemType SymbolicLink -Path $settingsPath -Target $PSScriptRoot\powershell\settings.json -Force

# Symlink pwsh and powershell profiles and install packages necessary
$powershellDir = "$env:HOMEDRIVE\$env:HOMEPATH\Documents\WindowsPowerShell"
$pwshDir = "$env:HOMEDRIVE\$env:HOMEPATH\Documents\Powershell"
foreach ($dir in @($powershellDir, $pwshDir)) {
    if (-Not(Test-Path -Path $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir
    }
}
New-Item -ItemType SymbolicLink -Path $powershellDir\profile.ps1 -Target $PSScriptRoot\powershell\profile.ps1 -Force
New-Item -ItemType SymbolicLink -Path $pwshDir\profile.ps1 -Target $PSScriptRoot\powershell\pwsh-profile.ps1 -Force

# Symlink icons for terminal
New-Item -ItemType SymbolicLink -Path "$env:HOMEDRIVE\$env:HOMEPATH\Pictures\icons" -Target $PSScriptRoot\powershell\icons -Force

# Git config
New-Item -ItemType SymbolicLink -Path "$env:HOMEDRIVE\$env:HOMEPATH\.gitconfig" -Target $PSScriptRoot\git\gitconfig.win.work -Force

# Check if running in WSL and symlink from C:\tools\neovim\bin\win32yank.exe to ~/.local/bin/win32yank.exe and
# make sure to symlink /etc/wsl.conf to the one in this repo
Push-Location $PSScriptRoot
wsl cp wsl-setup.sh /tmp
wsl -- /tmp/wsl-setup.sh
wsl --shutdown
wsl cp wsl-dotfile-install.sh /tmp
wsl -- /tmp/wsl-dotfile-install.sh
Pop-Location

# Generate ssh key in wsl
wsl -- ssh-keygen -f id_rsa -t rsa -N \'\'

# Install clink and copy over files for setup

# Make sure to sync your connected MSFT AD account
# Settings > Accounts > Access Work or School > Click on msft account > Info > Sync
# Make sure to download updates and restart vm
# Connect to MSFTVpn at least once before any scripts will work

# Figure out issue with starting docker at login
# $account = "northamerica\andrewsidlo"
# $npipe = "\\.\pipe\docker_engine"                                                                                 
# $dInfo = New-Object "System.IO.DirectoryInfo" -ArgumentList $npipe                                               
# $dSec = $dInfo.GetAccessControl()                                                                                 
# $fullControl = [System.Security.AccessControl.FileSystemRights]::FullControl                                       
# $allow = [System.Security.AccessControl.AccessControlType]::Allow                                                  
# $rule = New-Object "System.Security.AccessControl.FileSystemAccessRule" -ArgumentList $account, $fullControl, $allow
# $dSec.AddAccessRule($rule)                                                                                        
# $dInfo.SetAccessControl($dSec)