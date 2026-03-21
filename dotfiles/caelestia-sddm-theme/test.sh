#!/usr/bin/env bash
# test.sh — preview caelestia-sddm-theme without locking your session
# Creates a temporary theme copy with patched wallpaper — never touches Main.qml.
#
# Usage:
#   ./test.sh
#   ./test.sh --wallpaper ~/Pictures/wall.jpg
#   ./test.sh --no-blur
#   ./test.sh --help

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info() { echo -e "${CYAN}[test]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

usage() {
cat << HELP
${BOLD}caelestia-sddm-theme test runner${NC}
  ./test.sh [OPTIONS]
Options:
  -w, --wallpaper PATH   Wallpaper image
  -n, --no-blur          Disable blur
  -h, --help             This help
HELP
}

WALLPAPER=""; NO_BLUR=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--wallpaper) WALLPAPER="$2"; shift 2 ;;
        -n|--no-blur)   NO_BLUR=true;   shift   ;;
        -h|--help)      usage; exit 0           ;;
        *) warn "Unknown: $1"; usage; exit 1    ;;
    esac
done

command -v sddm-greeter-qt6 &>/dev/null || die "sddm-greeter-qt6 not found. Install: yay -S sddm"

# ── Auto-detect wallpaper ─────────────────────────────────────────────────
if [[ -z "$WALLPAPER" ]]; then
    WP_HINT="$HOME/.config/caelestia-sddm-theme/current_wallpaper"
    [[ -f "$WP_HINT" ]] && WALLPAPER=$(cat "$WP_HINT")
fi
if [[ -z "$WALLPAPER" ]]; then
    SHELL_JSON="$HOME/.config/caelestia/shell.json"
    if [[ -f "$SHELL_JSON" ]]; then
        WALLPAPER=$(python3 -c "
import json,os
try:
    d=json.load(open('$SHELL_JSON'))
    p=os.path.expanduser(d.get('paths',{}).get('wallpaper',''))
    print(p if os.path.isfile(p) else '')
except: pass
" 2>/dev/null || true)
    fi
fi
if [[ -z "$WALLPAPER" ]]; then
    for dir in "$HOME/Pictures/Wallpapers" "$HOME/Pictures" "$HOME/.local/share/wallpapers"; do
        [[ -d "$dir" ]] && WALLPAPER=$(find "$dir" -maxdepth 2 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            | head -1) && [[ -n "$WALLPAPER" ]] && break
    done
fi

if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    WP_ABS="file://$(realpath "$WALLPAPER")"
    info "Wallpaper: $WALLPAPER"
else
    WP_ABS=""
    warn "No wallpaper found — gradient background will show"
fi

BLUR_V="true"; BLUR_R="55"
$NO_BLUR && { BLUR_V="false"; BLUR_R="0"; }

# ── Create a temp dir copy with patched Main.qml ──────────────────────────
# We copy to /tmp so the greeter loads from there — original is never touched.
TMP_THEME=$(mktemp -d /tmp/caelestia-sddm-test.XXXXXX)

cp -r "$THEME_DIR/." "$TMP_THEME/"

python3 - << PY
import re

main = open("$TMP_THEME/Main.qml").read()

main = re.sub(
    r'(property string wallpaperPath:\s*)\"[^\"]*\"',
    lambda m: m.group(1) + '"$WP_ABS"',
    main
)
main = re.sub(
    r'(property bool\s+blurWallpaper:\s*)\w+',
    r'\g<1>$BLUR_V',
    main
)
main = re.sub(
    r'(property int\s+blurRadius:\s*)\d+',
    r'\g<1>$BLUR_R',
    main
)

open("$TMP_THEME/Main.qml", "w").write(main)
PY

cleanup() {
    rm -rf "$TMP_THEME"
    info "Temp theme cleaned up."
}
trap cleanup EXIT INT TERM

# ── Print info ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  caelestia-sddm-theme — test mode${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Blur  : $( $NO_BLUR && echo off || echo "on (radius $BLUR_R)" )"
echo -e ""
echo -e "  ${YELLOW}Password won't auth — normal in test mode${NC}"
echo -e "  ${YELLOW}Close window or Ctrl+C to exit${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
ok "Launching from $TMP_THEME ..."

sddm-greeter-qt6 \
    --test-mode \
    --theme "$TMP_THEME" \
    2>&1 | grep -Ev "^[[:space:]]*$|QObject::startTimer|QBasicTimer|Reading from|High-DPI"
