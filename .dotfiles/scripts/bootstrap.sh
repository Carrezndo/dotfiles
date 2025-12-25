#!/usr/bin/env bash
set -e

echo "=== Arch Linux Bootstrap Script ==="

# -------------------------
# Safety checks
# -------------------------
if [[ $EUID -eq 0 ]]; then
  echo "Do NOT run this script as root."
  exit 1
fi

if ! command -v pacman &>/dev/null; then
  echo "This script is for Arch Linux only."
  exit 1
fi

# -------------------------
# Dotfiles checkout (safe)
# -------------------------
if [[ -d "$HOME/.dotfiles" ]]; then
  echo "Running safe dotfiles checkout..."
  bash "$HOME/.dotfiles/scripts/dotfiles-checkout.sh"
fi

# -------------------------
# Sudo keepalive
# -------------------------
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# -------------------------
# Core packages
# -------------------------
echo "Installing base packages..."
sudo pacman -S --needed --noconfirm \
  base-devel \
  git \
  curl \
  wget \
  unzip \
  zip \
  rsync \
  htop \
  neovim \
  man-db \
  man-pages

# -------------------------
# AUR helper (yay)
# -------------------------
if ! command -v yay &>/dev/null; then
  echo "Installing yay..."
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
  rm -rf /tmp/yay
else
  echo "yay already installed"
fi

# -------------------------
# GPU detection
# -------------------------
echo "Detecting GPU..."

GPU=$(lspci | grep -E "VGA|3D")

if echo "$GPU" | grep -qi "NVIDIA"; then
  echo "NVIDIA GPU detected"
  sudo pacman -S --needed --noconfirm \
    nvidia \
    nvidia-utils \
    nvidia-settings

  # Wayland support
  sudo pacman -S --needed --noconfirm \
    egl-wayland

elif echo "$GPU" | grep -qi "AMD"; then
  echo "AMD GPU detected"
  sudo pacman -S --needed --noconfirm \
    mesa \
    vulkan-radeon \
    libva-mesa-driver \
    mesa-vdpau

elif echo "$GPU" | grep -qi "Intel"; then
  echo "Intel GPU detected"
  sudo pacman -S --needed --noconfirm \
    mesa \
    vulkan-intel \
    intel-media-driver

else
  echo "No supported GPU detected"
fi

# -------------------------
# Vulkan tools (optional)
# -------------------------
sudo pacman -S --needed --noconfirm \
  vulkan-tools \
  lib32-vulkan-icd-loader

# -------------------------
# NVIDIA Hyprland env (safe)
# -------------------------
if echo "$GPU" | grep -qi "NVIDIA"; then
  echo "Configuring NVIDIA Wayland environment..."
  mkdir -p ~/.config/environment.d
  cat <<EOF > ~/.config/environment.d/nvidia.conf
WLR_NO_HARDWARE_CURSORS=1
LIBVA_DRIVER_NAME=nvidia
XDG_SESSION_TYPE=wayland
EOF
fi

# -------------------------
# Wayland / Hyprland stack
# -------------------------
echo "Installing Wayland + Hyprland..."
sudo pacman -S --needed --noconfirm \
  hyprland \
  xdg-desktop-portal-hyprland \
  waybar \
  wofi \
  kitty \
  wl-clipboard \
  grim \
  slurp \
  swappy \
  polkit-kde-agent

# -------------------------
# Audio (PipeWire)
# -------------------------
echo "Installing PipeWire..."
sudo pacman -S --needed --noconfirm \
  pipewire \
  pipewire-alsa \
  pipewire-pulse \
  pipewire-jack \
  wireplumber

systemctl --user enable --now pipewire pipewire-pulse wireplumber

# -------------------------
# GTK / Theming
# -------------------------
echo "Installing GTK theming tools..."
sudo pacman -S --needed --noconfirm \
  nwg-look \
  gtk-engine-murrine \
  gtk-engines \
  papirus-icon-theme

# -------------------------
# File managers & utilities
# -------------------------
sudo pacman -S --needed --noconfirm \
  thunar \
  thunar-archive-plugin \
  file-roller \
  udiskie

# -------------------------
# Fonts
# -------------------------
echo "Installing fonts..."
sudo pacman -S --needed --noconfirm \
  ttf-jetbrains-mono \
  ttf-fira-code \
  noto-fonts \
  noto-fonts-emoji \
  ttf-font-awesome

# -------------------------
# Networking
# -------------------------
sudo pacman -S --needed --noconfirm networkmanager
sudo systemctl enable --now NetworkManager

# -------------------------
# User directories
# -------------------------
xdg-user-dirs-update

# -------------------------
# Git dotfiles setup reminder
# -------------------------
echo ""
echo "=== Bootstrap complete ==="
echo "Next steps:"
echo "1) Clone dotfiles (bare repo)"
echo "2) dot checkout"
echo "3) Reboot"
