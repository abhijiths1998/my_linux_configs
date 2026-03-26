#!/usr/bin/env bash
# Interactive theme switcher using wofi
# Can also be called with: theme-switch.sh <theme-name>

DOTFILES="$HOME/.dotfiles"
THEMES_DIR="$DOTFILES/themes"

apply_theme() {
    local theme="$1"
    local theme_dir="$THEMES_DIR/$theme"

    if [[ ! -d "$theme_dir" ]]; then
        echo "Theme '$theme' not found"
        exit 1
    fi

    echo "Applying theme: $theme"

    # Hyprland theme
    cp "$theme_dir/hypr-theme.conf" "$HOME/.config/hypr/theme.conf"

    # Waybar colors
    cp "$theme_dir/waybar-colors.css" "$HOME/.config/waybar/colors.css"

    # Wofi colors
    cp "$theme_dir/wofi-colors.css" "$HOME/.config/wofi/colors.css"

    # Kitty theme
    cp "$theme_dir/kitty-theme.conf" "$HOME/.config/kitty/theme.conf"

    # Dunst theme - merge colors into dunstrc
    if [[ -f "$theme_dir/dunst-theme" ]]; then
        local dunstrc="$HOME/.config/dunst/dunstrc"
        local base="$DOTFILES/config/dunst/dunstrc"
        # Replace urgency sections with theme colors
        python3 -c "
import configparser, sys
base = configparser.ConfigParser()
base.read('$base')
theme = configparser.ConfigParser()
theme.read('$theme_dir/dunst-theme')
for section in theme.sections():
    if not base.has_section(section):
        base.add_section(section)
    for key, value in theme.items(section):
        base.set(section, key, value)
with open('$dunstrc', 'w') as f:
    base.write(f)
" 2>/dev/null || cp "$theme_dir/dunst-theme" "$dunstrc.theme"
    fi

    # Fastfetch theme
    if [[ -f "$theme_dir/fastfetch.jsonc" ]]; then
        mkdir -p "$HOME/.config/fastfetch"
        cp "$theme_dir/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    fi

    # Save current theme
    echo "$theme" > "$DOTFILES/.current-theme"

    # Reload components
    hyprctl reload 2>/dev/null
    killall -SIGUSR2 waybar 2>/dev/null || (killall waybar 2>/dev/null && waybar &)
    killall dunst 2>/dev/null && dunst &

    # Set wallpaper if matching one exists
    "$DOTFILES/scripts/wallpaper.sh"

    notify-send "Theme Changed" "Applied: $theme" -i preferences-desktop-theme 2>/dev/null
    echo "Theme '$theme' applied successfully"
}

# Direct invocation with theme name
if [[ -n "$1" ]]; then
    apply_theme "$1"
    exit 0
fi

# Interactive mode via wofi
THEMES=$(ls -1 "$THEMES_DIR")
SELECTED=$(echo "$THEMES" | wofi --dmenu --prompt "Select Theme" --width 300 --height 400)

if [[ -n "$SELECTED" ]]; then
    apply_theme "$SELECTED"
fi
