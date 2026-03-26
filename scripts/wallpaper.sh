#!/usr/bin/env bash
# Set wallpaper using swww
# Usage: wallpaper.sh [path_to_image]

WALLPAPER_DIR="$HOME/.dotfiles/wallpapers"
CURRENT_THEME=$(cat "$HOME/.dotfiles/.current-theme" 2>/dev/null || echo "everforest")

if [[ -n "$1" ]]; then
    IMG="$1"
elif [[ -f "$WALLPAPER_DIR/$CURRENT_THEME.png" ]]; then
    IMG="$WALLPAPER_DIR/$CURRENT_THEME.png"
elif [[ -f "$WALLPAPER_DIR/$CURRENT_THEME.jpg" ]]; then
    IMG="$WALLPAPER_DIR/$CURRENT_THEME.jpg"
else
    # Use first image found in wallpapers dir
    IMG=$(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -1)
fi

if [[ -z "$IMG" || ! -f "$IMG" ]]; then
    echo "No wallpaper found. Place images in $WALLPAPER_DIR"
    exit 1
fi

swww img "$IMG" \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-duration 1.5 \
    --transition-fps 60
