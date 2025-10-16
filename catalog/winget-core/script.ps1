param(
  [string]$packages
)
$ErrorActionPreference = 'Stop'
if (-not $packages) {
  $packages = @(
    'Docker.DockerDesktop',
    'Starship.Starship',
    'sharkdp.fd',
    'sharkdp.bat',
    'BurntSushi.ripgrep.MSVC',
    'chrisant996.Clink',
    'junegunn.fzf',
    'Neovim.Neovim',
    'JesseDuffield.lazygit',
    'GoLang.Go',
    'vim.vim',
    'azcopy',
    'python3',
    'Outlook for Windows',
    'Microsoft.WindowsTerminal',
    'Microsoft.Teams',
    'Microsoft.AzureCLI',
    'LLVM.LLVM',
    'Rustlang.Rustup',
    'OpenJS.NodeJS.LTS',
    'Microsoft.PowerToys'
  )
} else {
  $packages = $packages.Split(' ') | Where-Object { $_ }
}
foreach ($p in $packages) {
  Write-Host "[winget] installing $p"
  winget install --id $p --accept-source-agreements --disable-interactivity -h 2>$null
}
