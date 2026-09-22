-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- HYPRLAND CONFIG (Lua)                                 --
-- Converted from hyprland.conf; hyprlang version is     --
-- kept alongside as a fallback -- Hyprland only reads it --
-- when no hyprland.lua is present.                      --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")

local home = os.getenv("HOME")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({ output = "",      mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.25 })


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "ghostty"
local fileManager = "nautilus"
local menu        = "wofi --show drun"
-- local screenLock  = "hyprlock" -- superseded by the shell's lock (CTRL+ALT+L);
                                  -- hyprlock is still installed as a fallback


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")

    -- Dynamite V3 (Quickshell): island/bar, launcher, control centre, notifications,
    -- OSDs, power menu, lock screen, polkit agent, theme + wallpaper pickers.
    -- It renders the wallpaper itself on a background layer, so no hyprpaper here.
    hl.exec_cmd("qs")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Theme colours from wallust, rewritten by ~/.config/wallust/theme-apply.sh on
-- every theme switch; that file sets a global `colors` table. The require is
-- guarded: on a fresh machine the file does not exist yet, and an unguarded
-- failure would abort this whole config and drop Hyprland into emergency mode
-- (SUPER+Q as the only bind). Falls back to the Tokyo Night Storm values used
-- before wallust.
local okColors = pcall(require, "colors.custom.wallust")
local palette  = okColors and colors or nil

-- wallust emits "rgb(RRGGBB)"; borders want alpha, so re-wrap as rgba(RRGGBBAA).
local function border(name, alpha, fallback)
    local hex = palette and palette[name] and palette[name]:match("rgb%((%x+)%)")
    return hex and ("rgba(" .. hex .. alpha .. ")") or fallback
end

-- Neutral on purpose: taken from the palette's grey ramp, not its accent, so
-- borders follow the theme's lightness without adding a colour cast.
-- Alpha is hex: 99 = 60%, 66 = 40%.
-- bg4 is the palette's own "lighter shade for borders" -- a step above the
-- background rather than a foreground grey, so the edge reads as depth instead
-- of a highlight. Alpha is hex: 99 = 60%, 66 = 40%.
local activeBorder   = border("bg4", "99", "rgba(565f8999)")
local inactiveBorder = border("bg2", "66", "rgba(565f8966)")

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 12,

        border_size = 1,

        -- Borders follow the active wallust theme (see `border` above).
        col = {
            active_border   = activeBorder,
            inactive_border = inactiveBorder,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.90,
        inactive_opacity = 0.60,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a, -- was rgba(1a1a1aee)
        },

        -- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
        blur = {
            enabled = true,
            size    = 15, -- Higher size = more blur but more GPU usage
            passes  = 3,  -- More passes = better quality but more GPU usage

            vibrancy          = 0.5,
            vibrancy_darkness = 0.2,

            popups = true, -- blur popups/menus too, to match the window blur
        },
    },

    cursor = {
        no_hardware_cursors = true,
    },

    animations = {
        enabled = true,
    },
})

-- Curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

-- Upstream's default spring, used for window open/movement only
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
-- NOTE: dwindle.pseudotile was removed in Hyprland 0.56; pseudotiling is now
-- only the `pseudo` dispatcher, bound to SUPER + P below.
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
        force_split    = 2,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


-------------------
---- XWAYLAND ----
-------------------

-- Render XWayland apps at native scale instead of letting the compositor
-- upscale them; with scale = 1.25 above, that upscale is what makes X11
-- windows look soft. No effect on native Wayland clients.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})


---------------
---- INPUT ----
---------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
    input = {
        kb_layout  = "de",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity    = 0,      -- -1.0 - 1.0, 0 means no modification.
        accel_profile  = "flat", -- adaptive or flat
        force_no_accel = false,

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Basics/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Per-device sensitivity settings
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({ name = "synps/2-synaptics-touchpad", sensitivity = 1 })
hl.device({ name = "keychron-keychron-m3-",      sensitivity = 0.1 })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Return",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())
hl.bind(mainMod .. " + M",           hl.dsp.exit())
hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F",           hl.dsp.window.float({ action = "toggle" }))

-- The shell's launcher replaces the Omarchy menu (and wofi before it). `menu`
-- is left defined above so `wofi --show drun` stays a one-line revert.
hl.bind(mainMod .. " + SPACE",       hl.dsp.global("quickshell:launcher"))

hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo())
-- hl.bind(mainMod .. " + J",        hl.dsp.layout("togglesplit")) -- dwindle

-- Universal copy/paste/cut: works in normal windows and in terminals, where the
-- script swaps in Ctrl+Insert / Shift+Insert so Ctrl+C keeps interrupting.
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(home .. "/.local/bin/universal-clipboard copy"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(home .. "/.local/bin/universal-clipboard paste"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(home .. "/.local/bin/universal-clipboard cut"))

-- Shell panels. Everything here except the control centre is registered by the
-- shell as a GlobalShortcut, so it goes through hl.dsp.global; the control
-- centre has none, so it is driven over IPC (the island's pill also opens it).
hl.bind(mainMod .. " + T",           hl.dsp.global("quickshell:theme"))
hl.bind(mainMod .. " + SHIFT + T",   hl.dsp.global("quickshell:wallpaper"))
hl.bind(mainMod .. " + SHIFT + C",   hl.dsp.global("quickshell:calendar"))
hl.bind(mainMod .. " + comma",       hl.dsp.global("quickshell:settings"))
hl.bind(mainMod .. " + N",           hl.dsp.global("quickshell:nightlight"))
hl.bind(mainMod .. " + G",           hl.dsp.global("quickshell:gamemode"))
hl.bind(mainMod .. " + A",           hl.dsp.exec_cmd("qs ipc call controlcenter toggle"))

-- Session control. The shell owns the lock screen now (WlSessionLock + PAM),
-- so hyprlock is unbound but still installed.
-- Power menu (lock / logout / reboot / shutdown). On the German layout `Entf`
-- IS the Delete keysym, so CONTROL+ALT+Entf works; SUPER+Backspace is the
-- easier one-hand alternative.
hl.bind(mainMod .. " + BackSpace",   hl.dsp.global("quickshell:logout"))
hl.bind(mainMod .. " + L",           hl.dsp.global("quickshell:lock"))
hl.bind("CONTROL + ALT + Delete",    hl.dsp.global("quickshell:logout"))
-- NOTE: on the `de` layout only the LEFT Alt is Alt_L; the right one is AltGr
-- (ISO_Level3_Shift), so Ctrl + right-Alt + L can never match this bind.
hl.bind("CONTROL + ALT + L",         hl.dsp.global("quickshell:lock"))

-- Window management is on the arrow keys, which leaves h/j/k/l free.
-- Move focus with mainMod + arrows
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + arrows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + TAB",         hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "-1" }))

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize windows with mainMod + ALT + arrows
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.resize({ x = -40, y = 0 }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 40,  y = 0 }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.resize({ x = 0,   y = -40 }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.resize({ x = 0,   y = 40 }))

-- Laptop multimedia keys for volume and LCD brightness
-- Volume and brightness run inside the shell (smooth on key repeat, and they
-- drive its OSD), so these are GlobalShortcuts rather than shell-outs.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.global("quickshell:volumeUp"),      { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.global("quickshell:volumeDown"),    { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.global("quickshell:volumeMute"),    { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.global("quickshell:brightnessUp"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("quickshell:brightnessDown"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Waybar blur
-- hl.layer_rule({ name = "blur-waybar", match = { namespace = "waybar" }, blur = true, ignore_alpha = 1 })

-- Example windowrule
-- hl.window_rule({ name = "float-kitty", match = { class = "^(kitty)$", title = "^(kitty)$" }, float = true })

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})
