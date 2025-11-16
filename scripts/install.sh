#!/bin/bash
# Hauptinstallationsskript für Arch Linux Setup

set -e

DOTFILES_DIR="$HOME/.dotfiles-arch"

echo "🚀 Arch Linux Setup Installation"
echo "================================="
echo ""

# Prüfen ob im richtigen Verzeichnis
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "❌ Fehler: $DOTFILES_DIR nicht gefunden"
    echo "Bitte klone zuerst das Repository nach $DOTFILES_DIR"
    exit 1
fi

cd "$DOTFILES_DIR"

# 1. System aktualisieren
echo "📦 System aktualisieren..."
sudo pacman -Syu --noconfirm

# 2. Basis-Tools installieren
echo "📦 Basis-Tools installieren (git, stow)..."
sudo pacman -S --needed --noconfirm git stow

# 3. AUR-Helper installieren
echo ""
echo "🔧 AUR-Helper installieren..."
./scripts/aur-helper.sh

# # 4. Offizielle Pakete installieren
# echo ""
# echo "📦 Offizielle Pakete installieren..."
# if [ -f "packages/official.txt" ]; then
#     # Kommentare und leere Zeilen entfernen
#     grep -v '^#' packages/official.txt | grep -v '^$' | sudo pacman -S --needed -
#     echo "✅ Offizielle Pakete installiert"
# else
#     echo "⚠️  packages/official.txt nicht gefunden"
# fi

# 5. AUR-Pakete installieren
echo ""
echo "📦 AUR-Pakete installieren..."
if [ -f "packages/aur.txt" ]; then
    # Kommentare und leere Zeilen entfernen
    grep -v '^#' packages/aur.txt | grep -v '^$' | paru -S --needed -
    echo "✅ AUR-Pakete installiert"
else
    echo "⚠️  packages/aur.txt nicht gefunden"
fi

# # 6. Optionale Pakete (mit Bestätigung)
# echo ""
# read -p "📦 Optionale Pakete installieren? (y/N) " -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     if [ -f "packages/optional.txt" ]; then
#         grep -v '^#' packages/optional.txt | grep -v '^$' | yay -S --needed -
#         echo "✅ Optionale Pakete installiert"
#     else
#         echo "⚠️  packages/optional.txt nicht gefunden"
#     fi
# fi

# 7. Dotfiles deployen
echo ""
read -p "🔗 Dotfiles mit Stow deployen? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    ./scripts/stow.sh
fi

echo ""
echo "✅ Installation abgeschlossen!"
echo ""
echo "📝 Nächste Schritte:"
echo "  - Passe die Konfigurationen in ~/.dotfiles-arch an"
echo "  - Reboote das System wenn nötig"
echo "  - Genieße dein Arch Setup! 🎉"
