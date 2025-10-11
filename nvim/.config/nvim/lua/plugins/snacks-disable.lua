-- Disable snacks.nvim plugin that causes treesitter query errors
-- This is the proper way to disable a plugin in LazyVim
return {
  "snacks.nvim",
  enabled = false, -- Completely disable this plugin
}