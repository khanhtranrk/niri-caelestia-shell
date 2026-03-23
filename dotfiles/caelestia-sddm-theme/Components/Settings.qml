// Settings.qml — user config. Edit ~/.config/caelestia-sddm-theme/Settings.qml
// then run the apply script.

import QtQuick

Item {
    readonly property string wallpaperPath:   ""   // set by apply script or pass via test.sh
    readonly property bool   blurWallpaper:   true
    readonly property int    blurRadius:      55
    readonly property real   dimOpacity:      0.4

    readonly property string clockFontFamily: "Rubik"
    readonly property string uiFontFamily:    "Rubik"
    readonly property string monoFontFamily:  "JetBrains Mono Nerd Font"

    readonly property bool   showAvatars:     true
    // virtualKeyboard: false unless qt6-virtualkeyboard is installed
    readonly property bool   virtualKeyboard: false

    readonly property int    animDuration:    280
}
