local wezterm = require('wezterm')

local config = wezterm.config_builder()
config.font_size = 14.0

config.allow_square_glyphs_to_overflow_width = 'WhenFollowedBySpace'
config.color_scheme = 'Tokyo Night Moon'

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

-- See https://alexplescan.com/posts/2024/08/10/wezterm/
-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = 'RESIZE'
-- Sets the font for the window frame (tab bar)
config.window_frame = {
    -- font = wezterm.font({ weight = 'Bold' }),
    font_size = 12,
}

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
        action = wezterm.action.ActivateTabRelative(1),
    },
    {
        key = 't',
        mods = 'ALT',
        action = wezterm.action.SpawnTab('CurrentPaneDomain'),
    },
    {
        key = 'w',
        mods = 'ALT',
        action = wezterm.action.CloseCurrentTab({ confirm = true }),
    },
}

wezterm.on('update-status', function(window)
    -- Grab the utf8 character for the "powerline" left facing
    -- solid arrow.
    local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

    -- Grab the current window's configuration, and from it the
    -- palette (this is the combination of your chosen colour scheme
    -- including any overrides).
    local color_scheme = window:effective_config().resolved_palette
    local bg = color_scheme.background
    local fg = color_scheme.foreground

    window:set_right_status(wezterm.format({
        -- First, we draw the arrow...
        { Background = { Color = 'none' } },
        { Foreground = { Color = bg } },
        { Text = SOLID_LEFT_ARROW },
        -- Then we draw our text
        { Background = { Color = bg } },
        { Foreground = { Color = fg } },
        {
            Text = wezterm.hostname():match('^olaf-')
                    and ' 🤔🚀🚀🚀 '
                or (' ' .. wezterm.hostname() .. ' '),
        },
    }))
end)

-- fit more text on Chromebook's small screen
if wezterm.hostname():match('penguin') then
    config.font_size = 11.0
    config.window_decorations = 'INTEGRATED_BUTTONS'
end

-- required for folke/zen-mode.nvim
wezterm.on('user-var-changed', function(window, pane, name, value)
    local overrides = window:get_config_overrides() or {}
    if name == 'ZEN_MODE' then
        local incremental = value:find('+')
        local number_value = tonumber(value)
        if incremental ~= nil then
            while number_value > 0 do
                window:perform_action(wezterm.action.IncreaseFontSize, pane)
                number_value = number_value - 1
            end
            overrides.enable_tab_bar = false
        elseif number_value < 0 then
            window:perform_action(wezterm.action.ResetFontSize, pane)
            overrides.font_size = nil
            overrides.enable_tab_bar = true
        else
            overrides.font_size = number_value
            overrides.enable_tab_bar = false
        end
    end
    window:set_config_overrides(overrides)
end)

return config
