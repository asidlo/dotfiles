#--------------------------------------------------------------
# Module Imports
#--------------------------------------------------------------
Import-Module -Name PSReadLine -RequiredVersion 2.1.0 
Import-Module posh-git 
Import-Module Get-ChildItemColor
Import-Module DockerCompletion
Import-Module PSFzf

#--------------------------------------------------------------
# PSReadline Config
#--------------------------------------------------------------
Set-PSReadLineOption -EditMode Emacs

# Turn off annoying bell
Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaximumHistoryCount 4000

Set-PSReadLineOption -PredictionSource History

# history substring search
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# Tab completion
Set-PSReadlineKeyHandler -Chord 'Shift+Tab' -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# https://devblogs.microsoft.com/powershell/announcing-psreadline-2-1-with-predictive-intellisense/
# https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1#L13-L21
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -Function AcceptSuggestion

# https://github.com/kelleyma49/PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -PSReadlineChordSetLocation 'Alt+c'
Set-PsFzfOption -PSReadlineChordReverseHistoryArgs 'Alt+a'

# Clipboard interaction is bound by default in Windows mode, but not Emacs mode.
Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste

Set-PSReadLineOption -Colors @{
    "ContinuationPrompt" = [ConsoleColor]:: Magenta
    "Emphasis"           = [ConsoleColor]:: Gray
    "Error"              = [ConsoleColor]:: Red
    "Selection"          = [ConsoleColor]:: Cyan
    "Default"            = [ConsoleColor]:: White
    "Comment"            = [ConsoleColor]:: Gray
    "Keyword"            = [ConsoleColor]:: Green
    "String"             = [ConsoleColor]:: White
    "Operator"           = [ConsoleColor]:: Gray
    "Variable"           = [ConsoleColor]:: Blue
    "Command"            = [ConsoleColor]:: Yellow
    "Parameter"          = [ConsoleColor]:: Gray
    "Type"               = [ConsoleColor]:: Yellow
    "Number"             = [ConsoleColor]:: White
    "Member"             = [ConsoleColor]:: Cyan
    "InlinePrediction"   = [ConsoleColor]:: DarkGray
}

#--------------------------------------------------------------
# Colors
#--------------------------------------------------------------
# Console Color Settings
# $host.UI.RawUI.BackgroundColor = "Black"
# $host.UI.RawUI.ForegroundColor = "White"
# $BackgroundColor = $host.UI.RawUI.BackgroundColor

# $host.PrivateData.ErrorBackgroundColor = $BackgroundColor
# $host.PrivateData.WarningBackgroundColor = $BackgroundColor
# $host.PrivateData.VerboseBackgroundColor = $BackgroundColor
# $host.PrivateData.DebugBackgroundColor = $BackgroundColor

# $host.PrivateData.VerboseForegroundColor = "Cyan"
# $host.PrivateData.DebugForegroundColor = "Green"
# $host.PrivateData.ProgressBackgroundColor = "DarkGray"
# $host.PrivateData.ProgressForegroundColor = "Gray"

$GetChildItemColorTable['Directory'] = "Blue"
$GetChildItemColorTable['Default'] = "White"
$GetChildItemColorExtensions.CompressedList += @(".tgz")
$GetChildItemColorExtensions.ImageList = @(".png", ".jpg", ".jfif")

ForEach ($Exe in $GetChildItemColorExtensions.ExecutableList) {
    $GetChildItemColorTable[$Exe] = "Green"
}

ForEach ($Exe in $GetChildItemColorExtensions.ImageList) {
    $GetChildItemColorTable[$Exe] = "Magenta"
}

ForEach ($Exe in $GetChildItemColorExtensions.CompressedList) {
    $GetChildItemColorTable[$Exe] = "Red"
}

ForEach ($Exe in $GetChildItemColorExtensions.DllPdbList) {
    $GetChildItemColorTable[$Exe] = "Red"
}

#--------------------------------------------------------------
# Functions
#--------------------------------------------------------------
function Set-LocationEnhanced {
    if ($args[0] -eq '-') {
        $DIR = $OLDPWD;
    }
    else {
        $DIR = $args[0];
    }
    $tmp = Get-Location;

    if ($DIR) {
        Set-Location $DIR;
    }
    else {
        Set-Location (Resolve-Path ~)
    }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

function Stop-JavaProcesses {
    jps -l | ForEach-Object { $p, $desc = $_ -split ' ', 2; Write-Host "`n$p - $desc"; Stop-Process -id $p -confirm -passthru } 
}

#--------------------------------------------------------------
# Aliases
#--------------------------------------------------------------
Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name cd -Value Set-LocationEnhanced -Option AllScope
Set-Alias -Name which -Value Get-Command

#--------------------------------------------------------------
# Prompt
#--------------------------------------------------------------
if (Get-Command "starship.exe" -ErrorAction SilentlyContinue) { 
    Invoke-Expression (&starship init powershell)
}
