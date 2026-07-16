-- zshify.lua — zsh-on-Windows quality-of-life for Clink (cmd.exe)
-- Provides: zoxide `z`/`zi` directory jumping, auto dir-tracking, and a small
-- set of modern-tool aliases (eza/bat/rg/fd). Pure Clink Lua, no registry/doskey,
-- so the whole thing lives in one file that can be symlinked from dotfiles.
--
-- API notes (Clink >= 1.x): os.getcwd/os.chdir/os.getenv, clink.onbeginedit,
-- clink.onfilterinput (return string=run it, ''=run nothing, nil=run original),
-- clink.argmatcher for Tab completion.

local function quote(s)
    return '"' .. tostring(s):gsub('"', '\\"') .. '"'
end

-- Escape arbitrary user input for cmd.exe. Double-quoting is NOT enough here:
-- cmd.exe doesn't honor backslash-escaped quotes, so an embedded `"` closes the
-- quote and re-enables metachar parsing (& | < > ...). Instead caret-escape every
-- cmd metacharacter (incl. `"` itself); carets are consumed by cmd and the char
-- is passed literally to the child. Spaces are left intact as token separators, so
-- `z foo bar` stays two zoxide keywords, not one phrase. (Paths use quote() — safe
-- because Windows filenames cannot contain `"`.)
local function esc_args(s)
    return (tostring(s):gsub('[&|<>()"%%!%^]', '^%0'))
end

-- Read one line of output from a command, trimmed. Returns nil on empty/failure.
local function popen_line(cmd)
    local h = io.popen(cmd .. ' 2>nul')
    if not h then return nil end
    local out = h:read('*l')
    h:close()
    if out and out ~= '' then return out end
    return nil
end

--------------------------------------------------------------------------------
-- zoxide: auto-track visited directories (only when cwd actually changes, to
-- avoid spawning a process on every prompt redraw).
--------------------------------------------------------------------------------
local last_cwd
clink.onbeginedit(function()
    local cwd = os.getcwd()
    if cwd and cwd ~= last_cwd then
        last_cwd = cwd
        os.execute('zoxide add ' .. quote(cwd) .. ' >nul 2>nul')
    end
end)

--------------------------------------------------------------------------------
-- Aliases: modern replacements. Only rewrite the leading interactive token —
-- batch files / scripts are unaffected (onfilterinput fires only for typed lines).
--------------------------------------------------------------------------------
local aliases = {
    ll   = 'eza -la --icons --group-directories-first',
    ls   = 'eza --icons --group-directories-first',
    la   = 'eza -a --icons --group-directories-first',
    lt   = 'eza --tree --level=2 --icons --group-directories-first',
    cat  = 'bat --paging=never',
    grep = 'rg',
    find = 'fd',
}

--------------------------------------------------------------------------------
-- Single input filter: aliases first, then zoxide z/zi. One handler keeps the
-- ordering deterministic regardless of Clink's multi-handler chaining rules.
--------------------------------------------------------------------------------
clink.onfilterinput(function(line)
    local first, rest = line:match('^%s*(%S+)%s*(.-)%s*$')
    if not first then return end

    -- alias expansion (leading token only)
    local repl = aliases[first]
    if repl then
        if rest ~= '' then repl = repl .. ' ' .. rest end
        return repl
    end

    -- zoxide jump
    if first == 'z' then
        if rest == '' then
            return 'cd /d ' .. quote(os.getenv('USERPROFILE') or os.getcwd())
        end
        local dir = popen_line('zoxide query -- ' .. esc_args(rest))
        if dir then return 'cd /d ' .. quote(dir) end
        return 'echo zoxide: no match for ' .. esc_args(rest)
    elseif first == 'zi' then
        -- interactive select (uses fzf via zoxide); result on stdout, UI on tty
        local dir = popen_line('zoxide query -i -- ' .. esc_args(rest))
        if dir then return 'cd /d ' .. quote(dir) end
        return '' -- cancelled: run nothing
    end
end)

--------------------------------------------------------------------------------
-- Tab completion for `z`: offer the zoxide database entries.
--------------------------------------------------------------------------------
clink.argmatcher('z'):addarg({ function()
    local t = {}
    local h = io.popen('zoxide query -l 2>nul')
    if h then
        for l in h:lines() do t[#t + 1] = l end
        h:close()
    end
    return t
end}):loop()
