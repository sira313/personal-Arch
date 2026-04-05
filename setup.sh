#!/bin/bash

# --- Arch Linux Post-Install Automation Script ---
# Base: Arch minimal (archinstall)
# Desktop: Niri + Dank Material Shell (DMS)

set -e

echo "--- Starting Post-Install Setup ---"

# 1. Setup Home Directories
echo "Step 1: Setting up XDG user directories..."
sudo pacman -S --noconfirm xdg-user-dirs
xdg-user-dirs-update

# 2. Install Paru (AUR Helper)
echo "Step 2: Installing Paru..."
sudo pacman -S --needed --noconfirm base-devel git
if [ ! -d "paru" ]; then
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
    gst-libav ffmpegthumbnailer

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

# 6. User Personalization
echo "Step 6: Setting full name and Shell..."
# Replace 'Aris' with your desired full name if needed
sudo chfn -f "Aris" $(whoami)

# Install Fish Shell
paru -S --noconfirm fish
echo "Switching default shell to Fish..."
chsh -s /usr/bin/fish

# 7. Applications
echo "Step 7: Installing productivity apps..."
paru -S --noconfirm krita gimp inkscape google-chrome visual-studio-code-bin

# 8. Wallpapers
echo "Step 8: Cloning wallpapers..."
if [ ! -d "$HOME/Pictures/Wallpapers" ]; then
    git clone https://github.com/mylinuxforwork/wallpaper "$HOME/Pictures/Wallpapers"
fi

echo "--- Setup Complete! Please reboot your system. ---"
