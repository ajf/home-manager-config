-- Hyprland Configuration
-- https://wiki.hypr.land/Configuring/

-- ==================
-- STARTUP APPS
-- ==================
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("1password --silent")
    -- Tray-only autostarts. Each was verified to register a StatusNotifierItem
    -- without mapping a window, so none of them flashes a window on login:
    -- Signal needs the flag, the other two do it by default.
    --
    -- Cider is deliberately NOT here. It cannot start hidden: there is no
    -- --hidden/--start-in-tray flag in its asar, spa-config.yml has only
    -- closeToTray (no start-minimized key), and window_state.json persists
    -- size and position but no hidden state. The only way to land it in the
    -- tray is to let the window map and then close it, which means several
    -- seconds of visible window on every login -- not worth it for a music
    -- player. closeToTray keeps it resident once opened by hand.
    hl.exec_cmd("signal-desktop --start-in-tray")
    -- Tailscale tray. tailscaled's OperatorUser is andrew, so its menu can
    -- bring the tunnel up and down without asking for root.
    hl.exec_cmd("tail-tray")
    -- iPhone bridge. tether-gtk is the tray client and spawns tetherd itself
    -- when none is running, so there is no separate daemon to start -- see the
    -- comments in the package's own tetherd.service. The binary comes from the
    -- system closure (NixOS), not from this repo.
    hl.exec_cmd("tether-gtk")
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
-- XWAYLAND
-- ==================
-- On a fractionally scaled output (eDP-1 runs at 1.25) Hyprland renders X11
-- clients at scale 1 and then upscales the finished surface, resampling
-- glyphs that were already rasterized -- text comes out grainy with uneven
-- kerning. force_zero_scaling hands XWayland the native pixel grid instead,
-- so those clients rasterize at full density and nothing is stretched.
--
-- The tradeoff is that X11 clients no longer learn the output scale and lay
-- out too small; each one needs its toolkit told by hand. VLC is the only
-- XWayland client here and carries QT_SCALE_FACTOR in its wrapper -- see
-- vlc' in the dotfiles' modules/linux.nix. Anything X11 added later will
-- need the same treatment.
--
-- This is a no-op on outputs at scale 1, where there is no upscale to avoid.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

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

-- Moonlander (QMK): the firmware owns its own caps mapping, so the global
-- caps:ctrl_modifier must not be layered on top of it. Empty kb_options
-- overrides the global value for this device only.
--
-- Two blocks because the board exposes two typing endpoints: the 6KRO boot
-- keyboard (interface 1.0) and the NKRO one (interface 1.2). Both report
-- `keyboard` to libinput and both would otherwise inherit the global options.
-- Its System Control and Consumer Control nodes send power and media keys
-- rather than characters, so they need nothing.
hl.device({
    name       = "zsa-technology-labs-moonlander-mark-i",
    kb_options = "",
})

hl.device({
    name       = "zsa-technology-labs-moonlander-mark-i-keyboard",
    kb_options = "",
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
-- Everything DMS generates is gitignored, so a fresh checkout has none of it
-- until DMS has run once — hence pcall rather than require. A hard require
-- here would abort the whole config and leave a new machine with no desktop
-- at all. DMS writes these as native Lua since 1.6.3 and reloads Hyprland
-- itself, so they appear moments into the first session.
pcall(require, "dms.outputs")
pcall(require, "dms.layout")
pcall(require, "dms.colors")
pcall(require, "dms.cursor")
pcall(require, "dms.windowrules")

-- Hand-written, always present: keep this one a hard require so a genuine
-- mistake in it is loud rather than silently dropping every keybind.
require("dms.binds")
