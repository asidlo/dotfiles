#--------------------------------------------------------------
# FAST STARTUP: Only load essential modules synchronously
# Other modules are loaded on-demand or in background
#--------------------------------------------------------------

# PSReadLine is essential - load it (already loaded by default in pwsh 7+)
if (-not (Get-Module PSReadLine)) {
    Import-Module PSReadLine -MinimumVersion 2.1.0 -ErrorAction SilentlyContinue
}

# Deferred module loading - loads after first prompt (non-blocking)
$Global:_DeferredModulesLoaded = $false
$Global:_DeferredInit = {
    if ($Global:_DeferredModulesLoaded) { return }
    $Global:_DeferredModulesLoaded = $true
    
    # Load these in background after first prompt
    @("posh-git", "Get-ChildItemColor", "DockerCompletion", "PSFzf") | ForEach-Object {
        Import-Module $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
    
    # Setup PSFzf keybindings after it loads
    if (Get-Module PSFzf) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
        Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
        Set-PsFzfOption -PSReadlineChordSetLocation 'Alt+c'
        Set-PsFzfOption -PSReadlineChordReverseHistoryArgs 'Alt+a'
    }
    
    # Setup Get-ChildItemColor after it loads
    if (Get-Module Get-ChildItemColor) {
        $GetChildItemColorTable['Directory'] = "Blue"
        $GetChildItemColorTable['Default'] = "White"
        $GetChildItemColorExtensions.CompressedList += @(".tgz")
        $GetChildItemColorExtensions.ImageList = @(".png", ".jpg", ".jfif")
        ForEach ($Exe in $GetChildItemColorExtensions.ExecutableList) { $GetChildItemColorTable[$Exe] = "Green" }
        ForEach ($Exe in $GetChildItemColorExtensions.ImageList) { $GetChildItemColorTable[$Exe] = "Magenta" }
        ForEach ($Exe in $GetChildItemColorExtensions.CompressedList) { $GetChildItemColorTable[$Exe] = "Red" }
        ForEach ($Exe in $GetChildItemColorExtensions.DllPdbList) { $GetChildItemColorTable[$Exe] = "Red" }
        
        # Now that module is loaded, update aliases
        Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope -Scope Global -Force
        Set-Alias -Name ll -Value Get-ChildItemColor -Scope Global -Force
    }
}

# Register to run deferred init after first prompt using PSReadLine
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    & $Global:_DeferredInit
} | Out-Null

# Simplified check - skip P/Invoke which is slow
function CanUsePredictionSource {
    return (-not [System.Console]::IsOutputRedirected)
}

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

# https://github.com/PowerShell/PSReadLine/issues/2046
if (CanUsePredictionSource) {
    Set-PSReadLineOption -PredictionSource History
}

# history substring search
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

# Tab completion
Set-PSReadlineKeyHandler -Chord 'Shift+Tab' -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# https://devblogs.microsoft.com/powershell/announcing-psreadline-2-1-with-predictive-intellisense/
# https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1#L13-L21
# Set-PSReadLineKeyHandler -Chord "Ctrl+f" -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord "Ctrl+Spacebar" -ScriptBlock {
    [Microsoft.Powershell.PSConsoleReadline]::AcceptSuggestion()
    [Microsoft.Powershell.PSConsoleReadline]::EndOfLine()
}
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -ScriptBlock {
    [Microsoft.Powershell.PSConsoleReadline]::AcceptSuggestion()
    [Microsoft.Powershell.PSConsoleReadline]::EndOfLine()
}

# https://github.com/kelleyma49/PSFzf - keybindings set in deferred init

# Clipboard interaction is bound by default in Windows mode, but not Emacs mode.
Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste

Set-PSReadLineOption -Colors @{
    #     "ContinuationPrompt" = [ConsoleColor]:: Magenta
    #     "Emphasis"           = [ConsoleColor]:: Gray
    #     "Error"              = [ConsoleColor]:: Red
    #     "Selection"          = [ConsoleColor]:: Cyan
    #     "Default"            = [ConsoleColor]:: White
    #     "Comment"            = [ConsoleColor]:: Gray
    #     "Keyword"            = [ConsoleColor]:: Green
    #     "String"             = [ConsoleColor]:: White
    "Operator"         = [ConsoleColor]:: Gray
    #     "Variable"           = [ConsoleColor]:: Blue
    #     "Command"            = [ConsoleColor]:: Yellow
    "Parameter"        = [ConsoleColor]:: Gray
    #     "Type"               = [ConsoleColor]:: Yellow
    #     "Number"             = [ConsoleColor]:: White
    #     "Member"             = [ConsoleColor]:: Cyan
    "InlinePrediction" = [ConsoleColor]:: DarkGray
}

#--------------------------------------------------------------
# Colors - Get-ChildItemColor settings moved to deferred init
#--------------------------------------------------------------
$host.PrivateData.ProgressBackgroundColor = "DarkGray"
$host.PrivateData.ProgressForegroundColor = "Gray"

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

Function New-SymLink ($Source, $Target) {
    $Source = (Get-Item $Source).FullName
    $Target = $Target.replace("~", $env:HOMEDRIVE + $env:HOMEPATH)

    if (test-path -pathtype container $source) {
        $command = "cmd /c mklink /d"
    }
    else {
        $command = "cmd /c mklink"
    }

    Invoke-Expression "$command $Target $Source"
}

# Dotnet cli completion
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

#--------------------------------------------------------------
# Aliases - ls/ll set in deferred init after Get-ChildItemColor loads
#--------------------------------------------------------------
Set-Alias -Name cd -Value Set-LocationEnhanced -Option AllScope
Set-Alias -Name which -Value Get-Command
Set-Alias -Name k -Value kubectl
Set-Alias -Name ln -Value New-Symlink

#--------------------------------------------------------------
# Prompt - cached starship init for faster startup
#--------------------------------------------------------------
$_starshipCache = "$env:LOCALAPPDATA\starship_init.ps1"
$_starshipBin = (Get-Command "starship" -ErrorAction SilentlyContinue).Source

if ($_starshipBin) {
    # Regenerate cache if starship binary is newer than cache
    if (-not (Test-Path $_starshipCache) -or 
        (Get-Item $_starshipBin).LastWriteTime -gt (Get-Item $_starshipCache).LastWriteTime) {
        & starship init powershell --print-full-init | Out-File $_starshipCache -Encoding utf8
    }
    . $_starshipCache
}