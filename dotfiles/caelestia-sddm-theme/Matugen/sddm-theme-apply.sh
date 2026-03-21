#!/usr/bin/env bash
# sddm-theme-apply.sh — applies colors + wallpaper into installed Main.qml
# Called by matugen post_hook (via passwordless sudo).

THEME_DIR="/usr/share/sddm/themes/caelestia-sddm-theme"
REAL_USER="${SUDO_USER:-${USER}}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
CONFIG_DIR="$REAL_HOME/.config/caelestia-sddm-theme"
MAIN="$THEME_DIR/Main.qml"

set -e

# ── Wallpaper ──────────────────────────────────────────────────────────────
if [[ -f "$CONFIG_DIR/current_wallpaper" ]]; then
    WP=$(cat "$CONFIG_DIR/current_wallpaper")
    if [[ -f "$WP" ]]; then
        EXT="${WP##*.}"
        DEST="$THEME_DIR/Backgrounds/wallpaper.${EXT}"
        cp "$WP" "$DEST"
        python3 -c "
import re, sys
txt = open('$MAIN').read()
txt = re.sub(r'(property string wallpaperPath:\s*)\"[^\"]*\"', r'\1\"Backgrounds/wallpaper.${EXT}\"', txt)
open('$MAIN','w').write(txt)
"
        echo "[caelestia-sddm] ✓ Wallpaper applied"
    fi
fi

# ── Colors from Colors.qml → patch Main.qml color properties ──────────────
if [[ -f "$CONFIG_DIR/Colors.qml" ]]; then
    python3 - << PY
import re

colors_txt = open("$CONFIG_DIR/Colors.qml").read()
main_txt   = open("$MAIN").read()

# Extract hex values from Colors.qml property declarations
mapping = {
    "background":   "clrBackground",
    "surface":      "clrSurface",
    "surfaceVariant":"clrSurfaceVar",
    "primary":      "clrPrimary",
    "colPrimary":   "clrPrimaryBtn",
    "outline":      "clrOutline",
    "error":        "clrError",
    "textPrimary":  "clrText",
    "textSecondary":"clrTextDim",
}

for src_name, dst_name in mapping.items():
    m = re.search(r'readonly property color\s+' + src_name + r':\s*"(#[0-9a-fA-F]+)"', colors_txt)
    if m:
        hex_val = m.group(1)
        main_txt = re.sub(
            r'(property color\s+' + dst_name + r':\s*)"#[0-9a-fA-F]+"',
            r'\1"' + hex_val + '"',
            main_txt
        )

open("$MAIN", "w").write(main_txt)
print("[caelestia-sddm] ✓ Colors applied")
PY
fi

echo "[caelestia-sddm] Done."
