// Colors.qml — global color pallet for Caelestia SDDM
// Overwritten by Matugen on wallpaper change.
// NOTE: All "on*" tokens renamed to "col*" to avoid QML signal-handler collision.

import QtQuick

Item {
    // Surfaces
    readonly property color clrBackground: "#111118"
    readonly property color clrSurface:    "#1c1b1f"
    readonly property color clrSurfaceVar: "#49454f"

    // Accents
    readonly property color clrPrimary:    "#d0bcff"
    readonly property color clrPrimaryBtn: "#381e72"
    readonly property color clrError:      "#f2b8b5"

    // Text
    readonly property color clrText:       "#e6e1e5"
    readonly property color clrTextDim:    "#cac4d0"

    // Outline
    readonly property color clrOutline:    "#938f99"
}
