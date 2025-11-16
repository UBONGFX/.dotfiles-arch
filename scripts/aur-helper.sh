#!/bin/bash
# AUR Helper (yay) installieren

set -e

echo "🔧 AUR Helper installieren..."

# Prüfen ob yay bereits installiert ist
if command -v yay &> /dev/null; then
    echo "✅ yay ist bereits installiert"
    exit 0
fi

# Prüfen ob paru installiert ist
if command -v paru &> /dev/null; then
    echo "✅ paru ist bereits installiert"
    exit 0
fi

echo "📦 yay wird installiert..."

# Abhängigkeiten installieren
sudo pacman -S --needed --noconfirm git base-devel

# yay klonen und bauen
cd /tmp
rm -rf yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

echo "✅ yay wurde erfolgreich installiert!"
