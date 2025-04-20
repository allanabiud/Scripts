#!/bin/bash

WALLPAPER="$1"

# Apply colorscheme with pywal16
/home/allanabiud/.local/bin/wal -i "$WALLPAPER"

# Restart waybar to apply new theme
pkill waybar && waybar &

# Tell Hyprland to reload its config (to apply new colors)
hyprctl reload

notify-send "✅ Wallpaper and colorscheme changed"
