local wezterm = require('wezterm')

config = wezterm.config_builder()

config.font_size = 14.0
config.allow_square_glyphs_to_overflow_width = 'WhenFollowedBySpace'
config.color_scheme = 'tokyonight_moon'

config.colors = {
    cursor_bg = '#c099ff',
    tab_bar = {
        active_tab = {
            bg_color = '#82aaff',
            fg_color = '#404d5f',
        },
        inactive_tab = {
            bg_color = '#444a73',
            fg_color = '#ddd',
        },
        new_tab = {
            bg_color = '#444a73',
            fg_color = '#ddd',
        },
    },
}

config.enable_wayland = false
config.front_end = 'OpenGL'
-- config.window_background_opacity = .65
-- config.macos_window_background_blur = 20

config.warn_about_missing_glyphs = true

-- try to map some shortcuts on Linux to be more like macOS defaults.
config.keys = {
    {
        key = '[',
        mods = 'CTRL|ALT',
        action = wezterm.action.ActivateTabRelative(-1),
    },
    {
        key = ']',
        mods = 'CTRL|ALT',
        action = wezterm.action.ActivateTabRelative(-1),
    },
    {
        key = 't',
        mods = 'ALT',
        action = wezterm.action.SpawnTab 'CurrentPaneDomain',
    },
}

return config
