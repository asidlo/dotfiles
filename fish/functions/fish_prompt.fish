set -x CONDA_LEFT_PROMPT

# Options
set -e __fish_git_prompt_show_informative_status
set __fish_git_prompt_showcolorhints
set __fish_git_prompt_showupstream "informative"

# Colors
set green (set_color green)
set cyan (set_color cyan)
set blue (set_color blue)
set magenta (set_color magenta)
set normal (set_color normal)
set red (set_color red)
set yellow (set_color yellow)

set __fish_git_prompt_color_branch cyan --bold
set __fish_git_prompt_color_dirtystate white
set __fish_git_prompt_color_invalidstate red
set __fish_git_prompt_color_merging yellow
set __fish_git_prompt_color_stagedstate yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red


# Icons
# https://medium.com/@joshuacrass/git-fish-prompt-faa389fff07c
set __fish_git_prompt_char_cleanstate ''
set __fish_git_prompt_char_conflictedstate '!' 
set __fish_git_prompt_char_dirtystate 'M'
set __fish_git_prompt_char_invalidstate 'X'
set __fish_git_prompt_char_stagedstate 'S'
set __fish_git_prompt_char_stashstate '_'
set __fish_git_prompt_char_stateseparator '|'
set __fish_git_prompt_char_untrackedfiles '?'
set __fish_git_prompt_char_upstream_ahead ' A'
set __fish_git_prompt_char_upstream_behind ' B'
set __fish_git_prompt_char_upstream_diverged ' D'
set __fish_git_prompt_char_upstream_equal '=' 


function fish_prompt --description "$USER - User defined prompt for fish shell"
  set last_status $status

  set_color cyan
  printf '%s' $USER
  set_color normal

  printf ' at '

  set_color magenta
  printf '%s' (hostname)
  set_color normal

  printf ' in '

  set_color blue
  printf '%s' (prompt_pwd)
  set_color normal

  printf '%s\n' (__fish_git_prompt)
  if test "$last_status" != 0
    set_color red
    printf '> '
    set_color normal
  else
    printf '> '
  end
end
