#!/bin/bash

# Configuration Paths
VARA_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_DEST="$HOME/.local/share/icons/Vara"
COLOR_SCHEME="$HOME/.local/share/color-schemes/DankMatugen.colors"

# Define required subdirectories
SUBDIRS=(
    "scalable/actions" "scalable/apps" "scalable/categories" "scalable/devices" 
    "scalable/emblems" "scalable/emotes" "scalable/mimetypes" "scalable/places" "scalable/status"
    "symbolic/actions" "symbolic/apps" "symbolic/categories" "symbolic/devices" 
    "symbolic/emblems" "symbolic/emotes" "symbolic/mimetypes" "symbolic/places" "symbolic/status"
)

# Function to convert RGB (255,255,255) to HEX (#ffffff)
rgb_to_hex() {
    IFS=',' read -r r g b <<< "$1"
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# 1. Initial Setup: Check and create directory structure
setup_structure() {
    if [ ! -d "$ICON_DEST" ]; then
        echo "Creating Vara icon theme structure at $ICON_DEST..."
        for dir in "${SUBDIRS[@]}"; do
            mkdir -p "$ICON_DEST/$dir"
        done
        
        if [ -f "index.theme" ]; then
            cp "index.theme" "$ICON_DEST/"
        else
            echo "Warning: index.theme not found in current directory!"
        fi
    fi
}

# 3. Icon Generation Logic
generate_icons() {
    echo "Change detected in $COLOR_SCHEME. Updating icons..."

    # Extract colors from .colors file using grep/sed
    # Primary = DecorationFocus
    # Secondary = ForegroundInactive
    RAW_PRIMARY=$(grep "DecorationFocus=" "$COLOR_SCHEME" | head -n 1 | cut -d'=' -f2)
    RAW_SECONDARY=$(grep "ForegroundInactive=" "$COLOR_SCHEME" | head -n 1 | cut -d'=' -f2)

    # Convert to HEX
    HEX_PRIMARY=$(rgb_to_hex "$RAW_PRIMARY")
    HEX_SECONDARY=$(rgb_to_hex "$RAW_SECONDARY")

    echo "Colors found: Primary=$HEX_PRIMARY, Secondary=$HEX_SECONDARY"

    # Process every SVG in the icon/ folder
    # Assuming source icons are located in ./icon/*.svg
    for icon_path in "$VARA_SRC_DIR"/icon/*.svg; do
        filename=$(basename "$icon_path")
        
        # Replace fill="primary" and fill="secondary" with the new HEX colors
        # Output is placed in scalable/places
        sed -e "s/fill=\"primary\"/fill=\"$HEX_PRIMARY\"/g" \
            -e "s/fill=\"secondary\"/fill=\"$HEX_SECONDARY\"/g" \
            "$icon_path" > "$ICON_DEST/scalable/places/$filename"
    done

    # 4. Update Icon Cache
    echo "Updating icon cache..."
    gtk-update-icon-cache -f -t "$ICON_DEST"
    
    echo "Done! Icons updated."
}

# Main Execution
setup_structure

# Run generation on initial execution
generate_icons

# 2 & 5. Monitor with inotifywait (Looping)
echo "Watching for changes in $COLOR_SCHEME..."
while inotifywait -e close_write "$COLOR_SCHEME"; do
    generate_icons
done
