#!/bin/bash

# --- Arch Linux Post-Install Automation Script ---
# Description: Automated setup for Niri + DMS on Arch Linux
# Author: Aris
# Note: DO NOT run with sudo. Run as: ./setup.sh

set -e

# --- PRE-FLIGHT CHECKS ---
echo "--- Checking System State ---"

if [[ $EUID -eq 0 ]]; then
   echo "CRITICAL: Please run this script as a normal user, NOT root/sudo."
   exit 1
fi

# Function to check and install via paru
install_pkg() {
    paru -S --needed --noconfirm "$@"
}

# --- STEP 1-3: Base Installation ---
sudo pacman -S --needed --noconfirm xdg-user-dirs base-devel git
xdg-user-dirs-update

if ! command -v paru &> /dev/null; then
    _tempdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$_tempdir"
    cd "$_tempdir" && makepkg -si --noconfirm
    cd - && rm -rf "$_tempdir"
fi

echo "Installing Core Components..."
install_pkg nano brightnessctl quickshell cava cliphist wl-clipboard \
    dgop dsearch matugen niri qt6-multimedia polkit-gnome \
    dms-shell-bin greetd-dms-greeter-git kitty totem loupe \
    wf-recorder gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    gst-libav ffmpegthumbnailer samba podman-compose

# --- STEP 4: DMS Setup & Greetd (FIXED) ---
echo "Step 4: Configuring DMS..."

# Fix permissions first to ensure user owns their config
sudo chown -R $USER:$USER "$HOME/.config" 2>/dev/null || true

# Run DMS setup as clean user environment
env -u SUDO_USER -u SUDO_UID -u SUDO_GID -u SUDO_COMMAND dms setup

echo "Configuring Greetd..."
# Only use sudo for directory creation and file writing
sudo mkdir -p /etc/greetd
sudo bash -c 'cat <<EOF > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF'

# CRITICAL FIX: Running greeter sync without sudo 
# because dms internally handles what it needs.
# If it fails, we use a subshell to strip root privileges.
echo "Enabling and syncing greeter..."
dms greeter enable || sudo -u $USER dms greeter enable
dms greeter sync || sudo -u $USER dms greeter sync

sudo systemctl enable greetd

# --- STEP 5-7: Apps & Fonts ---
echo "Installing Apps & Fonts..."
install_pkg noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-font-awesome \
    krita gimp inkscape google-chrome visual-studio-code-bin

# --- STEP 8-9: Wallpapers & Dotfiles ---
if [ ! -d "$HOME/Pictures/Wallpapers" ]; then
    read -p "Clone ML4W Wallpapers? (y/N): " confirm_wp
    [[ "$confirm_wp" =~ ^[Yy]$ ]] && git clone https://github.com/mylinuxforwork/wallpaper "$HOME/Pictures/Wallpapers"
fi

echo "Syncing configuration files..."
TOP_LEVEL_DIRS=(".config" ".local" "Documents")
for dir in "${TOP_LEVEL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        mkdir -p "$HOME/$(dirname "$dir")"
        cp -aux "$dir" "$HOME/"
    fi
done

# --- STEP 10: Shell ---
install_pkg fish
if [[ "$SHELL" != "/usr/bin/fish" ]]; then
    sudo usermod -s /usr/bin/fish $USER
fi

echo "----------------------------------------------------"
echo "Setup Complete! Please reboot."
echo "----------------------------------------------------"
