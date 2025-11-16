#!/bin/bash
# Dotfiles mit GNU Stow deployen

set -e

DOTFILES_DIR="$HOME/.dotfiles-arch"
cd "$DOTFILES_DIR"

echo "🔗 Dotfiles mit Stow deployen..."

# Liste aller Stow-Pakete (Ordner außer scripts, packages, etc.)
PACKAGES=($(find . -maxdepth 1 -type d ! -name ".*" ! -name "scripts" ! -name "packages" -exec basename {} \;))

if [ ${#PACKAGES[@]} -eq 0 ]; then
    echo "⚠️  Keine Dotfile-Pakete gefunden"
    exit 1
fi

echo "📦 Gefundene Pakete: ${PACKAGES[*]}"
echo ""

# Jedes Paket mit Stow deployen
for package in "${PACKAGES[@]}"; do
    echo "🔗 Deploye: $package"
    stow -v "$package"
done

echo ""
echo "✅ Alle Dotfiles wurden erfolgreich deployed!"
echo ""
echo "💡 Tipp: Um ein einzelnes Paket zu entfernen, nutze: stow -D <paket>"
