# Environment Variables

key   = `FZF_DEFAULT_COMMAND`

for powershell we would use $null for cmd nul
value = `git ls-files --cached --others --exclude-standard 2> $null | fd --type f --type l %FD_OPTS%`

key   = `FZF_DEFAULT_OPTS`
value = `--color=fg:#c2bebe,bg:-1,hl:#8be9fd --color=fg+:#f8f8f2,bg+:-1,hl+:#ff79c6 --color=info:#bd93f9,prompt:#ff79c6,pointer:#ff79c6 --color=marker:#50fa7b,spinner:#8be9fd,header:#f1fa8c --height 50% -1 --reverse --multi --inline-info --preview='bat.exe --color=always --style=numbers {}' --preview-window='right:hidden' --bind='F2:toggle-preview' --bind='ctrl-d:half-page-down' --bind='ctrl-u:half-page-up' --bind='ctrl-y:execute-silent(echo {+} | win32yank.exe -i)'`

key   = `FD_OPTS`
value = `--follow --exclude .git --exclude node_modules --exclude "*.class"`

key   = `FZF_CTRL_T_COMMAND`
value = `%FZF_DEFAULT_COMMAND%`

key   = `FZF_ALT_C_COMMAND`
value = `fd --type d %FD_OPTS%`
