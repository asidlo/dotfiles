# Copy/Symlink icons to pictures directory
# Symlink work.settings.json for windows terminal
# Symlink gitconfig.win.work
# Install clink and copy over files for setup
# Setup wsl and execute the install.sh and symlink wsl.conf

$settingsPath = "$env:HOMEDRIVE\$env:HOMEPATH\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
New-Item -ItemType SymbolicLink -Path $settingsPath -Target $PSScriptRoot\powershell\settings.json -Force

# Install meslo nerd fonts
choco install -y nerd-fonts-meslo

# Install Neovim
choco install -y neovim

# Install FZF
choco install -y fzf
choco install -y starship

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


# Check if running in WSL and symlink from C:\tools\neovim\bin\win32yank.exe to ~/.local/bin/win32yank.exe and
# make sure to symlink /etc/wsl.conf to the one in this repo