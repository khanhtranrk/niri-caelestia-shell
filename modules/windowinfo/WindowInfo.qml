import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts
import "ProcessList"

Item {
    id: root

    required property ShellScreen screen

    // Snapshotted on open – not updated live so follow-mouse focus doesn't
    // change which window is being inspected. Use the Refresh button to update.
    property var client: null

    Component.onCompleted: {
        root.client = Niri.focusedWindow ?? Niri.lastFocusedWindow ?? null;
    }

    // Expose a refresh function so Buttons.qml can trigger it
    function refreshClient(): void {
        root.client = Niri.focusedWindow ?? Niri.lastFocusedWindow ?? null;
    }

    implicitWidth: child.implicitWidth
    implicitHeight: screen.height * Config.winfo.sizes.heightMult

    RowLayout {
        id: child

        anchors.fill: parent
        anchors.margins: Appearance.padding.xl

        spacing: Appearance.spacing.lg

        // Preview {
        //     screen: root.screen
        //     client: root.client
        // }

        // ProcessListPopout {
        //     id: processListPopout
        // }

        ProcessListModal {
            id: processListModal
        }

        // ProcessListModal {

        // }

        ColumnLayout {
            spacing: Appearance.spacing.lg

            Layout.preferredWidth: Config.winfo.sizes.detailsWidth
            Layout.fillHeight: true

            StyledRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                color: Colours.tPalette.m3surfaceContainer
                radius: Appearance.rounding.normal

                Details {
                    client: root.client
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: buttons.implicitHeight

                color: Colours.tPalette.m3surfaceContainer
                radius: Appearance.rounding.normal

                Buttons {
                    id: buttons

                    client: root.client
                }
            }
        }
    }
}
