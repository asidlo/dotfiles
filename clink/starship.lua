-- Async starship prompt for clink (cmd.exe).
-- Managed replacement for the stock `starship init cmd` output (starship 1.26.0).
-- Two intentional changes vs stock init:
--   1. :filter runs starship inside a clink prompt coroutine (io.popenyield) so the
--      prompt paints INSTANTLY from a cheap Lua placeholder; the real prompt (incl.
--      the git branch) fills in on the next repaint. This hides the intermittent
--      ~200ms cost of starship's git-repo open under Windows Defender real-time scan.
--   2. :rightfilter is removed. right_format is empty, so stock init spawned a second
--      starship.exe every prompt for zero output (~40ms wasted). If you ever add a
--      [right_format] to starship.toml, restore the rightfilter block from
--      `starship init cmd`.

if (clink.version_encoded or 0) < 10020030 then
  error("Starship requires a newer version of Clink; please upgrade to Clink v1.2.30 or later.")
end

-- Resolve starship once at load: prefer PATH (works for winget/scoop/custom
-- installs) and fall back to the default installer location. Quoted for spaces.
local function resolve_starship()
  local h = io.popen('where starship.exe 2>nul')
  if h then
    local p = h:read('*l')
    h:close()
    if p and p ~= '' then return '"' .. p .. '"' end
  end
  return [["C:\Program Files\starship\bin\starship.exe"]]
end

local STARSHIP = resolve_starship()

local starship_prompt = clink.promptfilter(5)

start_time = os.clock()
end_time = 0
curr_duration = 0
is_line_empty = true

clink.onbeginedit(function ()
  end_time = os.clock()
  if not is_line_empty then
    curr_duration = end_time - start_time
  end
end)

clink.onendedit(function (curr_line)
  if starship_precmd_user_func ~= nil then
    starship_precmd_user_func(curr_line)
  end
  start_time = os.clock()
  if string.len(string.gsub(curr_line, '^%s*(.-)%s*$', '%1')) == 0 then
    is_line_empty = true
  else
    is_line_empty = false
  end
end)

-- Instant placeholder shown until the async starship render completes.
-- Mirrors starship.toml: folder-only directory (bold cyan) then the character
-- glyph (bold green on success / bold red on error). \226\157\175 == U+276F "  ".
local function placeholder()
  local cwd = os.getcwd() or ""
  local folder = cwd:match("[^\\/]+[\\/]*$") or cwd
  folder = folder:gsub("[\\/]+$", "")
  local ch = (os.geterrorlevel() == 0)
    and "\027[1;32m\226\157\175\027[0m"
    or  "\027[1;31m\226\157\175\027[0m"
  return "\027[1;36m"..folder.."\027[0m\n"..ch.." "
end

function starship_prompt:filter(prompt)
  if starship_preprompt_user_func ~= nil then
    starship_preprompt_user_func(prompt)
  end
  local cmd = STARSHIP.." prompt"
    .." --status="..os.geterrorlevel()
    .." --cmd-duration="..math.floor(curr_duration*1000)
    .." --terminal-width="..console.getwidth()
    .." --keymap="..rl.getvariable('keymap')
  local result = clink.promptcoroutine(function ()
    local f = io.popenyield(cmd)
    if not f then return nil end
    local out = f:read("*a")
    f:close()
    return out
  end)
  if result == nil then
    return placeholder()
  end
  return result
end

if starship_transient_prompt_func ~= nil then
  function starship_prompt:transientfilter(prompt)
    return starship_transient_prompt_func(prompt)
  end
end

if starship_transient_rprompt_func ~= nil then
  function starship_prompt:transientrightfilter(prompt)
    return starship_transient_rprompt_func(prompt)
  end
end

local characterset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local randomkey = ""
math.randomseed(os.time())
for i = 1, 16 do
  local rand = math.random(#characterset)
  randomkey = randomkey..string.sub(characterset, rand, rand)
end

os.setenv('STARSHIP_SHELL', 'cmd')
os.setenv('STARSHIP_SESSION_KEY', randomkey)
