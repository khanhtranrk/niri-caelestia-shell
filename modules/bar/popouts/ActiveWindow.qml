import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Item wrapper

    // Pinned window – snapshotted on open, not updated live while visible.
    // This prevents niri's follow-mouse focus from changing the displayed info.
    property var activeWindow: null

    // Update the snapshot whenever the popout is NOT visible (so next open is fresh)
    property bool _canUpdate: true

    Connections {
        target: Niri
        enabled: root._canUpdate
        function onFocusedWindowChanged(): void {
            root.activeWindow = Niri.focusedWindow ?? Niri.lastFocusedWindow ?? null;
        }
    }

    Component.onCompleted: {
        root.activeWindow = Niri.focusedWindow ?? Niri.lastFocusedWindow ?? null;
    }

    // When the item becomes visible (popout opens), freeze; when hidden, allow updates.
    onVisibleChanged: {
        if (visible) {
            // Snapshot the current window right now and lock it
            root.activeWindow = Niri.focusedWindow ?? Niri.lastFocusedWindow ?? null;
            root._canUpdate = false;
        } else {
            root._canUpdate = true;
        }
    }

    // Niri does not support individual window capture via hyprland-toplevel-export-v1 yet,
    // so we cannot use ScreencopyView on a WaylandToplevel here. We will just use the icon.

    implicitWidth: Niri.niriAvailable && root.activeWindow ? Config.bar.sizes.windowPreviewSize : -Appearance.padding.large * 2
    implicitHeight: child.implicitHeight

    Item {
        id: child

        anchors.centerIn: parent
        implicitWidth: parent.width
        implicitHeight: detailsRow.implicitHeight

        RowLayout {
            id: detailsRow

            anchors.fill: parent
            spacing: Appearance.spacing.normal

            IconImage {
                id: icon

                Layout.alignment: Qt.AlignVCenter
                implicitSize: details.implicitHeight
                source: Icons.getAppIcon(root.activeWindow?.app_id ?? "", "image-missing")
            }

            ColumnLayout {
                id: details

                spacing: 0
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: root.activeWindow?.title ?? ""
                    font.pointSize: Appearance.font.size.normal
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.activeWindow?.app_id ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            Item {
                implicitWidth: expandIcon.implicitHeight + Appearance.padding.small * 2
                implicitHeight: expandIcon.implicitHeight + Appearance.padding.small * 2

                Layout.alignment: Qt.AlignVCenter

                StateLayer {
                    radius: Appearance.rounding.normal

                    function onClicked(): void {
                        root.wrapper.detach("winfo");
                    }
                }

                MaterialIcon {
                    id: expandIcon

                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: font.pointSize * 0.05

                    text: "chevron_right"

                    font.pointSize: Appearance.font.size.large
                }
            }
        }

        // ScreencopyView removed because Niri doesn't support the required protocol
    }
}
