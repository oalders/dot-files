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
}
