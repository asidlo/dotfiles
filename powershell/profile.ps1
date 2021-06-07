#--------------------------------------------------------------
# Powershell Imports
#--------------------------------------------------------------

# Import Powershell Modules
Import-Module PSReadLine 
Import-Module posh-git           # Install with: `Install-Module -Name posh-git`
Import-Module Get-ChildItemColor # could add -Scope CurrentUser for local install non admin
Import-Module DockerCompletion
# Import-Module pscx

# How to see all functions provided by a module
# Get-Command -Module pscx

# Make sure you copy the escape.ahk from ~\Documents\dotfiles\powershell\escape.ahk
# into C:\Users\<UserName>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
# in order for it to run on user login

#--------------------------------------------------------------
# Misc Config
#--------------------------------------------------------------

# Vi Mode (needs to be before other options)
# Set-PSReadLineOption -EditMode Vi 
# Set-PSReadLineOption -ViModeIndicator Cursor
# Set-PSReadLineKeyHandler -Chord Ctrl+[ -Function ViCommandMode

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
}

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

    $curBranch = git rev-parse --abbrev-ref HEAD

    if ($curBranch) {
        Write-Host " [$curBranch]" -NoNewline -ForegroundColor White
    }

    $LastExitCode = $origLastExitCode
    "`n$('>' * ($nestedPromptLevel + 1)) "
}

# Console Color Settings
$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "White"
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
         $pwd = $OLDPWD;
	 }
	 else {
         $pwd = $args[0];
	 }
	 $tmp = Get-Location;

	 if ($pwd) {
         Set-Location $pwd;
	 } else {
         Set-Location (Resolve-Path ~)
	 }
	 Set-Variable -Name OLDPWD -Value $tmp -Scope global;
}

function Stop-NxJavaProcesses {
    jps -l | Select-String "nexidia" | ForEach-Object { $p, $desc = $_ -split ' ', 2; Write-Host "`n$p - $desc"; Stop-Process -id $p -confirm -passthru} 
}

#--------------------------------------------------------------
# Aliases
#--------------------------------------------------------------
Set-Alias -Name ls -Value Get-ChildItemColorFormatWide -Option AllScope
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name cd -Value Set-LocationEnhanced -Option AllScope
Set-Alias -Name which -Value where.exe
Remove-Item Alias:curl