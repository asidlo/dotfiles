function funcu --description "$USER - Show all user defined functions and their descriptions"
  func_descriptions -u | grep "$USER" | csv | sed "s/$USER - //g" | fzf --header="[func:$USER]"
end
