$IsUserAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

if (-not($IsUserAdmin)) {
    Write-Error "You need to run this script as an admin user." -Category AuthenticationError
}

# Check if choco installed, if not install choco .exe and add choco to PATH
Get-Command choco -ErrorAction SilentlyContinue -ErrorVariable ChocoError | Out-Null
if ($ChocoError) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

if ([string]::IsNullOrEmpty($Packages)) {
    $pkgs = $defaultPackages
}
else {
    $pkgs = Get-Content -Raw -Path $Packages | ConvertFrom-Json
}

ForEach ($pkg in $pkgs) {
    if ($pkg.params) {
        if ($pkg.version) {
            choco install $pkg.pkg --params $pkg.params --version $pkg.version -y
        }
        else {
            choco install $pkg.pkg --params $pkg.params -y
        }
    }
    else {
        if ($pkg.version) {
            choco install $pkg.pkg --version $pkg.version -y
        }
        else {
            choco install $pkg.pkg -y
        }
    }
}