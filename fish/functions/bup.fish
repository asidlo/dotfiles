function bup --description "$USER - Update brew plugins"
  set -l inst (brew outdated -v | eval "fzf $FZF_DEFAULT_OPTS -m --header='[brew:update]'" | cut -d' ' -f1)

  if not test (count $inst) = 0
    for prog in $inst
      brew upgrade "$prog"
    end
  end
end
