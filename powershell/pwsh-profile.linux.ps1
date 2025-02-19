$modules = @(
    "PSReadLine",
    "posh-git",
    "Get-ChildItemColor"
    "PSFzf"
    # "Az"
)

function Add-ToPath()
{
    param (
        [string]$PathToAdd
    )

    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Process)
    if ($currentPath -notcontains $PathToAdd)
    {
        [System.Environment]::SetEnvironmentVariable("PATH", "${currentPath}:${PathToAdd}", [System.EnvironmentVariableTarget]::Process)
    }
}

Add-ToPath "$env:HOME/.local/bin"

foreach ($module in $modules)
{
    if (-Not(Get-Module -ListAvailable -Name $module))
    {
        Install-Module -Force -Name $module -Scope CurrentUser
    }
    if ($module -eq "PSReadLine")
    {
        try
        {
            Import-Module -Name $module -MinimumVersion 2.1.0 -Force -ProgressAction SilentlyContinue -DisableNameChecking -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -ErrorVariable ReadlineImportError
            if ($ReadlineImportError -ne $nul)
            {
                Install-Module -Name $module -MinimumVersion 2.1.0 -Force
                Import-Module -Name $module -MinimumVersion 2.1.0 -Force -NoClobber
            }
        } catch [System.IO.FileLoadException]
        {
            Write-Debug "Module $($module) already loaded"
        }
    } else
    {
        Import-Module -Name $module
    }
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

# https://github.com/kelleyma49/PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -PSReadlineChordSetLocation 'Alt+c'
Set-PsFzfOption -PSReadlineChordReverseHistoryArgs 'Alt+a'

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
$host.PrivateData.ProgressBackgroundColor = "DarkGray"
$host.PrivateData.ProgressForegroundColor = "Gray"

$GetChildItemColorTable['Directory'] = "Blue"
$GetChildItemColorTable['Default'] = "White"
$GetChildItemColorExtensions.CompressedList += @(".tgz")
$GetChildItemColorExtensions.ImageList = @(".png", ".jpg", ".jfif")

ForEach ($Exe in $GetChildItemColorExtensions.ExecutableList)
{
    $GetChildItemColorTable[$Exe] = "Green"
}

ForEach ($Exe in $GetChildItemColorExtensions.ImageList)
{
    $GetChildItemColorTable[$Exe] = "Magenta"
}

ForEach ($Exe in $GetChildItemColorExtensions.CompressedList)
{
    $GetChildItemColorTable[$Exe] = "Red"
}

ForEach ($Exe in $GetChildItemColorExtensions.DllPdbList)
{
    $GetChildItemColorTable[$Exe] = "Red"
}

#--------------------------------------------------------------
# Functions
#--------------------------------------------------------------
function Set-LocationEnhanced
{
    if ($args[0] -eq '-')
    {
        $DIR = $OLDPWD;
    } else
    {
        $DIR = $args[0];
    }
    $tmp = Get-Location;

    if ($DIR)
    {
        Set-Location $DIR;
    } else
    {
        Set-Location (Resolve-Path ~)
    }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

function Stop-JavaProcesses
{
    jps -l | ForEach-Object { $p, $desc = $_ -split ' ', 2; Write-Host "`n$p - $desc"; Stop-Process -id $p -confirm -passthru } 
}

function New-SymLink ($Source, $Target)
{
    $Source = (Get-Item $Source).FullName
    $Target = $Target.replace("~", $env:HOMEDRIVE + $env:HOMEPATH)

    if (test-path -pathtype container $source)
    {
        $command = "cmd /c mklink /d"
    } else
    {
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
# Aliases
#--------------------------------------------------------------
Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope
Set-Alias -Name ll -Value Get-ChildItemColor
Set-Alias -Name cd -Value Set-LocationEnhanced -Option AllScope
Set-Alias -Name which -Value Get-Command
Set-Alias -Name k -Value kubectl

#--------------------------------------------------------------
# Prompt
#--------------------------------------------------------------
if (Get-Command "starship" -ErrorAction SilentlyContinue)
{ 
    Invoke-Expression (&starship init powershell)
}

if (Get-Command "$env:HOMEPATH\.azure-kubectl\kubectl.exe" -ErrorAction SilentlyContinue)
{
    &"$env:HOMEPATH\.azure-kubectl\kubectl.exe" completion powershell | Out-String | Invoke-Expression
}

