# Remove fish greeting
set fish_greeting

if test umask = "0000"
  umask 022
end

switch (uname)
case Linux
  set -g workspace_dir ~/workspace
  set -g go_root /usr/local/go
case Darwin
  set -g workspace_dir ~/Documents/workspace
  set -g go_root /usr/local/Cellar/go/*/libexec
end

# Show all hidden files and files that are being ignored by vcs
# https://sidneyliebrand.io/blog/how-fzf-and-ripgrep-improved-my-workflow?source=post_page---------------------------
set -l FD_OPTS                 "--follow --exclude .git --exclude node_modules"

# For large git projects, use git ls-files for everything else use fd
set -gx FZF_DEFAULT_COMMAND    "git ls-files --cached --others --exclude-standard 2> /dev/null | fd --type f --type l $FD_OPTS"
set -gx FZF_CTRL_T_COMMAND     $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND      "fd --type d $FD_OPTS"

# https://github.com/dracula/dracula-theme
# https://minsw.github.io/fzf-color-picker/
set -gx FZF_DEFAULT_OPTS       '--color=fg:#c2bebe,bg:#282a36,hl:#8be9fd' \
                               '--color=fg+:#f8f8f2,bg+:#282a36,hl+:#ff79c6' \
                               '--color=info:#bd93f9,prompt:#ff79c6,pointer:#ff79c6' \
                               '--color=marker:#50fa7b,spinner:#8be9fd,header:#f1fa8c' \
                               '--height 50% -1 --reverse --multi --inline-info' \
                               '--preview="bat --color=always --style=numbers {}"' \
                               "--preview-window='right:hidden'" \
                               # "--preview-window='right:hidden:wrap'" \
                               "--bind='F2:toggle-preview'" \
                               "--bind='ctrl-d:half-page-down'" \
                               "--bind='ctrl-u:half-page-up'" \
                               "--bind='ctrl-a:select-all+accept'" \
                               "--bind='ctrl-y:execute-silent(echo {+} | copy)'"

set -gx LPS_DEFAULT_USERNAME   'sidlo.andrew@gmail.com'
set -gx VISUAL                 nvim
set -gx EDITOR                 nvim
set -gx GOPATH                 "$workspace_dir/go"
set -gx GOROOT                 $go_root 
set -gx FISH_HOME              ~/.config/fish
set -gx FISH_FUNCS             $FISH_HOME/functions
set -gx CARGO_HOME             ~/.cargo
set -gx LLVM_HOME              /usr/local/opt/llvm
set -gx LDFLAGS                "-L/usr/local/opt/llvm/lib"
set -gx CPPFLAGS               "-I/usr/local/opt/llvm/include"
set -gx ANACONDA_HOME          /usr/local/anaconda3
set -gx DOTDIR                 ~/documents/dotfiles
set -gx PIP_REQUIRE_VIRTUALENV false

# Aliases (-s write function to file...makes it have a more global scope)
alias cls "clear"

if type -q xsel
	alias copy "xsel -i -b"
end
if type -q xclip
	alias copy "xclip -selection clipboard"
end
if type -q pbcopy
	alias copy "pbcopy"
end
if type -q clip.exe
	alias copy "clip.exe"
end

alias csv "column -t -s,"

# Abbreviations
abbr g 'git'
abbr py  'python'
abbr py3  'python3'
abbr conff "$EDITOR ~/.config/fish/config.fish"
abbr confe "$EDITOR ~/.vimrc"
abbr tree "tree -C"

# Set user paths, could just be set via cmd since it will be saved in
# fish_user_paths
if test -e "$GOPATH/bin"
  set -Ux fish_user_paths "$GOPATH/bin" 
end
if test -e "$CARGO_HOME/bin"
  set -Ux fish_user_paths "$CARGO_HOME/bin" 
end
if test -e "$LLVM_HOME/bin"
  set -Ux fish_user_paths "$LLVM_HOME/bin"
end
if test -e "$GOROOT/bin"
  set -Ux fish_user_paths "$GOROOT/bin"
end

type -q fd
if test $status -ne 0
  echoerr 'fd not found in PATH, fzf uses fd for default file find command'
end
###############################################################################
# Commenting below out for now since sourcing the conda script adds to fish shell
# init time and I am currently not using anaconda for python dev.
###############################################################################

# Init conda
# eval /usr/local/anaconda3/bin/conda "shell.fish" "hook" $argv | source

# Removes (base) from prompt
# conda deactivate
