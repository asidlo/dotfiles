function gadd --description "$USER - Fuzzy search and add files to staging" 
  set -l files (git ls-files --modified | fzf --ansi --preview "git diff HEAD --color=always {}" -m --header="[git:add]")
  if not test -z "$files"
    git add --verbose $files
  end
end

