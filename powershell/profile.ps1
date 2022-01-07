if (Get-Command "starship.exe" -ErrorAction SilentlyContinue) { 
    Invoke-Expression (&starship init powershell)
}
else {
    # https://joonro.github.io/blog/posts/powershell-customizations.html
    # https://hodgkins.io/ultimate-powershell-prompt-and-git-setup
    # - https://github.com/MattHodge/MattHodgePowerShell/blob/master/PowerShellProfile/Microsoft.PowerShell_profile.ps1
    # http://serverfault.com/questions/95431
    function Test-Administrator {
        $user = [Security.Principal.WindowsIdentity]::GetCurrent();
        (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }
    
    function prompt {
        $origLastExitCode = $LastExitCode
    
        if (Test-Administrator) {
            # if elevated
            Write-Host "(Elevated) " -NoNewline -ForegroundColor White
        }
    
        Write-Host "$env:USERNAME" -NoNewline -ForegroundColor Cyan
        Write-Host " at " -NoNewline -ForegroundColor White
        Write-Host "$env:COMPUTERNAME".ToLower() -NoNewline -ForegroundColor Magenta
        Write-Host " in " -NoNewline -ForegroundColor White
    
        $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
        if ($curPath.ToLower().StartsWith($Home.ToLower())) {
            $curPath = "~" + $curPath.SubString($Home.Length)
        }
    
        Write-Host $curPath -NoNewline -ForegroundColor Blue
    
        $curBranch = git rev-parse --abbrev-ref HEAD
    
        if ($curBranch) {
            Write-Host " [$curBranch]" -NoNewline -ForegroundColor White
        }
    
        $LastExitCode = $origLastExitCode
        "`n$('>' * ($nestedPromptLevel + 1)) "
    }
}

#--------------------------------------------------------------
# Powershell Imports
#--------------------------------------------------------------

# Import Powershell Modules
# Install-Module -Name PSReadline -RequiredVersion 2.1.0
Import-Module -Name PSReadLine # -RequiredVersion 2.1.0 
Import-Module posh-git           # Install with: `Install-Module -Name posh-git`
Import-Module Get-ChildItemColor # could add -Scope CurrentUser for local install non admin
Import-Module DockerCompletion
Import-Module PSFzf

#--------------------------------------------------------------
# Misc Config
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
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -Function AcceptSuggestion

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
# Prompt Config
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
Set-Alias -Name which -Value where.exe
Remove-Item Alias:curl