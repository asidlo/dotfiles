function fge --description "$USER - Find search term and open editor at result"
  if test (count $argv) -ne 0 
    set -l match (
      rg --color=never --line-number "$1" | fzf --no-multi --delimiter : \
        --preview "bat --color=always --line-range {2}: {1}"
    )
    set -l file (echo $match | cut -d':' -f1)
    if not test -z "$file"
      $EDITOR $file +(echo $match | cut -d':' -f2)
    end
  else
    set_color red
    echo "usage: fge [searchterm], missing searchterm arg" 1>&2
    set_color normal
    return 1
  end
end

