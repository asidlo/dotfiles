#--------------------------------------------------------------
# FAST STARTUP: Minimal synchronous loading
#--------------------------------------------------------------

# PSReadLine - only import if not already loaded (PS5.1 loads old version by default)
if (-not (Get-Module PSReadLine) -or (Get-Module PSReadLine).Version -lt [Version]"2.1.0") {
    Import-Module PSReadLine -MinimumVersion 2.1.0 -ErrorAction SilentlyContinue
}

#--------------------------------------------------------------
# PSReadLine Config (fast - just setting options)
#--------------------------------------------------------------
Set-PSReadLineOption -EditMode Emacs -BellStyle None -ShowToolTips
Set-PSReadLineOption -HistoryNoDuplicates -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally -MaximumHistoryCount 4000

if (-not [System.Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource History
}

# Key bindings
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Chord 'Shift+Tab' -Function Complete
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -ScriptBlock {
    [Microsoft.Powershell.PSConsoleReadline]::AcceptSuggestion()
    [Microsoft.Powershell.PSConsoleReadline]::EndOfLine()
}

Set-PSReadLineOption -Colors @{
    "Operator" = [ConsoleColor]::Gray
    "Parameter" = [ConsoleColor]::Gray
    "InlinePrediction" = [ConsoleColor]::DarkGray
}

#--------------------------------------------------------------
# Deferred loading - PSFzf after first prompt
#--------------------------------------------------------------
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    if (Get-Module PSFzf) {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
        Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
        Set-PsFzfOption -PSReadlineChordSetLocation 'Alt+c'
        Set-PsFzfOption -PSReadlineChordReverseHistoryArgs 'Alt+a'
    }
} | Out-Null

#--------------------------------------------------------------
# Prompt - minimal native (starship too slow in PS5)
#--------------------------------------------------------------
$ESC = [char]27
function prompt {
    $path = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    if ($path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
        $path = "~" + $path.Substring($HOME.Length)
    }
    "$ESC[36m$path$ESC[0m`n> "
}

#--------------------------------------------------------------
# Minimal functions and aliases
#--------------------------------------------------------------
$host.PrivateData.ProgressBackgroundColor = "DarkGray"
$host.PrivateData.ProgressForegroundColor = "Gray"

function Set-LocationEnhanced {
    param($Path)
    $tmp = $PWD
    if ($Path -eq '-') { Set-Location $OLDPWD } 
    elseif ($Path) { Set-Location $Path } 
    else { Set-Location ~ }
    $Global:OLDPWD = $tmp
}

Set-Alias -Name cd -Value Set-LocationEnhanced -Option AllScope
Set-Alias -Name which -Value Get-Command