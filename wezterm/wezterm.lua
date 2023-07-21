local wezterm = require 'wezterm';
local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

config.font_size = 14.0
config.font = wezterm.font_with_fallback({
    "JetBrainsMono Nerd Font",
})
config.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"
config.color_scheme = "nord"

config.colors = {
    cursor_bg = '#B48EAD',
    tab_bar = {
        active_tab = {
            bg_color = "#78c1d2",
            fg_color = "#404d5f",
        },
        inactive_tab = {
            bg_color = "#54748c",
            fg_color = "#ddd",
        },
        new_tab = {
            bg_color = "#54748c",
            fg_color = "#ddd",
        },
    }
}

-- config.window_background_opacity = .65
-- config.macos_window_background_blur = 20

return config;
