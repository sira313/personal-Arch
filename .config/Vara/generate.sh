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

# Convert RGB (255,255,255) to HEX (#ffffff)
rgb_to_hex() {
    IFS=',' read -r r g b <<< "$1"
    r=$(echo "$r" | xargs); g=$(echo "$g" | xargs); b=$(echo "$b" | xargs)
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

# Ensure directory structure exists
setup_structure() {
    for dir in "${SUBDIRS[@]}"; do
        mkdir -p "$ICON_DEST/$dir"
    done
    
    if [ -f "$VARA_SRC_DIR/index.theme" ]; then
        cp "$VARA_SRC_DIR/index.theme" "$ICON_DEST/"
    fi
}

# Generate and process icons
generate_icons() {
    if [ ! -f "$COLOR_SCHEME" ]; then
        return 1
    fi

    # Extract and convert colors
    RAW_PRIMARY=$(grep "DecorationFocus=" "$COLOR_SCHEME" | head -n 1 | cut -d'=' -f2)
    RAW_SECONDARY=$(grep "ForegroundInactive=" "$COLOR_SCHEME" | head -n 1 | cut -d'=' -f2)

    HEX_PRIMARY=$(rgb_to_hex "$RAW_PRIMARY")
    HEX_SECONDARY=$(rgb_to_hex "$RAW_SECONDARY")

    # Remove potential debris from previous failed globbing
    rm -f "$ICON_DEST/scalable/places/*.svg"

    # Use find to prevent literal *.svg file creation if directory is empty
    if [ -d "$VARA_SRC_DIR/icons/scalable" ]; then
        find "$VARA_SRC_DIR/icons/scalable" -maxdepth 1 -name "*.svg" -print0 | while IFS= read -r -d '' icon_path; do
            filename=$(basename "$icon_path")
            sed -e "s/fill=\"primary\"/fill=\"$HEX_PRIMARY\"/g" \
                -e "s/fill=\"secondary\"/fill=\"$HEX_SECONDARY\"/g" \
                "$icon_path" > "$ICON_DEST/scalable/places/$filename"
        done
    fi

    # Update icon cache for system recognition
    gtk-update-icon-cache -f -t "$ICON_DEST"
}

# Initial execution
setup_structure
generate_icons

# Watch for color scheme changes
while inotifywait -e close_write "$COLOR_SCHEME"; do
    generate_icons
done