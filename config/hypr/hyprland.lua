-- Hyprland Configuration
-- https://wiki.hypr.land/Configuring/

-- ==================
-- STARTUP APPS
-- ==================
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("1password --silent")
    -- hypridle runs as a systemd user unit (see modules/linux.nix)
    -- polkit agent handled by home-manager (services.hyprpolkitagent)
    hl.exec_cmd("hyprsunset -t 4500")
    hl.exec_cmd("foot --title quake")
    hl.exec_cmd("wl-paste --watch cliphist store")
    -- Obsidian must be RUNNING for Sync to flow — Claude writes memory into
    -- the vault headlessly; this is what actually ships it to other devices.
    hl.exec_cmd("obsidian")
end)

-- ==================
-- ENVIRONMENT VARIABLES
-- ==================
-- GPU/driver-specific env (LIBVA_DRIVER_NAME etc.) is machine-local: the
-- identity repo's gpu.nix exports it via ~/.config/uwsm/env, which uwsm
-- sources before launching the compositor.

-- Without a theme Qt auto-picks gtk3, whose in-process file chooser aborts
-- on missing GSettings schemas (Okular SIGABRT on Open). The portal theme
-- ships with qtbase and delegates dialogs to xdg-desktop-portal-gtk.
hl.env("QT_QPA_PLATFORMTHEME", "xdgdesktopportal")

-- ==================
-- INPUT CONFIG
-- ==================
hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = true,
        kb_options         = "caps:ctrl_modifier",
        -- input.natural_scroll covers mice; the touchpad has its own knob
        -- and does not inherit it.
        natural_scroll     = true,
        touchpad = {
            natural_scroll = true,
            -- macOS-style clicking: one finger anywhere = left, two = right
            -- (three = middle, which macOS lacks). The alternative,
            -- button-areas, splits the bottom strip into fixed left/right
            -- zones whose boundary libinput does not let you move.
            -- Also makes physical clicks agree with taps, since tap_to_click
            -- already right-clicks on a two-finger tap.
            clickfinger_behavior = true,
        },
    },
})

hl.device({
    name           = "logitech-mx-master-3-1",
    natural_scroll = true,
})

-- ==================
-- GESTURES
-- ==================
-- Three-finger horizontal swipe changes workspace, as on macOS. This is
-- Hyprland 0.49+'s gesture system, not the old gestures:workspace_swipe
-- block. The swipe animates live and follows the finger, so it tracks the
-- workspace under your hand rather than firing once at the end.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Swipe sensitivity. distance is the finger travel (px) for a full workspace
-- change, so lower is more sensitive -- 300 is the default and felt like a lot
-- of trackpad. cancel_ratio is how far through you must get for it to commit
-- rather than snap back; 0.5 default, lowered to match.
hl.config({
    gestures = {
        workspace_swipe_distance     = 180,
        workspace_swipe_cancel_ratio = 0.35,
    },
})

-- Three-finger swipe down toggles DMS's workspace overview -- the same thing
-- SUPER+TAB does (dms/binds.lua), so this is a gesture onto an existing
-- action rather than a second implementation. Hyprland has no built-in
-- overview; the overview belongs to DMS, hence the IPC call.
hl.gesture({
    fingers   = 3,
    direction = "down",
    action    = function()
        hl.exec_cmd("dms ipc call hypr toggleOverview")
    end,
})

-- ==================
-- GENERAL LAYOUT
-- ==================
hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 5,
        border_size = 2,
        layout      = "dwindle",
    },
})

-- ==================
-- DECORATION
-- ==================
hl.config({
    decoration = {
        rounding         = 12,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 5,
            offset       = "0 5",
            color        = "rgba(00000070)",
        },
    },
})

-- ==================
-- ANIMATIONS
-- ==================
hl.config({
    animations = { enabled = true },
})

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "border",      enabled = true, speed = 3, bezier = "default" })

-- ==================
-- LAYOUTS
-- ==================
hl.config({
    dwindle = { preserve_split = true },
    master  = { mfact = 0.5 },
})

-- ==================
-- MISC
-- ==================
hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})

-- ==================
-- WINDOW RULES
-- ==================
hl.window_rule({ match = { class = "^(org\\.wezfurlong\\.wezterm)$" }, tile     = true })
hl.window_rule({ match = { class = "^(org\\.gnome\\.)" },              rounding = 12   })
hl.window_rule({ match = { class = "^(gnome-control-center)$" },       tile     = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" },                tile     = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },       tile     = true })
hl.window_rule({ match = { class = "^(gnome-calculator)$" },           float    = true })
hl.window_rule({ match = { class = "^(galculator)$" },                 float    = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" },            float    = true })
hl.window_rule({ match = { class = "^(org\\.gnome\\.Nautilus)$" },     float    = true })
hl.window_rule({ match = { class = "^(xdg-desktop-portal)$" },         float    = true })
hl.window_rule({ match = { class = "^(zoom)$" },                       float    = true })

hl.window_rule({
    match = { class = "^(steam)$", title = "^(notificationtoasts)" },
    pin   = true,
})

hl.window_rule({
    match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" },
    float = true,
})

-- DMS windows: Hyprland doesn't size these correctly so float is disabled
-- hl.window_rule({ match = { class = "^(org%.quickshell)$" }, float = true })

hl.layer_rule({
    match   = { namespace = "^(quickshell)$" },
    no_anim = true,
})

-- ==================
-- SPECIAL BINDS
-- ==================
hl.bind("SUPER + grave",     hl.dsp.workspace.toggle_special("quake"))
hl.bind("SUPER + backslash", hl.dsp.exec_cmd("1password --quick-access"))

-- Tab switching on ALT+SHIFT+[ / ]. Firefox's own shortcuts are not
-- user-configurable without an extension, so instead of rebinding Firefox we
-- translate the combo into the Ctrl+PageUp/PageDown it already understands,
-- via sendshortcut into the focused window.
--
-- Deliberately global rather than Firefox-only: Hyprland has no per-app binds,
-- and Ctrl+PageUp/Down is "previous/next tab" in most tabbed apps anyway. In a
-- terminal it may scroll instead -- harmless, but that is the trade.
-- Prior = PageUp, Next = PageDown.
hl.bind("ALT + SHIFT + bracketleft",
    hl.dsp.send_shortcut({ mods = "CTRL", key = "Prior", window = "activewindow" }))
hl.bind("ALT + SHIFT + bracketright",
    hl.dsp.send_shortcut({ mods = "CTRL", key = "Next", window = "activewindow" }))

-- ==================
-- SOURCED CONFIGS
-- ==================
-- outputs is machine-local (written by DMS, gitignored); a fresh machine
-- has no outputs file until monitors are configured in DMS.
pcall(require, "dms.outputs")
require("dms.layout")
-- colors was never wired up, so Hyprland borders ignored the DMS theme.
require("dms.colors")
require("dms.cursor")
require("dms.binds")
