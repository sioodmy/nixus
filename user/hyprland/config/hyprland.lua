-- ---------------------------------------------------------------------------
-- hyprland.lua — entry point
--
-- Hyprland 0.55 deprecated hyprlang in favour of Lua. Everything else lives in
-- conf.d/ and is pulled in with a globbed require(), which expands in
-- sorted order, so the numeric prefixes control evaluation order.
--
-- The files are symlinked into ~/.config/hypr by the `homix` module
-- (user/hyprland), which keeps them readable and lintable in the repo.
-- ---------------------------------------------------------------------------

-- The glob form only kicks in for explicit relative paths, so the "./" prefix
-- is load-bearing. Files expand in sorted order, so the numeric prefixes on the
-- filenames control evaluation order. Only .lua files are matched so non-Lua
-- files (e.g. legacy configs or editor backups) are ignored.
require("./conf.d/*.lua")
