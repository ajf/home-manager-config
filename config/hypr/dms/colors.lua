-- Replays DMS's generated colors.conf via hl.config().
--
-- DMS 1.4.6 writes colors.conf (matugen theme output) and has no Lua writer,
-- so the previous hand-generated Lua here went stale. See dms/confbridge.lua.

require("dms.confbridge").apply("colors.conf")
