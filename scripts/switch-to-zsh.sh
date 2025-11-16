#!/bin/bash
# Automatisch von Bash zu Zsh wechseln

set -e

echo "🐚 Wechsel zu Zsh"
echo "================="
echo ""

# Prüfen ob Zsh installiert ist
if ! command -v zsh &> /dev/null; then
    echo "❌ Zsh ist nicht installiert!"
    echo "📦 Installiere Zsh..."
    sudo pacman -S --needed zsh
fi

# Zeige aktuelle Shell
CURRENT_SHELL=$(echo $SHELL)
echo "📍 Aktuelle Shell: $CURRENT_SHELL"

# Prüfen ob bereits Zsh
if [[ "$CURRENT_SHELL" == *"zsh"* ]]; then
    echo "✅ Du nutzt bereits Zsh!"
    exit 0
fi

# Zsh Pfad finden
ZSH_PATH=$(which zsh)
echo "🔍 Zsh gefunden: $ZSH_PATH"

# Prüfen ob Zsh in /etc/shells ist
if ! grep -q "^$ZSH_PATH$" /etc/shells; then
    echo "⚠️  Zsh ist nicht in /etc/shells"
    echo "➕ Füge Zsh zu /etc/shells hinzu..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

# Shell wechseln
echo ""
echo "🔄 Wechsle Standard-Shell zu Zsh..."
chsh -s "$ZSH_PATH"

echo ""
echo "✅ Shell erfolgreich zu Zsh gewechselt!"
echo ""
echo "📝 Nächste Schritte:"
echo "  1. Melde dich ab und wieder an (oder führe aus: exec zsh)"
echo "  2. Installiere Oh My Zsh: paru -S oh-my-zsh-git"
echo "  3. Installiere Zsh Plugins aus packages/aur.txt"
echo "  4. Konfiguriere ~/.zshrc"
echo ""
echo "💡 Mehr Infos: ~/.dotfiles-arch/docs/switch-to-zsh.md"
echo ""

# Frage ob sofort zu Zsh wechseln
read -p "🚀 Jetzt zu Zsh wechseln? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "🐚 Starte Zsh..."
    exec zsh
fi
