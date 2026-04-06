#!/bin/bash

# --- Arch Linux Post-Install Automation Script ---
# Description: Automated setup for Niri + DMS on Arch Linux
# Author: Aris

set -e

echo "--- Starting Post-Install Setup ---"

# 1. Setup Home Directories
echo "Step 1: Setting up XDG user directories..."
sudo pacman -S --noconfirm xdg-user-dirs
xdg-user-dirs-update

# 2. Install Paru (AUR Helper)
echo "Step 2: Installing Paru..."
sudo pacman -S --needed --noconfirm base-devel git
if ! command -v paru &> /dev/null; then
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ..
    rm -rf paru
fi

# 3. Install DMS and Core Components
echo "Step 3: Installing DMS, Niri, and multimedia tools..."
paru -S --noconfirm \
    nano brightnessctl quickshell cava cliphist wl-clipboard \
    dgop dsearch matugen niri qt6-multimedia polkit-gnome \
    dms-shell-bin greetd-dms-greeter-git kitty totem loupe \
    wf-recorder gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    gst-libav ffmpegthumbnailer samba podman-compose

# 4. Configure DMS & Greetd
echo "Step 4: Configuring DMS and Greetd..."
dms setup

# Create greetd config
sudo mkdir -p /etc/greetd
sudo bash -c 'cat <<EOF > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF'

# Enable Greeter
sudo dms greeter enable
dms greeter sync
sudo systemctl enable greetd

# 5. Install Fonts
echo "Step 5: Installing fonts..."
paru -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-font-awesome

# 6. User Personalization & Shell
echo "Step 6: User Personalization..."

# Input full name from terminal
read -p "Enter your full name for this system: " full_name
sudo chfn -f "$full_name" $(whoami)

# Install and set Fish Shell
echo "Installing Fish Shell..."
paru -S --noconfirm fish
echo "Switching default shell to Fish..."
sudo chsh -s /usr/bin/fish $(whoami)

# 7. Applications
echo "Step 7: Installing productivity apps..."
paru -S --noconfirm krita gimp inkscape google-chrome visual-studio-code-bin

# 8. Wallpapers
echo "Step 8: Wallpapers..."
read -p "Do you want to clone wallpapers from ML4W? (y/N): " confirm_wallpaper

if [[ "$confirm_wallpaper" =~ ^[Yy]$ ]]; then
    if [ ! -d "$HOME/Pictures/Wallpapers" ]; then
        echo "Downloading wallpapers..."
        mkdir -p "$HOME/Pictures"
        git clone https://github.com/mylinuxforwork/wallpaper "$HOME/Pictures/Wallpapers"
    else
        echo "Wallpaper directory already exists, skipping this step."
    fi
else
    echo "Skipping wallpaper installation."
fi

# --- Step 9: Sync Dotfiles (Automated Sub-folder Detection) ---
echo "Step 9: Synchronizing configuration files..."

# List of top-level directories to be scanned from the repo
TOP_LEVEL_DIRS=(".config" ".local" "Documents")

for dir in "${TOP_LEVEL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        
        # Find all subdirectories that contain files
        find "$dir" -type d | while read -r subdir; do
            
            # Map repo subdirectory to the user's HOME path
            target_path="$HOME/$subdir"

            # Create target folder if it doesn't exist
            mkdir -p "$target_path"
            
            # Copy files and replace existing ones (-f)
            # Redirecting errors to null in case a directory is empty
            cp -f "$subdir"/* "$target_path/" 2>/dev/null
            
        done
        echo "[OK] Structure for $dir successfully synced."
    fi
done

# Ensure fish functions are executable
chmod +x "$HOME/.config/fish/functions"/*.fish 2>/dev/null

echo "Step 9 complete!"
echo "----------------------------------------------------"
echo "Setup Complete! System is ready."
echo "Please reboot to apply all changes and enter DMS."
echo "----------------------------------------------------"
