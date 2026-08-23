vim.g.mapleader = ","

-- Plugins are provided by home-manager (programs.neovim.plugins in
-- modules/neovim.nix); this file is inlined into the generated init.lua.

require("plugins.util")
require("plugins.lsp")
require("plugins.completion")
require("plugins.syntax")
require("plugins.rust")
require("plugins.ui")
require("plugins.obsidian")
require("lsp")
require("customization")
