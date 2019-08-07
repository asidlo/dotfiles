function ffe --description "$USER - Find a file and open it in editor"
  set -lx FZF_DEFAULT_COMMAND 'fd --type f --follow --color=never --hidden -E .git'
  set -l pwd (prompt_pwd)
  set -l file (fzf --no-multi --preview 'bat --color=always --line-range :500 {}' -m --header="[fd:$pwd]")

  if not test -z "$file"
    $EDITOR $file
  end
end

