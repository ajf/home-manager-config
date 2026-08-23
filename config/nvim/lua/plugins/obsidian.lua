-- Only register vaults that exist on this machine; obsidian.nvim errors if
-- configured with zero valid workspaces.
local candidates = {
    { name = "personal", path = "~/Documents/personal" },
    { name = "work", path = "~/Documents/work" },
}

local workspaces = {}
for _, ws in ipairs(candidates) do
    if vim.fn.isdirectory(vim.fn.expand(ws.path)) == 1 then
        table.insert(workspaces, ws)
    end
end

if #workspaces > 0 then
    require("obsidian").setup({
        legacy_commands = false,
        workspaces = workspaces,
    })
end
