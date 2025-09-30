-- Bootstrap mini.deps
-- Compatibility: Older Neovim versions (<0.10) don't support stdpath('log')
-- Check if we need to add a fallback
local has_log_stdpath = pcall(vim.fn.stdpath, 'log')
if not has_log_stdpath then
  -- Monkey-patch stdpath to support 'log' for older Neovim versions
  local original_stdpath = vim.fn.stdpath
  vim.fn.stdpath = function(what)
    if what == 'log' then
      return original_stdpath('data')
    end
    return original_stdpath(what)
  end
end

-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/nvim-mini/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
-- Use stdpath('data') for log to support older Neovim versions (pre-0.10)
require('mini.deps').setup({
  path = {
    package = path_package,
    snapshot = vim.fn.stdpath('config') .. '/mini-deps-snap',
    log = vim.fn.stdpath('data') .. '/mini-deps.log',
  }
})

-- Helper for adding plugins
local add = require('mini.deps').add

-- Add Catppuccin theme
add({ source = "catppuccin/nvim", name = "catppuccin" })

-- Set the colorscheme
vim.cmd('colorscheme catppuccin-mocha')

-- Basic Neovim settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true
