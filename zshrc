# Author  : Andrew Sidlo
# Modified: 2019-07-09

#==============================================================================
# ZSH CONFIG {{{
#==============================================================================
# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# }}}
#==============================================================================
# SDKMAN {{{
#==============================================================================
# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/asidlo/.sdkman"
[[ -s "/Users/asidlo/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/asidlo/.sdkman/bin/sdkman-init.sh"

# }}}
#==============================================================================
# FUNCTIONS {{{
#==============================================================================
function get_go_version {
    if [ -x "$(command -v go)" ]; then
        go version | cut -d' ' -f3 | sed 's/go//g'
    else
        printf "Go executable not found in path, cannot determine version for GOROOT" >&2
    fi
}

# }}}
#==============================================================================
# ENV VARS {{{
#==============================================================================
# Useful, but is setup now to always be in some sort of virtualenv via pyenv
# and also is buggy when using conda based environments
export PIP_REQUIRE_VIRTUALENV=true
export VIRTUAL_ENV_DISABLE_PROMPT=1
export HISTFILESIZE=100000
export HISTSIZE=100000
export HISTTIMEFORMAT="%h %d %H:%M:%S - "
export GRADLE_OPTS=-Xmx4096m
export GOPATH=~/Documents/workspace/go
export GOROOT=/usr/local/Cellar/go/$(get_go_version)/libexec
export LESS="-F -X $LESS"
export SCRIPTS_HOME="/Users/asidlo/Documents/Workspace/scripts"
export VISUAL=nvim
export EDITOR="$VISUAL"
export LLVM_HOME=/usr/local/Cellar/llvm/8.0.0_1
export PATH=$PATH:$GOPATH/bin:$LLVM_HOME/bin

# }}}
#==============================================================================
# ALIASES {{{
#==============================================================================
# MISC {{{
#==============================================================================
alias cls=clear
alias vi=vim
alias copy=pbcopy
alias csv="column -t -s,"
alias zshrc='${=EDITOR} ~/.zshrc'
alias grep='grep  --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn}'
alias tree="tree -C"
alias cal='cal -3'


# }}}
#==============================================================================
# DOCKER {{{
#==============================================================================
alias dm="docker-machine"
alias dc='docker-compose'

# }}}
#==============================================================================
# FILE {{{
#==============================================================================
alias md="mkdir -p"
alias mv='mv -i'

alias rd=rmdir
alias rm='rm -i'

alias cp='cp -i'

alias l='ls -lFh'
alias lS='ls -1FSsh'
alias la='ls -lAFh'
alias lart='ls -1Fcart'
alias ldot='ls -ld .*'
alias ll='ls -l'
alias lr='ls -tRFh'
alias lrt='ls -1Fcrt'
alias ls='ls -G'
alias lsa='ls -lah'
alias lt='ls -ltFh'
alias ldir="ls -d */"

alias d='dirs -v | head -10'

alias fd='find . -type d -name'
alias ff='find . -type f -name'

# }}}
#==============================================================================
# GIT {{{
#==============================================================================
for git_alias in $(git --list-cmds=alias); do
    alias g$git_alias="git $git_alias"
done

function extract_git_aliases() {
    local git_aliases=(`git --list-cmds=alias`)
    echo "Alias,Command"
    echo "-----,--------------------------------------------------------------------------------"
    for a in $git_aliases; do
        # Trim the desc for pretty output print
        local cmd=$(git config -l | grep "alias.$a=" | cut -d= -f2- | cut -c 1-80)
        echo "$a,$cmd"
    done
}

alias gla="extract_git_aliases | column -t -s,"
alias gal="extract_git_aliases | column -t -s,"

# }}}
# vim:foldmethod=marker
