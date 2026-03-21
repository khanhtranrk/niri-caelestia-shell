#!/usr/bin/env bash
# setup.sh — interactive installer for caelestia-sddm-theme

set -e
THEME_NAME="caelestia-sddm-theme"
THEME_INSTALL_DIR="/usr/share/sddm/themes/$THEME_NAME"
REAL_USER="${SUDO_USER:-$USER}"                          # actual user even under sudo
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)   # real home dir
CONFIG_DIR="$REAL_HOME/.config/$THEME_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${CYAN}[setup]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

echo ""
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}${BOLD}  caelestia-sddm-theme installer${NC}"
echo -e "${CYAN}  SDDM theme matching niri-caelestia-shell lockscreen${NC}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
info "Installing for user: $REAL_USER (home: $REAL_HOME)"
echo ""

# ── Dependency check ──────────────────────────────────────────────────────
info "Checking dependencies..."
MISSING=()
command -v sddm-greeter-qt6 &>/dev/null || MISSING+=("sddm")
if command -v pacman &>/dev/null; then
    for pkg in qt6-svg qt6-declarative qt6-multimedia-ffmpeg; do
        pacman -Q "$pkg" &>/dev/null || MISSING+=("$pkg")
    done
fi
if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Missing: ${MISSING[*]}"
    warn "Install: yay -S --needed ${MISSING[*]}"
    read -rp "Continue anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || die "Aborted."
fi
ok "Dependencies OK"

# ── Integration mode ──────────────────────────────────────────────────────
echo ""
echo "Select integration mode:"
echo "  1) Matugen — colors auto-sync when wallpaper changes (recommended)"
echo "  2) Manual  — edit Colors.qml yourself"
echo ""
read -rp "Choice [1/2]: " MODE_CHOICE

# ── Install theme files ───────────────────────────────────────────────────
info "Installing theme to $THEME_INSTALL_DIR ..."
sudo mkdir -p "$THEME_INSTALL_DIR"
sudo cp -rf "$SCRIPT_DIR"/. "$THEME_INSTALL_DIR/"
ok "Theme files installed"

# Fonts
if ls "$SCRIPT_DIR/fonts/"* &>/dev/null 2>&1; then
    sudo cp -r "$SCRIPT_DIR/fonts/"* /usr/share/fonts/ 2>/dev/null || true
    ok "Fonts installed"
fi

# ── Config dir (owned by real user, not root) ─────────────────────────────
sudo -u "$REAL_USER" mkdir -p "$CONFIG_DIR"

if [[ "$MODE_CHOICE" == "1" ]]; then
    # ── Matugen mode ──────────────────────────────────────────────────────
    sudo -u "$REAL_USER" bash -c "
        cp -n '$SCRIPT_DIR/Matugen/SddmColors.qml'     '$CONFIG_DIR/SddmColors.qml'
        cp -n '$SCRIPT_DIR/Matugen/Colors.qml'         '$CONFIG_DIR/Colors.qml'
        cp    '$SCRIPT_DIR/Matugen/sddm-theme-apply.sh' '$CONFIG_DIR/sddm-theme-apply.sh'
        cp -n '$SCRIPT_DIR/Components/Settings.qml'    '$CONFIG_DIR/Settings.qml'
        chmod +x '$CONFIG_DIR/sddm-theme-apply.sh'
    "

    SUDOERS_FILE="/etc/sudoers.d/${THEME_NAME}-${REAL_USER}"
    echo "$REAL_USER ALL=(ALL) NOPASSWD: $CONFIG_DIR/sddm-theme-apply.sh" \
        | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 0440 "$SUDOERS_FILE"
    ok "Passwordless sudo configured"

    MATUGEN_CONF="$REAL_HOME/.config/matugen/config.toml"
    if [[ -f "$MATUGEN_CONF" ]]; then
        if ! grep -q "caelestia-sddm" "$MATUGEN_CONF"; then
            cat "$SCRIPT_DIR/Matugen/matugen-config.toml" >> "$MATUGEN_CONF"
            ok "Matugen hook added to $MATUGEN_CONF"
        else
            ok "Matugen hook already present"
        fi
    else
        warn "No matugen config at $MATUGEN_CONF — add hook manually from Matugen/matugen-config.toml"
    fi

    info "Applying initial colors..."
    sudo -u "$REAL_USER" bash -c "sudo '$CONFIG_DIR/sddm-theme-apply.sh'" || \
        warn "Apply script failed — run manually: sudo $CONFIG_DIR/sddm-theme-apply.sh"

else
    # ── Manual mode ───────────────────────────────────────────────────────
    sudo -u "$REAL_USER" bash -c "
        cp -n '$SCRIPT_DIR/noMatugen/Colors.qml'            '$CONFIG_DIR/Colors.qml'
        cp -n '$SCRIPT_DIR/noMatugen/Settings.qml'          '$CONFIG_DIR/Settings.qml'
        cp    '$SCRIPT_DIR/noMatugen/sddm-theme-apply.sh'   '$CONFIG_DIR/sddm-theme-apply.sh'
        chmod +x '$CONFIG_DIR/sddm-theme-apply.sh'
    "

    SUDOERS_FILE="/etc/sudoers.d/${THEME_NAME}-${REAL_USER}"
    echo "$REAL_USER ALL=(ALL) NOPASSWD: $CONFIG_DIR/sddm-theme-apply.sh" \
        | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 0440 "$SUDOERS_FILE"

    # Apply immediately
    sudo cp "$CONFIG_DIR/Colors.qml"   "$THEME_INSTALL_DIR/Components/Colors.qml"
    sudo cp "$CONFIG_DIR/Settings.qml" "$THEME_INSTALL_DIR/Components/Settings.qml"
    ok "Colors and settings applied"
    info "Edit $CONFIG_DIR/Colors.qml and Settings.qml to customize"
    info "Then run: $CONFIG_DIR/sddm-theme-apply.sh"
fi

# ── /etc/sddm.conf ────────────────────────────────────────────────────────
SDDM_CONF="/etc/sddm.conf"
info "Configuring $SDDM_CONF ..."
[[ -f "$SDDM_CONF" ]] && sudo cp "$SDDM_CONF" "${SDDM_CONF}.bak" && ok "Backup: ${SDDM_CONF}.bak"

sudo tee "$SDDM_CONF" > /dev/null << CONF
[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/$THEME_NAME/Components/,QT_IM_MODULE=qtvirtualkeyboard

[Theme]
Current=$THEME_NAME
CONF
ok "sddm.conf configured"

# ── Guide ─────────────────────────────────────────────────────────────────
sudo -u "$REAL_USER" tee "$CONFIG_DIR/GUIDE.txt" > /dev/null << GUIDE
caelestia-sddm-theme — quick reference
═══════════════════════════════════════
Config : $CONFIG_DIR
Theme  : $THEME_INSTALL_DIR

Edit Settings.qml or Colors.qml, then apply:
  $CONFIG_DIR/sddm-theme-apply.sh

Test without rebooting (from theme source dir):
  ./test.sh
  ./test.sh --wallpaper ~/Pictures/wall.jpg
  ./test.sh --no-blur

Uninstall:
  sudo rm -rf $THEME_INSTALL_DIR
  rm -rf $CONFIG_DIR
  sudo rm -f /etc/sudoers.d/${THEME_NAME}-${REAL_USER}
GUIDE

echo ""
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Done! Reboot to activate SDDM theme.${NC}"
echo -e "${GREEN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Test first:  ./test.sh --wallpaper ~/Pictures/Wallpapers/wall.jpg"
echo "  Guide:       $CONFIG_DIR/GUIDE.txt"
echo ""
