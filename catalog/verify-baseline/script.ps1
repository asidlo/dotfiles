$ErrorActionPreference = 'Continue'
$checks = @(
  @{ Name='Docker'; Test={ Get-Command docker -ErrorAction SilentlyContinue } },
  @{ Name='Neovim'; Test={ Get-Command nvim -ErrorAction SilentlyContinue } },
  @{ Name='Az CLI'; Test={ Get-Command az -ErrorAction SilentlyContinue } },
  @{ Name='Node'; Test={ Get-Command node -ErrorAction SilentlyContinue } },
  @{ Name='Go'; Test={ Get-Command go -ErrorAction SilentlyContinue } },
  @{ Name='Rustup'; Test={ Get-Command rustup -ErrorAction SilentlyContinue } },
  @{ Name='PowerToys'; Test={ Test-Path 'C:\\Program Files\\PowerToys\\PowerToys.exe' } },
  @{ Name='Meslo Nerd Font'; Test={ (Get-ChildItem "$env:WINDIR\Fonts" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Meslo' }) } },
  @{ Name='Gitconfig link'; Test={ Test-Path "$env:HOMEDRIVE$env:HOMEPATH\.gitconfig" } },
  @{ Name='Starship config'; Test={ Test-Path "$env:HOMEDRIVE$env:HOMEPATH\.config\starship.toml" } }
)
$results = foreach ($c in $checks) {
  [PSCustomObject]@{ Item = $c.Name; Present = [bool](& $c.Test) }
}
$results | Format-Table -AutoSize | Out-String | Write-Host
if ($results.Where({-not $_.Present}).Count -eq 0) {
  Write-Host '[verify] All baseline items present.'
} else {
  Write-Host '[verify] Missing items:'
  $results.Where({-not $_.Present}) | ForEach-Object { Write-Host " - $($_.Item)" }
  exit 1
}
