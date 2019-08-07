function bcup --description "$USER - Update brew cask plugins"
  set -l inst (brew cask list | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:update]'")

  if not test (count $inst) = 0
    for prog in $inst
      brew cask update "$prog"
    end
  end
end

