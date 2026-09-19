-- Replays DMS's generated layout.conf via hl.config().
--
-- DMS 1.4.6 writes layout.conf (gaps / border_size / rounding, driven by the
-- bar spacing setting) and has no Lua writer, so the previous hand-generated
-- Lua here went stale. See dms/confbridge.lua.

require("dms.confbridge").apply("layout.conf")
