#!/usr/bin/env bash
# Downloads a curated set of aesthetic wallpapers into ~/Pictures/wallpapers/
# Sources: Unsplash CDN (free, no account required)

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
mkdir -p "$WALLPAPER_DIR"

# Curated list of aesthetic wallpapers from Unsplash
# Format: "filename|unsplash_photo_id"
declare -A WALLPAPERS=(
    # Nature & Landscapes
    ["forest-fog.jpg"]="https://images.unsplash.com/photo-1448375240586-882707db888b?w=2560&q=90"
    ["mountain-lake.jpg"]="https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=2560&q=90"
    ["misty-mountains.jpg"]="https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=2560&q=90"
    ["aurora-borealis.jpg"]="https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=2560&q=90"
    ["desert-dunes.jpg"]="https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=2560&q=90"
    ["ocean-cliffs.jpg"]="https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=2560&q=90"
    ["cherry-blossom.jpg"]="https://images.unsplash.com/photo-1522383225653-ed111181a951?w=2560&q=90"
    ["lavender-field.jpg"]="https://images.unsplash.com/photo-1499002238440-d264edd596ec?w=2560&q=90"

    # Dark & Moody
    ["dark-forest.jpg"]="https://images.unsplash.com/photo-1448375240586-882707db888b?w=2560&q=85&sat=-50&bri=-10"
    ["night-city.jpg"]="https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=2560&q=90"
    ["milky-way.jpg"]="https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=2560&q=90"
    ["storm-clouds.jpg"]="https://images.unsplash.com/photo-1504701954957-2010ec3bcec1?w=2560&q=90"

    # Minimal & Abstract
    ["minimal-waves.jpg"]="https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=2560&q=90"
    ["geometric-dark.jpg"]="https://images.unsplash.com/photo-1550684376-efcbd6e3f031?w=2560&q=90"
    ["gradient-purple.jpg"]="https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=2560&q=90"
    ["gradient-blue.jpg"]="https://images.unsplash.com/photo-1557682224-5b8590cd9ec5?w=2560&q=90"

    # Architecture
    ["brutalist.jpg"]="https://images.unsplash.com/photo-1486325212027-8081e485255e?w=2560&q=90"
    ["japanese-temple.jpg"]="https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=2560&q=90"

    # Seasons
    ["autumn-path.jpg"]="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=2560&q=90"
    ["winter-pine.jpg"]="https://images.unsplash.com/photo-1418985991508-e47386d96a71?w=2560&q=90"
)

echo "Downloading ${#WALLPAPERS[@]} wallpapers to $WALLPAPER_DIR..."
echo ""

SUCCESS=0
FAIL=0

for name in "${!WALLPAPERS[@]}"; do
    dest="$WALLPAPER_DIR/$name"
    if [[ -f "$dest" ]]; then
        echo "  [skip] $name (already exists)"
        ((SUCCESS++))
        continue
    fi

    url="${WALLPAPERS[$name]}"
    printf "  Downloading %-30s ... " "$name"

    if curl -fsSL --max-time 30 -o "$dest" "$url" 2>/dev/null; then
        echo "done"
        ((SUCCESS++))
    else
        echo "FAILED"
        rm -f "$dest"
        ((FAIL++))
    fi
done

echo ""
echo "Done: $SUCCESS downloaded, $FAIL failed"
echo "Wallpapers saved to: $WALLPAPER_DIR"

# Apply a random one right away if swww-daemon is running
if pgrep -x awww-daemon > /dev/null; then
    echo "Applying a random wallpaper..."
    ~/.dotfiles/scripts/wallpaper.sh --random 2>/dev/null \
        || ~/my_linux_configs/scripts/wallpaper.sh --random
fi
