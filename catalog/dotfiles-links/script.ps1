$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
function SafeLink($target,$link){ if (Test-Path $link){ Remove-Item -Force -Recurse $link }; New-Item -ItemType SymbolicLink -Path $link -Target $target -Force | Out-Null }
# Terminal settings
$terminalSettings = "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
SafeLink "$root\powershell\settings.json" $terminalSettings
# Icons
SafeLink "$root\powershell\icons" "$env:HOMEDRIVE$env:HOMEPATH\Pictures\icons"
# Git config
SafeLink "$root\git\gitconfig.win.work" "$env:HOMEDRIVE$env:HOMEPATH\.gitconfig"
# Starship
$configDir = "$env:HOMEDRIVE$env:HOMEPATH\.config"; if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir | Out-Null }
SafeLink "$root\zsh\starship.windows.toml" "$configDir\starship.toml"
# Clink
$clinkSettingsDir = "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local\clink"; if (Test-Path $clinkSettingsDir) { Remove-Item -Path $clinkSettingsDir -Force }
SafeLink "$root\clink" $clinkSettingsDir
# Neovim
$nvimDir = "$env:HOMEDRIVE$env:HOMEPATH\AppData\Local\nvim"; if (Test-Path $nvimDir) { Remove-Item -Path $nvimDir -Force }
SafeLink "$root\nvim\lazynvim" $nvimDir
