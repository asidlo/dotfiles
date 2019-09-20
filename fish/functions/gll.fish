function gll --description "$USER - Shows git commit logs and preview"
  set -l commits (
    git lo --color=always $argv | fzf --ansi --no-sort --height 100% \
           --preview-window='right' \
           --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I@ sh -c 'git show --color=always @'" \
           -m --header="[git:log]"
  )

  if not test -z "$commits"
    set -l hashes
    for commit in $commits
      set hashes $hashes (echo $commit | cut -d' ' -f1 | string trim)
    end
    echo $hashes | pbcopy
    git show $hashes
  end
end

