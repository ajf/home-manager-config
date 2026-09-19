-- Bridge: apply DMS's generated section-style .conf files through hl.config().
--
-- Same root cause as dms/outputs.lua: DMS 1.4.6 writes plain Hyprland .conf
-- for its layout and theme output, but hyprland.lua is the active config, so
-- the `source =` lines in hyprland.conf are never read. This parses those
-- .conf files and replays them as nested hl.config() tables.
--
-- Handles: `$var = value` definitions and substitution, nested `section { }`
-- blocks, and dotted keys (`col.active_border` -> general.col.active_border).
--
-- Nothing here is hand-edited. Change things in DMS, then `hyprctl reload`.

local M = {}

-- `debug` may not be exposed in the config sandbox; fall back to $HOME.
local ok, dir = pcall(function()
    return debug.getinfo(1, "S").source:match("^@(.*)/")
end)
if not ok or not dir then
    dir = (os.getenv("HOME") or "") .. "/.config/hypr/dms"
end

-- "4" -> 4, "true" -> true; colors like "rgb(d0bcff)" stay strings.
local function coerce(raw)
    local v = raw:match("^%s*(.-)%s*$")
    if v == "true" then return true end
    if v == "false" then return false end
    return tonumber(v) or v
end

local function subst(s, vars)
    return (s:gsub("%$([%w_]+)", function(name)
        local hit = vars[name]
        if hit == nil then return "$" .. name end
        return tostring(hit)
    end))
end

-- "col.active_border" under {general} -> general.col.active_border
local function set_path(node, dotted, value)
    local parts = {}
    for part in dotted:gmatch("[^.]+") do
        parts[#parts + 1] = part
    end
    if #parts == 0 then return end

    local cursor = node
    for i = 1, #parts - 1 do
        local key = parts[i]
        if type(cursor[key]) ~= "table" then cursor[key] = {} end
        cursor = cursor[key]
    end
    cursor[parts[#parts]] = value
end

--- Parse a DMS-generated .conf into a nested table. Returns nil if absent.
function M.load(filename)
    local fh = io.open(dir .. "/" .. filename, "r")
    if not fh then return nil end

    local root = {}
    local stack = { root }
    local vars = {}

    for raw in fh:lines() do
        local line = raw:match("^%s*(.-)%s*$")
        local top = stack[#stack]

        if line == "" or line:sub(1, 1) == "#" then
            -- comment or blank

        elseif line:sub(1, 1) == "$" then
            local name, value = line:match("^%$([%w_]+)%s*=%s*(.+)$")
            if name then vars[name] = coerce(subst(value, vars)) end

        elseif line:sub(-1) == "{" then
            local name = line:match("^([%w_%-%.]+)%s*{$")
            if name then
                local child = {}
                set_path(top, name, child)
                stack[#stack + 1] = child
            else
                -- Unrecognised block header: push a scratch table so its
                -- body doesn't leak into the enclosing section.
                stack[#stack + 1] = {}
            end

        elseif line:sub(1, 1) == "}" then
            if #stack > 1 then stack[#stack] = nil end

        else
            local key, value = line:match("^([%w_%-%.]+)%s*=%s*(.*)$")
            if key then set_path(top, key, coerce(subst(value, vars))) end
        end
    end

    fh:close()
    return root
end

--- Parse and apply a DMS-generated .conf. Returns the table it applied.
function M.apply(filename)
    local cfg = M.load(filename)
    if cfg and next(cfg) ~= nil then hl.config(cfg) end
    return cfg
end

return M
