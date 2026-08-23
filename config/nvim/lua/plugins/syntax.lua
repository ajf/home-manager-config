-- Grammars come precompiled from nix (nvim-treesitter.withAllGrammars),
-- so no runtime install() here.

vim.api.nvim_create_autocmd('FileType', {
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
