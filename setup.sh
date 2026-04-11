#!/bin/bash

# --- Arch Linux Post-Install Automation Script ---
# Description: Automated setup for Niri + DMS on Arch Linux
# Author: Aris
# Note: Run this script as a NORMAL USER (not via sudo). The script will ask for password when needed.

set -e

echo "--- Starting Post-Install Setup ---"

# --- Step 0: Pre-flight System Checks ---
echo "Step 0: Pre-flight checks..."

# Ensure the script is NOT running as root
if [[ $EUID -eq 0 ]]; then
   echo "Error: This script must NOT be run as root. Please run as a normal user."
   exit 1
fi

# Check for internet connection
if ! ping -c 1 google.com &> /dev/null; then
    echo "Error: No internet connection detected."
    exit 1
fi

# List of essential packages to check
CORE_PKGS=("base-devel" "git" "fish")
echo "Checking core dependencies..."
for pkg in "${CORE_PKGS[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        echo "[SKIP] $pkg is already installed."
    else
        echo "[INSTALL] $pkg will be installed."
    fi
done

# 1. Setup Home Directories
echo "Step 1: Setting up XDG user directories..."
sudo pacman -S --needed --noconfirm xdg-user-dirs
xdg-user-dirs-update

# 2. Install Paru (AUR Helper)
echo "Step 2: Installing Paru..."
sudo pacman -S --needed --noconfirm base-devel git
if ! command -v paru &> /dev/null; then
    _tempdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$_tempdir"
    cd "$_tempdir"
    makepkg -si --noconfirm
    cd -
    rm -rf "$_tempdir"
fi

# 3. Install DMS and Core Components
echo "Step 3: Installing DMS, Niri, and multimedia tools..."
# Added --needed to skip already installed packages
paru -S --needed --noconfirm \
    nano brightnessctl quickshell cava cliphist wl-clipboard \
    dgop dsearch matugen niri qt6-multimedia polkit-gnome \
    dms-shell-bin greetd-dms-greeter-git kitty totem loupe \
    wf-recorder gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    gst-libav ffmpegthumbnailer samba podman-compose

# 4. Configure DMS & Greetd
echo "Step 4: Configuring DMS and Greetd..."

# IMPORTANT: Run dms setup as current user, NOT root
echo "Running DMS setup as $(whoami)..."
dms setup

# Create greetd config (Requires sudo for system directory)
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
paru -S --needed --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-font-awesome

# 6. User Personalization & Shell
echo "Step 6: User Personalization..."
# Check if full name is already set to avoid re-asking if possible
current_name=$(getent passwd $(whoami) | cut -d ':' -f 5 | cut -d ',' -f 1)
if [ -z "$current_name" ]; then
    read -p "Enter your full name for this system: " full_name
    sudo chfn -f "$full_name" $(whoami)
else
    echo "Full name already set to: $current_name"
fi

# 7. Applications
echo "Step 7: Installing productivity apps..."
paru -S --needed --noconfirm krita gimp inkscape google-chrome visual-studio-code-bin

# 8. Wallpapers
echo "Step 8: Wallpapers..."
if [ ! -d "$HOME/Pictures/Wallpapers" ]; then
    read -p "Do you want to clone wallpapers from ML4W? (y/N): " confirm_wallpaper
    if [[ "$confirm_wallpaper" =~ ^[Yy]$ ]]; then
        echo "Downloading wallpapers..."
        mkdir -p "$HOME/Pictures"
        git clone https://github.com/mylinuxforwork/wallpaper "$HOME/Pictures/Wallpapers"
    fi
else
    echo "Wallpaper directory already exists, skipping."
fi

# 9. Sync Dotfiles
echo "Step 9: Synchronizing configuration files..."
TOP_LEVEL_DIRS=(".config" ".local" "Documents")

for dir in "${TOP_LEVEL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        mkdir -p "$HOME/$(dirname "$dir")"
        # Using cp -ur to only update newer files/copy missing files
        cp -aux "$dir" "$HOME/"
        echo "[OK] $dir successfully synced."
    fi
done

# Ensure fish functions are executable
if [ -d "$HOME/.config/fish/functions" ]; then
    chmod +x "$HOME/.config/fish/functions"/*.fish 2>/dev/null
fi

# 10. Finalizing Shell & Services
echo "Step 10: Finalizing system..."
paru -S --needed --noconfirm fish

# Switch default shell to Fish
if [[ "$SHELL" != "/usr/bin/fish" ]]; then
    echo "Switching default shell to Fish..."
    sudo usermod -s /usr/bin/fish $(whoami)
else
    echo "Fish is already the default shell."
fi

echo "----------------------------------------------------"
echo "Setup Complete! System is ready."
echo "Please reboot to apply all changes and enter DMS."
echo "----------------------------------------------------"
