#!/bin/bash
# Einstellungen, die nicht in einer Datei liegen und daher nicht gestowt
# werden koennen - sie leben in dconf.
#
# Das Icon-Theme braucht es doppelt: GTK liest ~/.config/gtk-3.0/settings.ini
# (gestowt), Qt6 - und damit Quickshell und sein App-Launcher - liest den
# gsettings-Wert. QT_QPA_PLATFORMTHEME=qt5ct greift fuer Qt6 nicht,
# solange qt6ct nicht installiert ist.

set -e

echo "🎨 Desktop-Einstellungen setzen..."
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark-Storm'
echo "✅ Fertig."
