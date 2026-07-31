param(
  [string]$packages
)
$ErrorActionPreference = 'Stop'
if (-not $packages) {
  # NOTE: python3, Microsoft.WindowsTerminal, OpenJS.NodeJS.LTS and
  # Microsoft.PowerToys are intentionally omitted -- the vendored
  # WindowsDeveloperConfig base setup (Phase 2 of install.ps1) installs them.
  # eza + zoxide are added here because clink\zshify.lua depends on them and
  # WDC does not provide them.
  $packages = @(
    'Docker.DockerDesktop',
    'Starship.Starship',
    'eza-community.eza',
    'ajeetdsouza.zoxide',
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
    'Outlook for Windows',
    'Microsoft.Teams',
    'Microsoft.AzureCLI',
    'LLVM.LLVM',
    'Rustlang.Rustup'
  )
} else {
  $packages = $packages.Split(' ') | Where-Object { $_ }
}
$issues = @()
foreach ($p in $packages) {
  Write-Host "[winget] installing $p"
  # --accept-package-agreements is required alongside --disable-interactivity, or
  # winget aborts any package that carries a license agreement (e.g. Docker Desktop).
  winget install --id $p --accept-source-agreements --accept-package-agreements --disable-interactivity -h 2>$null
  if ($LASTEXITCODE -ne 0) { $issues += "$p (exit $LASTEXITCODE)" }
}
# winget returns non-zero for real failures AND for benign "already installed / no
# applicable upgrade" cases; surface a single non-fatal summary so genuine failures
# are visible without aborting the run or spamming warnings on idempotent re-runs.
if ($issues.Count) {
  Write-Warning "[winget] $($issues.Count) package(s) returned non-zero (may already be installed): $($issues -join '; ')"
}
