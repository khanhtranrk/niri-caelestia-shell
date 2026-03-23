// SddmColors.qml — Matugen template
// Place in ~/.config/caelestia-sddm-theme/SddmColors.qml
// Matugen will fill in {{color.*}} placeholders and write Colors.qml

// NOTE: This file is the INPUT template — do not edit Colors.qml directly.

import QtQuick

QtObject {
    // Material You color tokens (dark scheme)
    readonly property color background:        "{{colors.dark.background.hex}}"
    readonly property color colBackground:      "{{colors.dark.on_background.hex}}"
    readonly property color surface:           "{{colors.dark.surface.hex}}"
    readonly property color surfaceVariant:    "{{colors.dark.surface_variant.hex}}"
    readonly property color colSurface:         "{{colors.dark.on_surface.hex}}"
    readonly property color colSurfaceVariant:  "{{colors.dark.on_surface_variant.hex}}"
    readonly property color primary:           "{{colors.dark.primary.hex}}"
    readonly property color colPrimary:         "{{colors.dark.on_primary.hex}}"
    readonly property color primaryContainer:  "{{colors.dark.primary_container.hex}}"
    readonly property color secondary:         "{{colors.dark.secondary.hex}}"
    readonly property color colSecondary:       "{{colors.dark.on_secondary.hex}}"
    readonly property color outline:           "{{colors.dark.outline.hex}}"
    readonly property color outlineVariant:    "{{colors.dark.outline_variant.hex}}"
    readonly property color error:             "{{colors.dark.error.hex}}"
    readonly property color colError:           "{{colors.dark.on_error.hex}}"
    readonly property color tertiary:          "{{colors.dark.tertiary.hex}}"
    readonly property color colTertiary:        "{{colors.dark.on_tertiary.hex}}"
}
