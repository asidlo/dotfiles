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
set -l FD_OPTS                 "--follow --exclude .git --exclude node_modules"

# For large git projects, use git ls-files for everything else use fd
set -gx FZF_DEFAULT_COMMAND    "git ls-files --cached --others --exclude-standard | fd --type f --type l $FD_OPTS"
set -gx FZF_CTRL_T_COMMAND     $FZF_DEFAULT_COMMAND

# https://github.com/dracula/dracula-theme
# https://minsw.github.io/fzf-color-picker/
set -gx FZF_DEFAULT_OPTS       '--color=fg:#c2bebe,bg:#282a36,hl:#8be9fd' \
                               '--color=fg+:#f8f8f2,bg+:#282a36,hl+:#ff79c6' \
                               '--color=info:#bd93f9,prompt:#ff79c6,pointer:#ff79c6' \
                               '--color=marker:#50fa7b,spinner:#8be9fd,header:#f1fa8c'

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

# Aliases (-s write function to file...makes it have a more global scope)
alias cls "clear"
alias copy "pbcopy"
alias csv "column -t -s,"
alias md "mkdir -p"
alias cpi 'cp -i'
alias mvi 'mv -i'
alias rmi 'rm -i'
alias rd rmdir

# Abbreviations
abbr g 'git'
abbr py  'python'
abbr py3  'python3'
abbr conff "$EDITOR ~/.config/fish/config.fish"
abbr confe "$EDITOR ~/.vimrc"
abbr tree "tree -C"

if not set -q __FISH_CFG_INITIALIZED
  set -gx __FISH_CFG_INITIALIZED

  # Set user paths, could just be set via cmd since it will be saved in
  # fish_user_paths
  set -Ux fish_user_paths "$GOPATH/bin" "$CARGO_HOME/bin"

  # Init conda
  eval /usr/local/anaconda3/bin/conda "shell.fish" "hook" $argv | source

  # Removes (base) from prompt
  conda deactivate
end


