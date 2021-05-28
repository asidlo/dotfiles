" Automatically generated packer.nvim plugin loader code

if !has('nvim-0.5')
  echohl WarningMsg
  echom "Invalid Neovim version for packer.nvim!"
  echohl None
  finish
endif

packadd packer.nvim

try

lua << END
  local time
  local profile_info
  local should_profile = false
  if should_profile then
    local hrtime = vim.loop.hrtime
    profile_info = {}
    time = function(chunk, start)
      if start then
        profile_info[chunk] = hrtime()
      else
        profile_info[chunk] = (hrtime() - profile_info[chunk]) / 1e6
      end
    end
  else
    time = function(chunk, start) end
  end
  
local function save_profiles(threshold)
  local sorted_times = {}
  for chunk_name, time_taken in pairs(profile_info) do
    sorted_times[#sorted_times + 1] = {chunk_name, time_taken}
  end
  table.sort(sorted_times, function(a, b) return a[2] > b[2] end)
  local results = {}
  for i, elem in ipairs(sorted_times) do
    if not threshold or threshold and elem[2] > threshold then
      results[i] = elem[1] .. ' took ' .. elem[2] .. 'ms'
    end
  end

  _G._packer = _G._packer or {}
  _G._packer.profile_output = results
end

time("Luarocks path setup", true)
local package_path_str = "/Users/asidlo/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?.lua;/Users/asidlo/.cache/nvim/packer_hererocks/2.1.0-beta3/share/lua/5.1/?/init.lua;/Users/asidlo/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?.lua;/Users/asidlo/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/luarocks/rocks-5.1/?/init.lua"
local install_cpath_pattern = "/Users/asidlo/.cache/nvim/packer_hererocks/2.1.0-beta3/lib/lua/5.1/?.so"
if not string.find(package.path, package_path_str, 1, true) then
  package.path = package.path .. ';' .. package_path_str
end

if not string.find(package.cpath, install_cpath_pattern, 1, true) then
  package.cpath = package.cpath .. ';' .. install_cpath_pattern
end

time("Luarocks path setup", false)
time("try_loadstring definition", true)
local function try_loadstring(s, component, name)
  local success, result = pcall(loadstring(s))
  if not success then
    print('Error running ' .. component .. ' for ' .. name)
    error(result)
  end
  return result
end

time("try_loadstring definition", false)
time("Defining packer_plugins", true)
_G.packer_plugins = {
  ReplaceWithRegister = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/ReplaceWithRegister"
  },
  dracula = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/dracula"
  },
  ["galaxyline.nvim"] = {
    config = { "require('config.statusline')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/galaxyline.nvim"
  },
  ["git-messenger.vim"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/git-messenger.vim"
  },
  ["lsp_extensions.nvim"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/lsp_extensions.nvim"
  },
  ["lspsaga.nvim"] = {
    config = { "require('config.lspsaga')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/lspsaga.nvim"
  },
  ["lua-dev.nvim"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/lua-dev.nvim"
  },
  ["nvim-compe"] = {
    config = { "require('config.compe')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/nvim-compe"
  },
  ["nvim-lspconfig"] = {
    config = { "require('config.lsp')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/nvim-lspconfig"
  },
  ["nvim-tree.lua"] = {
    config = { "require('config.tree')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/nvim-tree.lua"
  },
  ["nvim-treesitter"] = {
    config = { "require('config.treesitter')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/nvim-treesitter"
  },
  ["nvim-treesitter-textobjects"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/nvim-treesitter-textobjects"
  },
  ["nvim-web-devicons"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/nvim-web-devicons"
  },
  ["packer.nvim"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/packer.nvim"
  },
  ["plenary.nvim"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/plenary.nvim"
  },
  ["popup.nvim"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/popup.nvim"
  },
  ["snippets.nvim"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/snippets.nvim"
  },
  ["symbols-outline.nvim"] = {
    config = { "require('config.outline')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/symbols-outline.nvim"
  },
  tabular = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/tabular"
  },
  ["telescope.nvim"] = {
    config = { "require('config.telescope')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/telescope.nvim"
  },
  ["vim-bbye"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-bbye"
  },
  ["vim-commentary"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-commentary"
  },
  ["vim-dispatch"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-dispatch"
  },
  ["vim-fugitive"] = {
    config = { "require('config.fugitive')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-fugitive"
  },
  ["vim-gitgutter"] = {
    config = { "require('config.gitgutter')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-gitgutter"
  },
  ["vim-markdown"] = {
    config = { "require('config.markdown')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-markdown"
  },
  ["vim-obsession"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-obsession"
  },
  ["vim-repeat"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-repeat"
  },
  ["vim-rooter"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-rooter"
  },
  ["vim-surround"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-surround"
  },
  ["vim-symlink"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-symlink"
  },
  ["vim-unimpaired"] = {
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/vim-unimpaired"
  },
  ["which-key.nvim"] = {
    config = { "require('config.whichkey')" },
    loaded = true,
    path = "/Users/asidlo/.local/share/nvim/site/pack/packer/start/which-key.nvim"
  }
}

time("Defining packer_plugins", false)
-- Config for: vim-gitgutter
time("Config for vim-gitgutter", true)
require('config.gitgutter')
time("Config for vim-gitgutter", false)
-- Config for: lspsaga.nvim
time("Config for lspsaga.nvim", true)
require('config.lspsaga')
time("Config for lspsaga.nvim", false)
-- Config for: galaxyline.nvim
time("Config for galaxyline.nvim", true)
require('config.statusline')
time("Config for galaxyline.nvim", false)
-- Config for: which-key.nvim
time("Config for which-key.nvim", true)
require('config.whichkey')
time("Config for which-key.nvim", false)
-- Config for: telescope.nvim
time("Config for telescope.nvim", true)
require('config.telescope')
time("Config for telescope.nvim", false)
-- Config for: vim-markdown
time("Config for vim-markdown", true)
require('config.markdown')
time("Config for vim-markdown", false)
-- Config for: vim-fugitive
time("Config for vim-fugitive", true)
require('config.fugitive')
time("Config for vim-fugitive", false)
-- Config for: nvim-tree.lua
time("Config for nvim-tree.lua", true)
require('config.tree')
time("Config for nvim-tree.lua", false)
-- Config for: nvim-compe
time("Config for nvim-compe", true)
require('config.compe')
time("Config for nvim-compe", false)
-- Config for: nvim-treesitter
time("Config for nvim-treesitter", true)
require('config.treesitter')
time("Config for nvim-treesitter", false)
-- Config for: symbols-outline.nvim
time("Config for symbols-outline.nvim", true)
require('config.outline')
time("Config for symbols-outline.nvim", false)
-- Config for: nvim-lspconfig
time("Config for nvim-lspconfig", true)
require('config.lsp')
time("Config for nvim-lspconfig", false)
if should_profile then save_profiles() end

END

catch
  echohl ErrorMsg
  echom "Error in packer_compiled: " .. v:exception
  echom "Please check your config for correctness"
  echohl None
endtry
