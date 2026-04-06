![ss](https://github.com/sira313/personal-Arch/blob/main/Screenshots/Screenshot%20from%202026-04-05%2012-44-12.png)
# Arch + DMS
After install minimal arch with archinstall

## Setup home dir
```
sudo pacman -S xdg-user-dirs && xdg-user-dirs-update
```

## Install Paru
```
sudo pacman -S --needed base-devel git
```
```
git clone https://aur.archlinux.org/paru.git && cd paru
```
```
makepkg -si
```

## Install DMS and others
```
paru -S nano brightnessctl quickshell cava cliphist wl-clipboard dgop dsearch matugen niri qt6-multimedia polkit-gnome dms-shell-bin greetd-dms-greeter-git kitty totem loupe wf-recorder gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav ffmpegthumbnailer samba freerdp podman-compose
```

### Configure DMS
```
dms setup
```

### Config greetd
```
sudo nano /etc/greetd/config.toml
```
Just like this
```
[terminal]
vt = 1

[default_session]
user = "greeter"
# Perintah ini akan menjalankan DMS greeter di atas niri
command = "dms-greeter --command niri"
```

### Activate Greeter
```
sudo dms greeter enable
```
```
dms greeter sync
```
```
sudo systemctl enable --now greetd
```
```
reboot
```
Setup your DMS with `Meta + ,`

## Install font
```
paru -S noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-font-awesome
```

## Add your full name
```
sudo chfn -f "My Full Name" username
```

## Apps
```
paru -S krita gimp inkscape google-chrome visual-studio-code-bin
```

## Free wallpapers
```
git clone https://github.com/mylinuxforwork/wallpaper Pictures/Wallpapers
```
