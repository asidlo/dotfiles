function gdh --description "$USER - Shows git diff head for and preview each file"
  set -l staged (
    git status -s | fzf --ansi --no-sort --height 100% \
           --preview "echo {} | string trim | cut -d' ' -f2 | xargs -I@ sh -c 'git diff HEAD --color=always @'" \
           --preview-window='right' \
           -m --header="[git:'diff HEAD']"
  )

  if not test -z "$staged"
    set -l changes
    for change in $staged
      set changes $changes (echo $change | string trim | cut -d' ' -f2)
    end
    git diff HEAD $changes
  end
end

