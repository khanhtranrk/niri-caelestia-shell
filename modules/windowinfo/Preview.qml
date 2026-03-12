pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen

    // Client is snapshotted by WindowInfo.qml on open.
    // DO NOT add Connections here – follow-mouse focus would re-target this.
    property var client: null

    // Niri currently does not support the hyprland-toplevel-export-v1 protocol,
    // which prevents ScreencopyView from capturing individual Wayland windows.
    // We will use a large application icon instead of a blank screen.

    Layout.preferredWidth: preview.implicitWidth + Appearance.padding.xl * 2
    Layout.fillHeight: true

    StyledClippingRect {
        id: preview

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: label.top
        anchors.topMargin: Appearance.padding.xl
        anchors.bottomMargin: Appearance.spacing.lg

        implicitWidth: parent.height

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.small

        Loader {
            anchors.centerIn: parent
            active: !root.client
            asynchronous: true

            sourceComponent: ColumnLayout {
                spacing: 0

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "web_asset_off"
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.headlineLarge * 3
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No active client")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.headlineLarge
                    font.weight: 500
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Try switching to a window")
                    color: Colours.palette.m3outline
                    font.pointSize: Appearance.font.size.titleMedium
                }
            }
        }

        // Fallback for ScreencopyView since Niri lacks hyprland-toplevel-export-v1
        IconImage {
            id: appIcon
            
            anchors.centerIn: parent
            visible: root.client !== null
            
            // Set a large size for the icon in the preview area
            property real size: parent.height * 0.6
            width: size
            height: size
            sourceSize.width: size
            sourceSize.height: size
            
            source: Icons.getAppIcon(root.client?.app_id ?? "", "application-default-icon")
        }
    }

    StyledText {
        id: label

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.padding.xl

        animate: true
        text: {
            const client = root.client;
            if (!client)
                return qsTr("No active client");
            return qsTr("%1 → WORKSPACE: %2").arg(client.title).arg(client.workspace_id);
        }
    }
}
