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
read -p "Apakah Anda ingin melakukan git clone untuk wallpaper dari ML4W? (y/N): " confirm_wallpaper

if [[ "$confirm_wallpaper" =~ ^[Yy]$ ]]; then
    if [ ! -d "$HOME/Pictures/Wallpapers" ]; then
        echo "Sedang mengunduh wallpaper..."
        mkdir -p "$HOME/Pictures"
        git clone https://github.com/mylinuxforwork/wallpaper "$HOME/Pictures/Wallpapers"
    else
        echo "Direktori wallpaper sudah ada, melewati langkah ini."
    fi
else
    echo "Melewati instalasi wallpaper."
fi

# --- Step 9: Sync Dotfiles (Automated Sub-folder Detection) ---
echo "Step 9: Menempatkan file konfigurasi secara otomatis..."

# Cukup daftarkan folder utama yang ingin disinkronkan
TOP_LEVEL_DIRS=(".config" ".local" "Documents")

for dir in "${TOP_LEVEL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Memproses folder: $dir"
        
        # Cari semua sub-folder yang berisi file (depth-first)
        # find akan mencari semua direktori di dalam $dir yang mengandung file
        find "$dir" -type d | while read -r subdir; do
            
            # Tentukan target path di $HOME
            target_path="$HOME/$subdir"
            
            # Buat folder jika belum ada (skip jika sudah ada)
            mkdir -p "$target_path"
            
            # Copy semua file (non-direktori) yang ada di folder tersebut
            # -f (force) untuk replace, 2>/dev/null untuk sembunyikan error folder kosong
            cp -f "$subdir"/* "$target_path/" 2>/dev/null
            
        done
        echo "[OK] Struktur $dir berhasil disinkronkan."
    fi
done

# Pastikan izin eksekusi untuk fungsi fish
chmod +x "$HOME/.config/fish/functions"/*.fish 2>/dev/null

echo "Step 9 selesai!"
echo "----------------------------------------------------"
echo "Setup Complete! System is ready."
echo "Please reboot to apply all changes and enter DMS."
echo "----------------------------------------------------"
