#!/usr/bin/env bash
# Set wallpaper using swww
# Usage: wallpaper.sh [path_to_image]
#        wallpaper.sh --random   (pick random from wallpaper dir)

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

pick_random() {
    find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) \
        | shuf -n 1
}

if [[ -n "$1" && "$1" != "--random" ]]; then
    IMG="$1"
else
    IMG=$(pick_random)
fi

if [[ -z "$IMG" || ! -f "$IMG" ]]; then
    echo "No wallpaper found. Run: ~/my_linux_configs/scripts/download-wallpapers.sh"
    exit 1
fi

# Vary transition type for visual interest
TRANSITIONS=(grow wave outer wipe any)
T=${TRANSITIONS[$((RANDOM % ${#TRANSITIONS[@]}))]}

awww img "$IMG" \
    --transition-type "$T" \
    --transition-pos 0.5,0.5 \
    --transition-duration 1.5 \
    --transition-fps 60

echo "$IMG" > "$HOME/.cache/current-wallpaper"
