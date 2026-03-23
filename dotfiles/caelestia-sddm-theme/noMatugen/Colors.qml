// Colors.qml — Matugen-generated (default Caelestia purple)
// "on*" tokens renamed to "col*" and "text*" to avoid QML signal-handler collision.

import QtQuick

Item {
    readonly property color background:          "#111118"
    readonly property color surface:             "#131218"
    readonly property color surfaceVariant:      "#46464f"
    readonly property color primary:             "#cbbdff"
    readonly property color primaryContainer:    "#4200ba"
    readonly property color secondary:           "#cbc2db"
    readonly property color outline:             "#928f9a"
    readonly property color outlineVariant:      "#46464f"
    readonly property color error:               "#ffb4ab"
    readonly property color tertiary:            "#efb8c8"

    // "on" tokens renamed → safe names
    readonly property color colBackground:       "#e4e1ec"
    readonly property color colSurface:          "#e4e1ec"
    readonly property color colSurfaceVariant:   "#c8c5d0"
    readonly property color colPrimary:          "#2b0082"   // text ON primary button
    readonly property color colPrimaryContainer: "#e9ddff"
    readonly property color colSecondary:        "#322942"
    readonly property color colError:            "#690005"
    readonly property color colTertiary:         "#492532"

    // Convenience aliases (used by components)
    readonly property color textPrimary:         "#e4e1ec"   // main text color
    readonly property color textSecondary:       "#c8c5d0"   // dim text color
}
