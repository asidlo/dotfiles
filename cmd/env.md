# Environment Variables

key   = `FZF_DEFAULT_COMMAND`

for powershell we would use $null for cmd nul
value = `git ls-files --cached --others --exclude-standard 2> $null | fd --type f --type l %FD_OPTS%`

key   = `FZF_DEFAULT_OPTS`
value = `--color=fg:-1,bg:-1,fg+:-1,bg+:-1,gutter:-1,hl:4,hl+:6,info:8,prompt:4,pointer:5,marker:2,spinner:8,header:8 --height 50% -1 --reverse --multi --inline-info --preview='bat.exe --color=always --style=numbers {}' --preview-window='right:hidden' --bind='F2:toggle-preview' --bind='ctrl-d:half-page-down' --bind='ctrl-u:half-page-up' --bind='ctrl-y:execute-silent(echo {+} | win32yank.exe -i)'`

key   = `FD_OPTS`
value = `--follow --exclude .git --exclude node_modules --exclude "*.class"`

key   = `FZF_CTRL_T_COMMAND`
value = `%FZF_DEFAULT_COMMAND%`

key   = `FZF_ALT_C_COMMAND`
value = `fd --type d %FD_OPTS%`

key   = `MANPAGER`
value = `%EDITOR% +Man!`

key   = `EDITOR`
value = `nvim`

key   = `VISUAL`
value = `%EDITOR%`

key   = `PROMPT`
value = `$E[36m%USERNAME%$E[0m$Sat$S$E[35m%COMPUTERNAME%$E[0m$Sin$S$E[34m$P$E[0m$_$G$S`
