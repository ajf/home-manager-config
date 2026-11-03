-- Vaults live under ~/notes (modules/obsidian.nix seeds the app's registry for
-- ~/notes/personal; a machine with no Obsidian app keeps one in sync with the
-- headless client, modules/obsidian-sync.nix).
--
-- Only register vaults that exist on this machine; obsidian.nvim errors if
-- configured with zero valid workspaces.
local candidates = {
    { name = "personal", path = "~/notes/personal" },
    { name = "work", path = "~/notes/work" },
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

        -- The plugin's defaults suit a zettelkasten; the vaults here are written
        -- in the Obsidian app and by hand, so match what the app itself does or
        -- the two editors fight over the same files (and Sync carries the mess).

        -- Readable filenames ("CNC - PR Aggregation.md"), not 1657296016-ABC.
        -- Only the characters Obsidian itself forbids in a title are dropped.
        note_id_func = function(title)
            if title and title ~= "" then
                local id = title:gsub('[\\/:*?"<>|#^%[%]]', "")
                id = id:gsub("^%s+", "")
                id = id:gsub("%s+$", "")
                if id ~= "" then
                    return id
                end
            end
            return os.date("%Y-%m-%d-%H%M%S")
        end,

        -- Notes carry no frontmatter unless written by hand (3 of 31 in work),
        -- and the plugin would otherwise stamp id/aliases/tags into every note
        -- it saves.
        frontmatter = { enabled = false },

        -- Daily notes are YYYY-MM-DD.md at the vault root, every day, with no
        -- tag: the app's defaults. (The plugin skips weekends and tags them.)
        daily_notes = { default_tags = {}, workdays_only = false },

        -- Pasted images go to the vault root, as the app does. A folder starting
        -- with "." would mean "beside the current note", so use "".
        attachments = { folder = "" },
    })

    -- obsidian.nvim wants conceallevel 1 or 2 to render links and checkboxes,
    -- and warns if it is not set by the time it checks. FileType runs ahead of
    -- that (its own ObsidianNoteEnter does not), and only inside a vault, so
    -- other markdown files keep their raw syntax.
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev)
            local file = vim.fn.fnamemodify(ev.file, ":p")
            for _, ws in ipairs(workspaces) do
                if vim.startswith(file, vim.fn.expand(ws.path) .. "/") then
                    vim.opt_local.conceallevel = 2
                    return
                end
            end
        end,
    })

    -- Leader is ",". Inside a note, <CR> follows the link under the cursor (or
    -- toggles a checkbox) and ]o / [o jump between links; those are the plugin's.
    local map = function(lhs, cmd, desc)
        vim.keymap.set("n", "<Leader>" .. lhs, "<Cmd>Obsidian " .. cmd .. "<CR>", { desc = "Obsidian: " .. desc })
    end
    map("oo", "quick_switch", "open note by name")
    map("os", "search", "search note contents")
    map("on", "new", "new note")
    map("od", "today", "today's daily note")
    map("ob", "backlinks", "backlinks to this note")
    map("ow", "workspace", "switch vault")
end
