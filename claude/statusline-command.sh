#!/usr/bin/env bash
# Claude Code status line: model | folder | context bar
# Colours: Tokyo Night Moon palette (24-bit truecolor) — matches the
# tokyonight_moon tmux theme sourced from tmux.conf.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
folder=$(basename "$cwd")
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id // empty')

# ── Tokyo Night colour codes ──────────────────────────────────────────────────
RESET="\033[0m"
# Comment colour #636da6 — used for dimmed text and pipe separators
COMMENT="\033[38;2;99;109;166m"
# Empty bar segment #3b4261 (fg_gutter — also the tmux statusline segment bg)
BAR_EMPTY="\033[38;2;59;66;97m"
# Green  #c3e88d  < 50 %
GREEN="\033[38;2;195;232;141m"
# Yellow #ffc777  50–65 %
YELLOW="\033[38;2;255;199;119m"
# Orange #ff966c  65–95 %
ORANGE="\033[38;2;255;150;108m"
# Red    #ff757f  95 %+  (plus bold + blink)
RED="\033[1;5;38;2;255;117;127m"

# ── Dim text (model name and folder) ─────────────────────────────────────────
model_str=$(printf "${COMMENT}%s${RESET}" "$model")
folder_str=$(printf "${COMMENT}%s${RESET}" "$folder")

# ── Pipe separator in comment colour ─────────────────────────────────────────
SEP=$(printf "${COMMENT}|${RESET}")

# ── Dimmed session segment (UUID truncated to 8 chars) ───────────────────────
# Only built when session_id is present, so an absent id renders no segment.
session_str=""
if [ -n "$session_id" ]; then
    session_str=$(printf "${COMMENT}session: %s${RESET}" "${session_id:0:8}")
fi

# ── Build context bar section ─────────────────────────────────────────────────
if [ -n "$used_pct" ]; then
    # Scale so that 80% real = 100% displayed, cap at 100
    scaled=$(echo "$used_pct" | awk '{ s = $1 / 0.8; if (s > 100) s = 100; printf "%.0f", s }')

    # Number of filled blocks out of 10 (round to nearest)
    filled=$(echo "$scaled" | awk '{ f = int($1 / 10); if (($1 / 10 - f) >= 0.5) f++; if (f > 10) f = 10; printf "%d", f }')
    empty=$((10 - filled))

    # Choose fill colour by threshold
    if [ "$scaled" -ge 95 ]; then
        COLOR="$RED"
    elif [ "$scaled" -ge 65 ]; then
        COLOR="$ORANGE"
    elif [ "$scaled" -ge 50 ]; then
        COLOR="$YELLOW"
    else
        COLOR="$GREEN"
    fi

    # Build bar: coloured filled blocks + darker empty blocks
    filled_bar=""
    for i in $(seq 1 "$filled"); do filled_bar="${filled_bar}█"; done

    empty_bar=""
    for i in $(seq 1 "$empty"); do empty_bar="${empty_bar}░"; done

    bar="${COLOR}${filled_bar}${RESET}${BAR_EMPTY}${empty_bar}${RESET}"

    if [ "$scaled" -ge 95 ]; then
        bar_str=$(printf "%b %b${scaled}%%%b 💀" "$bar" "$COLOR" "$RESET")
    else
        bar_str=$(printf "%b %b${scaled}%%%b" "$bar" "$COLOR" "$RESET")
    fi

    if [ -n "$session_str" ]; then
        printf "%b %b %b %b %b %b %b\n" "$model_str" "$SEP" "$folder_str" "$SEP" "$bar_str" "$SEP" "$session_str"
    else
        printf "%b %b %b %b %b\n" "$model_str" "$SEP" "$folder_str" "$SEP" "$bar_str"
    fi
else
    if [ -n "$session_str" ]; then
        printf "%b %b %b %b %b\n" "$model_str" "$SEP" "$folder_str" "$SEP" "$session_str"
    else
        printf "%b %b %b\n" "$model_str" "$SEP" "$folder_str"
    fi
fi
