#!/bin/bash

# Exit on error
set -e

echo "--------------------------------------------------"
echo "Starting Arch Linux Post-Install Setup (DMS + Niri)"
echo "--------------------------------------------------"

# 1. Update system and install base-devel
echo "Updating system and installing base-devel..."
sudo pacman -Syu --needed base-devel git --noconfirm

# 2. Install Paru (AUR Helper)
if ! command -v paru &> /dev/null; then
    echo "Installing Paru..."
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd ~
else
    echo "Paru is already installed. Skipping..."
fi

# 3. Install DMS, Niri, and Core Dependencies
echo "Installing DMS, Niri, and required packages..."
paru -S --noconfirm \
    nano brightnessctl quickshell cava cliphist wl-clipboard \
    dgop dsearch matugen niri qt6-multimedia polkit-gnome \
    dms-shell-bin greetd-dms-greeter-git kitty totem loupe \
    wf-recorder gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    gst-libav ffmpegthumbnailer

# 4. Setup DMS
echo "Initializing DMS setup..."
dms setup

# 5. Configure Greetd
echo "Configuring greetd..."
GREETD_CONFIG="/etc/greetd/config.toml"
sudo mkdir -p /etc/greetd
sudo bash -c "cat > $GREETD_CONFIG" <<EOF
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "dms-greeter --command niri"
EOF

# 6. Activate Greeter
echo "Enabling greetd service..."
sudo dms greeter enable
dms greeter sync
sudo systemctl enable greetd

# 7. Install Fonts
echo "Installing fonts..."
paru -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-font-awesome

# 8. Set Full Name
# Note: This uses the current logged-in user
echo "Setting full name..."
read -p "Enter your full name: " FULL_NAME
sudo chfn -f "$FULL_NAME" $(whoami)

# 9. Install Essential Apps
echo "Installing creative and productivity apps..."
paru -S --noconfirm krita gimp inkscape google-chrome visual-studio-code-bin

# 10. Download Wallpapers
echo "Downloading wallpapers..."
mkdir -p ~/Pictures
git clone https://github.com/mylinuxforwork/wallpaper ~/Pictures/Wallpapers

# 11. Final Step: Install Fish Shell
echo "Installing Fish shell..."
paru -S --noconfirm fish
echo "Setting Fish as default shell..."
chsh -s $(which fish)

echo "--------------------------------------------------"
echo "Setup complete! Please reboot your system."
echo "--------------------------------------------------"
