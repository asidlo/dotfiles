-- Setup nvim-cmp.
local M = {}

M.config = function(opts)
  opts = opts or {}
  local defaults = {
    check_ts = true,
    ts_config = {
      lua = { "string", "source" },
      javascript = { "string", "template_string" },
      java = false,
    },
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    fast_wrap = {
      map = "<M-e>",
      chars = { "{", "[", "(", '"', "'" },
      pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
      offset = 0, -- Offset from pattern match
      end_key = "$",
      keys = "qwertyuiopzxcvbnmasdfghjkl",
      check_comma = true,
      highlight = "PmenuSel",
      highlight_grey = "LineNr",
    },
  }
  return vim.tbl_deep_extend('force', defaults, opts)
end

M.repo = "windwp/nvim-autopairs"

M.requires = {
  'hrsh7th/nvim-cmp',
}

M.setup = function(cfg)
  cfg = cfg or M.config()

  local required = {
    'cmp',
    'nvim-autopairs',
    'nvim-autopairs.completion.cmp',
  }

  local plugins = {}
  for _, req in ipairs(required) do
    local ok, plug = pcall(require, req)
    if not ok then
      return
    end
    plugins[req] = plug
  end

  plugins['nvim-autopairs'].setup(cfg)

  local cmp = plugins['cmp']
  local cmp_autopairs = plugins['nvim-autopairs.completion.cmp']
  cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done { map_char = { tex = "" } })
end

M.use = function(cfg)
  return {
    M.repo,
    config = M.setup(cfg),
    requires = M.requires,
  }
end

return M
