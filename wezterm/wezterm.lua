local wezterm = require 'wezterm';

return {
  font_size = 14.0,
  font = wezterm.font_with_fallback({
    "JetBrainsMono Nerd Font",
}),
  allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace",
  color_scheme = "nord",

  colors = {
    tab_bar = {
      active_tab = {
        bg_color = "#0328fc",
        fg_color = "#c0c0c0",
      },
      inactive_tab = {
        bg_color = "#010d54",
        fg_color = "#808080",
      },
      new_tab = {
        bg_color = "#010d54",
        fg_color = "#808080",
      },
    }
  }
}
