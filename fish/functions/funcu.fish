function funcu --description "$USER - Show all user defined functions and their descriptions"
  set -l funcs (func_descriptions -u | grep "$USER" | csv | sed "s/$USER - //g" | fzf --header="[func:$USER]")

  if not test -z "$funcs"
    set -l cmd (echo $funcs | cut -d" " -f1 | string trim)
    $cmd
  end
end
