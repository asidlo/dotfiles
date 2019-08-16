function reload --description "$USER - Reload fish shell"
  if contains -- -f $argv
    set -e __FISH_CFG_INITIALIZED
  end
  source ~/.config/fish/config.fish
end

