function bcip --description "$USER - Install brew cask plugins"
  set -l inst (brew search --casks | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:install]'")

  if not test (count $inst) = 0
    for prog in $inst
      brew cask install "$prog"
    end
  end
end

