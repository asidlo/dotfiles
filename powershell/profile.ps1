$modules = @(
    "PSReadLine",
    "PSFzf"
)

foreach ($module in $modules) {
    if (-Not(Get-Module -ListAvailable -Name $module)) {
        Install-Module -Force -Name $module -Scope CurrentUser
    }
    if ($module -eq "PSReadLine") {
        try {
            Import-Module -Name $module -MinimumVersion 2.1.0 -ErrorAction Ignore
        }
        catch {
            Install-Module -Name $module -MinimumVersion 2.1.0 -Force
            Import-Module -Name $module -MinimumVersion 2.1.0
        }
    }
    else {
        Import-Module -Name $module
    }
}

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

function IsVirtualTerminalProcessingEnabled {
    $MethodDefinitions = @'
[DllImport("kernel32.dll", SetLastError = true)]
public static extern IntPtr GetStdHandle(int nStdHandle);
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
'@
    $Kernel32 = Add-Type -MemberDefinition $MethodDefinitions -Name 'Kernel32' -Namespace 'Win32' -PassThru
    $hConsoleHandle = $Kernel32::GetStdHandle(-11) # STD_OUTPUT_HANDLE
    $mode = 0
    $Kernel32::GetConsoleMode($hConsoleHandle, [ref]$mode) >$null
    if ($mode -band 0x0004) {
        # 0x0004 ENABLE_VIRTUAL_TERMINAL_PROCESSING
        return $true
    }
    return $false
}

function CanUsePredictionSource {
    return (! [System.Console]::IsOutputRedirected) -and (IsVirtualTerminalProcessingEnabled)
}

Import-Module -Name PSReadLine 

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
Set-PSReadLineKeyHandler -Chord "Ctrl+f" -ScriptBlock {
    [Microsoft.Powershell.PSConsoleReadline]::AcceptSuggestion()
    [Microsoft.Powershell.PSConsoleReadline]::EndOfLine()
}

# https://github.com/kelleyma49/PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -PSReadlineChordSetLocation 'Alt+c'
Set-PsFzfOption -PSReadlineChordReverseHistoryArgs 'Alt+a'

# Clipboard interaction is bound by default in Windows mode, but not Emacs mode.
Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste

Set-PSReadLineOption -Colors @{
    "Operator"         = [ConsoleColor]:: Gray
    "Parameter"        = [ConsoleColor]:: Gray
    "InlinePrediction" = [ConsoleColor]:: DarkGray
}

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


#--------------------------------------------------------------
# Aliases
#--------------------------------------------------------------
# Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope
# Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name cd -Value Set-LocationEnhanced -Option AllScope
Set-Alias -Name which -Value Get-Command