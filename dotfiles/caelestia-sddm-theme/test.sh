#!/usr/bin/env bash
# test.sh — preview caelestia-sddm-theme without locking your session
# Creates a temporary theme copy with patched properties — never touches source files.

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors and formatting
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${CYAN}[test]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

usage() {
cat << HELP
${BOLD}caelestia-sddm-theme test runner${NC}
  Usage: ./test.sh [OPTIONS]

Options:
  -w, --wallpaper PATH   Path to a custom wallpaper image
  -u, --user NAME        Test with a specific username (default: current user)
  -n, --no-blur          Disable background blur
  -f, --fast             Disable animations (instant transitions)
  -h, --help             Show this help message

Environment:
  Requires 'sddm-greeter-qt6' (Qt6 greeter) to be installed.
HELP
}

# ── Parse arguments ───────────────────────────────────────────────────────
WALLPAPER=""; TEST_USER="$USER"; NO_BLUR=false; FAST=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--wallpaper) WALLPAPER="$2"; shift 2 ;;
        -u|--user)      TEST_USER="$2"; shift 2 ;;
        -n|--no-blur)   NO_BLUR=true;   shift   ;;
        -f|--fast)      FAST=true;      shift   ;;
        -h|--help)      usage; exit 0           ;;
        *) warn "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# Check for required tools
command -v sddm-greeter-qt6 &>/dev/null || die "sddm-greeter-qt6 not found. Please install SDDM (Qt6 version)."

# ── Auto-detect wallpaper ─────────────────────────────────────────────────
if [[ -z "$WALLPAPER" ]]; then
    # Try theme config hint
    WP_HINT="$HOME/.config/caelestia-sddm-theme/current_wallpaper"
    [[ -f "$WP_HINT" ]] && WALLPAPER=$(cat "$WP_HINT")
fi

if [[ -z "$WALLPAPER" ]]; then
    # Try Caelestia shell config
    SHELL_JSON="$HOME/.config/caelestia/shell.json"
    if [[ -f "$SHELL_JSON" ]]; then
        WALLPAPER=$(python3 -c "import json,os; d=json.load(open('$SHELL_JSON')); p=os.path.expanduser(d.get('paths',{}).get('wallpaper','')); print(p if os.path.isfile(p) else '')" 2>/dev/null || true)
    fi
fi

if [[ -z "$WALLPAPER" ]]; then
    # Fallback search
    for dir in "$HOME/Pictures/Wallpapers" "$HOME/Pictures" "$HOME/.local/share/wallpapers" "/usr/share/backgrounds"; do
        [[ -d "$dir" ]] && WALLPAPER=$(find "$dir" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | head -1) && [[ -n "$WALLPAPER" ]] && break
    done
fi

if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    WP_ABS="file://$(realpath "$WALLPAPER")"
    info "Wallpaper: $(basename "$WALLPAPER")"
else
    WP_ABS=""
    warn "No wallpaper found — using theme default colors"
fi

# Configuration values
BLUR_V="true"; BLUR_R="64"
$NO_BLUR && { BLUR_V="false"; BLUR_R="0"; }
ANIM_MS="300"
$FAST && ANIM_MS="0"

# ── Create temporary theme copy ──────────────────────────────────────────
# We copy to /tmp so the greeter loads from an isolated path
TMP_THEME=$(mktemp -d /tmp/caelestia-sddm-test.XXXXXX)
cp -r "$THEME_DIR/." "$TMP_THEME/"

# Patch Main.qml with test settings using Python
python3 - << PY
import re

path = "$TMP_THEME/Main.qml"
with open(path, "r") as f:
    content = f.read()

# Patch wallpaper
content = re.sub(r'(property string wallpaperPath:\s*)\"[^\"]*\"', r'\g<1>"$WP_ABS"', content)
# Patch blur
content = re.sub(r'(property bool\s+blurWallpaper:\s*)\w+', r'\g<1>$BLUR_V', content)
content = re.sub(r'(property int\s+blurRadius:\s*)\d+', r'\g<1>$BLUR_R', content)
# Patch animations
content = re.sub(r'(property int\s+animMs:\s*)\d+', r'\g<1>$ANIM_MS', content)

with open(path, "w") as f:
    f.write(content)
PY

cleanup() {
    rm -rf "$TMP_THEME"
    info "Cleaned up temporary files."
}
trap cleanup EXIT INT TERM

# ── Run Greeter ───────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  caelestia-sddm-theme — Qt6 Test Mode${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  User       : ${BLUE}$TEST_USER${NC}"
echo -e "  Blur       : $( $NO_BLUR && echo -e "${RED}Off${NC}" || echo -e "${GREEN}On (radius $BLUR_R)${NC}" )"
echo -e "  Animations : $( $FAST && echo -e "${RED}Disabled${NC}" || echo -e "${GREEN}Enabled ($ANIM_MS ms)${NC}" )"
echo -e ""
echo -e "  ${YELLOW}Note: Password authentication is disabled in test mode.${NC}"
echo -e "  ${YELLOW}Close the window or press Ctrl+C to exit.${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ok "Launching greeter..."

# Run sddm-greeter-qt6
# We set QML2_IMPORT_PATH to include our temporary Components directory
export QML2_IMPORT_PATH="$TMP_THEME/Components/:$QML2_IMPORT_PATH"

sddm-greeter-qt6 \
    --test-mode \
    --theme "$TMP_THEME" \
    2>&1 | grep -Ev "^[[:space:]]*$|QObject::startTimer|QBasicTimer|Reading from|High-DPI|cursor.available|Loading qrc"
