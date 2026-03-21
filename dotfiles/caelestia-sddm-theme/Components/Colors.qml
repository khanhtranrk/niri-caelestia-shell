// Colors.qml — Material You dark palette (Caelestia purple default)
// Overwritten by Matugen on wallpaper change.
// NOTE: All "on*" tokens renamed to "col*" to avoid QML signal-handler collision.

import QtQuick 2.15

Item {
    // Surfaces
    readonly property color background:          "#111118"
    readonly property color colBackground:       "#111118"
    readonly property color surface:             "#131218"
    readonly property color surfaceVariant:      "#46464f"
    readonly property color colSurface:          "#e4e1ec"
    readonly property color colSurfaceVariant:   "#c8c5d0"
    // Primary
    readonly property color primary:             "#cbbdff"
    readonly property color primaryContainer:    "#4200ba"
    readonly property color colPrimary:          "#2b0082"
    readonly property color colPrimaryContainer: "#e9ddff"
    // Secondary
    readonly property color secondary:           "#cbc2db"
    readonly property color colSecondary:        "#322942"
    // Outline
    readonly property color outline:             "#928f9a"
    readonly property color outlineVariant:      "#46464f"
    // Error
    readonly property color error:               "#ffb4ab"
    readonly property color colError:            "#690005"
    // Tertiary
    readonly property color tertiary:            "#efb8c8"
    readonly property color colTertiary:         "#492532"
    // Text on backgrounds (convenience aliases — these are safe names)
    readonly property color textPrimary:         "#e4e1ec"
    readonly property color textSecondary:       "#c8c5d0"
}
