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

&"$PSScriptRoot\devbox\settings.ps1"

&"$PSScriptRoot\devbox\features.ps1"

&"$PSScriptRoot\devbox\choco.ps1"

# Install wsl
wsl --install -d Ubuntu
wsl --set-default Ubuntu

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

# TODO (AS): Change multitasking to System > Multitasking > SHow tabs from apps when snapping or pressing alt+tab (dont show tabs)