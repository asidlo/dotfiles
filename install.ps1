$IsUserAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

if (-not($IsUserAdmin)) {
    Write-Error "You need to run this script as an admin user." -Category AuthenticationError
}

# Disable wsl and reenable to ensure latest version is installed; otherwise group policy warnings occur
# dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

&"$PSScriptRoot\devbox\settings.ps1"
&"$PSScriptRoot\devbox\features.ps1"

# TODO (AS): Restart devbox

# Install wsl
# Doesnt seem to work, needs to be run without n flag. Running wsl --install -d ubuntu afterwards works, but asks
# for username and password interactively. If we could automate this that would be great.
# wsl --install -d ubuntu -n

# TODO (AS): Restart devbox (Restart-Computer -Force)
# TODO (AS): Remove linux shortcut on desktop 

# Install packages
# TODO (AS): Make generic to pass list of packages similar to choco setup
choco install nerd-fonts-meslo -y
winget install --id Docker.DockerDesktop --accept-source-agreements --disable-interactivity -h
winget install --id Starship.Starship --accept-source-agreements --disable-interactivity -h
winget install --id sharkdp.fd --accept-source-agreements --disable-interactivity -h
winget install --id BurntSushi.ripgrep.MSVC --accept-source-agreements --disable-interactivity -h
winget install --id chrisant996.Clink --accept-source-agreements --disable-interactivity -h
winget install --id junegunn.fzf --accept-source-agreements --disable-interactivity -h
winget install --id Neovim.Neovim --accept-source-agreements --disable-interactivity -h
winget install --id JesseDuffield.lazygit --accept-source-agreements --disable-interactivity -h
winget install --id LLVM.LLVM --accept-source-agreements --disable-interactivity -h
winget install --id GoLang.Go --accept-source-agreements --disable-interactivity -h
winget install --id vim.vim --accept-source-agreements --disable-interactivity -h
winget install azcopy --accept-source-agreements --disable-interactivity -h
winget install python3 --accept-source-agreements --disable-interactivity -h

# Terminal settings
$settingsPath = "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
New-Item -ItemType SymbolicLink -Path $settingsPath -Target $PSScriptRoot\powershell\settings.json -Force

Install-Module -Name PSDesiredStateConfiguration
# TODO (AS): run Optimize-WindowsDefnender

# Install Ev2

# Symlink pwsh and powershell profiles and install packages necessary
# TODO (AS): Maybe Have a basic powershell config for onedrive and then source C:\src\powershell if present
$powershellDir = "$env:HOMEDRIVE\$env:HOMEPATH\OneDrive - Microsoft\Documents\WindowsPowerShell"
$pwshDir = "$env:HOMEDRIVE\$env:HOMEPATH\OneDrive - Microsoft\Documents\PowerShell"
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

$configDir = "$env:HOMEDRIVE\$env:HOMEPATH\.config"
if (Test-Path -Path $configDir -PathType Container) {
    New-Item -ItemType Directory -Path $configDir
}
New-Item -ItemType SymbolicLink -Path "$env:HOMEDRIVE\$env:HOMEPATH\.config\starship.toml" -Target $PSScriptRoot\zsh\starship.windows.toml -Force

$clinkSettingsDir = "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\clink"
if (Test-Path -Path $clinkSettingsDir -PathType Container) {
    Remove-Item -Path $clinkSettingsDir -Force
}
New-Item -ItemType SymbolicLink -Path "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\clink" -Target $PSScriptRoot\clink -Force


# TODO (AS): Set neovim config to use clang on windows
$nvimDir = "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\nvim"
if (Test-Path -Path $nvimDir -PathType Container) {
    Remove-Item -Path $nvimDir -Force
}
New-Item -ItemType SymbolicLink -Path "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\nvim" -Target $PSScriptRoot\nvim\lazynvim -Force

# Check if running in WSL and symlink from C:\tools\neovim\bin\win32yank.exe to ~/.local/bin/win32yank.exe and
# make sure to symlink /etc/wsl.conf to the one in this repo
# Push-Location $PSScriptRoot
# wsl cp wsl-setup.sh /tmp
# wsl -- /tmp/wsl-setup.sh
# wsl --shutdown
# wsl cp wsl-dotfile-install.sh /tmp
# wsl -- /tmp/wsl-dotfile-install.sh
# Pop-Location

# Generate ssh key in wsl
# wsl -- ssh-keygen -f id_rsa -t rsa -N \'\'

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