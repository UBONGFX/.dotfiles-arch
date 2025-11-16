#!/bin/bash
# AUR Helper (paru) installieren

set -e

echo "🔧 AUR Helper installieren..."

# Prüfen ob paru bereits installiert ist
if command -v paru &> /dev/null; then
    echo "✅ paru ist bereits installiert"
    exit 0
fi

# Prüfen ob yay installiert ist (fallback)
if command -v yay &> /dev/null; then
    echo "✅ yay ist bereits installiert"
    exit 0
fi

echo "📦 paru wird installiert..."

# Abhängigkeiten installieren
sudo pacman -S --needed --noconfirm git base-devel

# paru klonen und bauen
cd /tmp
rm -rf paru
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm

echo "✅ paru wurde erfolgreich installiert!"
