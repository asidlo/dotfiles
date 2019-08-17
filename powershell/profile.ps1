#--------------------------------------------------------------
# Powershell Imports
#--------------------------------------------------------------

# Import Powershell Modules
Import-Module PSReadLine
Import-Module get-childitemcolor
Import-Module 'C:\tools\poshgit\dahlbyk-posh-git-9bda399\src\posh-git.psd1'

#--------------------------------------------------------------
# Misc Config
#--------------------------------------------------------------

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

#--------------------------------------------------------------
# Prompt Config
#--------------------------------------------------------------
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

    Write-VcsStatus

    $LastExitCode = $origLastExitCode
    "`n$('>' * ($nestedPromptLevel + 1)) "
}

# Git Color Settings
$GitPromptSettings.WorkingForegroundColor = "Red"
$GitPromptSettings.LocalWorkingStatusForegroundColor = "Red"
$GitPromptSettings.BeforeForegroundColor = "White"
$GitPromptSettings.AfterForegroundColor = "White"
$GitPromptSettings.BranchGoneStatusForegroundColor = "Cyan"

# Console Color Settings
# If ConEmu = Black, else DarkBlue
$BackgroundColor = $host.UI.RawUI.BackgroundColor

$host.PrivateData.ErrorBackgroundColor = $BackgroundColor
$host.PrivateData.WarningBackgroundColor = $BackgroundColor
$host.PrivateData.VerboseBackgroundColor = $BackgroundColor
$host.PrivateData.DebugBackgroundColor = $BackgroundColor

$host.PrivateData.VerboseForegroundColor = "Cyan"
$host.PrivateData.DebugForegroundColor = "Green"
$host.PrivateData.ProgressBackgroundColor = "DarkGray"
$host.PrivateData.ProgressForegroundColor = "Gray"

$GetChildItemColorTable['Directory'] = "Blue"
$GetChildItemColorExtensions.CompressedList += @(".tgz")
$GetChildItemColorExtensions.ImageList = @(".png", ".jpg", ".jfif")

ForEach ($Exe in $GetChildItemColorExtensions.ExecutableList) {
    $GetChildItemColorTable[$Exe] = "Green"
}

ForEach ($Exe in $GetChildItemColorExtensions.ImageList) {
    $GetChildItemColorTable[$Exe] = "Magenta"
}

ForEach ($Exe in $GetChildItemColorExtensions.TextList) {
    $GetChildItemColorTable[$Exe] = "White"
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

# Do not show dotfile when list directory contents
function ShowNonDotFiles {
    Get-ChildItem | Where-Object -FilterScript {$_ -notlike ".*"}
}

function ShowNonDotFilesWide {
    ShowNonDotFiles | Format-Wide -AutoSize
}

function ShowAllFiles {
    Get-ChildItemColor -Force
}

function cddash {
    if ($args[0] -eq '-') {
        $pwd = $OLDPWD;
    }
    else {
        $pwd = $args[0];
    }
    $tmp = Get-Location;

    if ($pwd) {
        Set-Location $pwd;
    }
    Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

# To print color names only
# > Get-ConsoleColor
# To print with colors
# > Get-ConsoleColor -Colorize
#
# https://www.petri.com/change-powershell-console-font-and-background-colors
function Get-ConsoleColor {
    Param(
        [switch]$Colorize
    )
     
    $wsh = New-Object -ComObject wscript.shell
     
    $data = [enum]::GetNames([consolecolor])
     
    if ($Colorize) {
        Foreach ($color in $data) {
            Write-Host $color -ForegroundColor $Color
        }
        [void]$wsh.Popup("The current background color is $([console]::BackgroundColor)", 16, "Get-ConsoleColor")
    }
    else {
        #display values
        $data
    }  
}
	
Function Show-ConsoleColor {
    Param()
    $host.PrivateData.psobject.properties | 
    ForEach-Object {
        #$text = "$($_.Name) = $($_.Value)"
        Write-host "$($_.name.padright(23)) = " -NoNewline
        Write-Host $_.Value -ForegroundColor $_.value
    }
}

Function Test-ConsoleColor {
    [cmdletbinding()]
    Param()
     
    Clear-Host
    $heading = "White"
    Write-Host "Pipeline Output" -ForegroundColor $heading
    Get-Service | Select-Object -first 5
     
    Write-Host "`nError" -ForegroundColor $heading
    Write-Error "I made a mistake"
     
    Write-Host "`nWarning" -ForegroundColor $heading
    Write-Warning "Let this be a warning to you."
     
    Write-Host "`nVerbose" -ForegroundColor $heading
    $VerbosePreference = "Continue"
    Write-Verbose "I have a lot to say."
    $VerbosePreference = "SilentlyContinue"
     
    Write-Host "`nDebug" -ForegroundColor $heading
    $DebugPreference = "Continue"
    Write-Debug "`nSomething is bugging me. Figure it out."
    $DebugPreference = "SilentlyContinue"
     
    Write-Host "`nProgress" -ForegroundColor $heading
    1..10 | ForEach-Object -Begin { $i = 0 } -process {
        $i++
        $p = ($i / 10) * 100
        Write-Progress -Activity "Progress Test" -Status "Working" -CurrentOperation $_ -PercentComplete $p
        Start-Sleep -Milliseconds 250
    }
}

# Usage: . Reload-Profile
# https://stackoverflow.com/questions/567650/how-to-reload-user-profile-from-script-file-in-powershell
function Reload-Profile {
    @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    ) | % {
        if (Test-Path $_) {
            Write-Verbose "Running $_"
            . $_
        }
    }    
}

function Kill-NxJavaProcesses {
  jps -l | Select-String "nexidia" | ForEach-Object { $p, $desc = $_ -split ' ', 2; Write-Host "`n$p - $desc"; Stop-Process -id $p -confirm -passthru} 
}

#--------------------------------------------------------------
# Aliases
#--------------------------------------------------------------
Set-Alias ll Get-ChildItemColor -option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
Set-Alias la ShowAllFiles -option AllScope

Set-Alias -Name cd -value cddash -Option AllScope

Set-Alias g git.exe -option AllScope


#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
#(& "C:\tools\Anaconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | Invoke-Expression
#endregion
