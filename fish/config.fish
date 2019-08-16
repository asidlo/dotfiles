# Installs fisher on startup if not already installed
if not functions -q fisher
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    curl https://git.io/fisher --create-dirs -sLo $XDG_CONFIG_HOME/fish/functions/fisher.fish
    fish -c fisher
end


# Remove fish greeting
set fish_greeting

# Show all hidden files and files that are being ignored by vcs
# https://sidneyliebrand.io/blog/how-fzf-and-ripgrep-improved-my-workflow?source=post_page---------------------------
# set -gx FZF_DEFAULT_COMMAND    'rg --files --no-ignore-vcs --hidden'
set -gx FZF_DEFAULT_COMMAND    'fd --type f --color=never'
set -gx FZF_DEFAULT_OPTS       '--color fg:188,bg:233,hl:103,fg+:222,bg+:234,hl+:104' \
                               '--color info:183,prompt:110,spinner:107,pointer:167,marker:215'
set -gx LPS_DEFAULT_USERNAME   'sidlo.andrew@gmail.com'
set -gx VISUAL                 nvim
set -gx EDITOR                 nvim
set -gx GOPATH                 ~/Documents/workspace/go
set -gx GOROOT                 /usr/local/Cellar/go/*/libexec
set -gx FISH_HOME              ~/.config/fish
set -gx FISH_FUNCS             $FISH_HOME/functions
set -gx CARGO_HOME             ~/.cargo
set -gx LLVM_HOME              /usr/local/opt/llvm
set -gx LDFLAGS                "-L/usr/local/opt/llvm/lib"
set -gx CPPFLAGS               "-I/usr/local/opt/llvm/include"
set -gx ANACONDA_HOME          /usr/local/anaconda3
set -gx DOTDIR                 ~/Documents/dotfiles
set -gx PIP_REQUIRE_VIRTUALENV true

# Add global go bin and local bin to path
# set -x PATH "$LLVM_HOME/bin" $PATH "$GOROOT/bin" "$GOPATH/bin" "$CARGO_HOME/bin"
set -Ux fish_user_paths "$GOPATH/bin" "$CARGO_HOME/bin"

# Aliases (-s write function to file...makes it have a more globa scope)
alias cls "clear"
alias copy "pbcopy"
alias csv "column -t -s,"
alias md "mkdir -p"
alias mv 'mv -i'
alias rd rmdir
alias rm 'rm -i'
alias cp 'cp -i'

# Abbreviations
abbr g 'git'
abbr py  'python'
abbr py3  'python3'
abbr conff "$EDITOR ~/.config/fish/config.fish"
abbr confe "$EDITOR ~/.vimrc"
abbr tree "tree -C"

if not set -q __FISH_CFG_INITIALIZED
  set -gx __FISH_CFG_INITIALIZED

  # Init conda
  eval /usr/local/anaconda3/bin/conda "shell.fish" "hook" $argv | source

  # Removes (base) from prompt
  conda deactivate
end


