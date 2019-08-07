function funcs --description "$USER - Show all defined functions and their descriptions"
  func_descriptions | csv | fzf --header='[func:description]'
end


