import qs.components
import qs.components.misc
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

// import qs.modules.bar.popouts

ColumnLayout {
    id: root

    // Client is snapshotted by WindowInfo.qml on open.
    // DO NOT add Connections here – that would re-target on every focus change.
    property var client: null

    // Keep SysMonitorService alive while this panel is visible for live CPU/RAM
    Ref {
        service: SysMonitorService
    }

    // Resolve the live process entry for the focused window's PID
    readonly property var proc: {
        const pid = root.client?.pid;
        if (!pid || !SysMonitorService.processes) return null;
        for (let i = 0; i < SysMonitorService.processes.length; i++) {
            if (SysMonitorService.processes[i].pid === pid)
                return SysMonitorService.processes[i];
        }
        return null;
    }

    anchors.fill: parent
    spacing: Appearance.spacing.sm

    Label {
        Layout.topMargin: Appearance.padding.xl * 2

        text: root.client?.title ?? qsTr("No active client")
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

        font.pointSize: Appearance.font.size.titleMedium
        font.weight: 500
    }

    Label {
        text: root.client?.app_id ?? qsTr("No active client")
        color: Colours.palette.m3tertiary

        font.pointSize: Appearance.font.size.bodyLarge
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.leftMargin: Appearance.padding.xl * 2
        Layout.rightMargin: Appearance.padding.xl * 2
        Layout.topMargin: Appearance.spacing.lg
        Layout.bottomMargin: Appearance.spacing.xxl

        color: Colours.palette.m3secondary
    }

    // ── Layout / compositor info ──────────────────────────────────────────────

    Detail {
        icon: "location_on"
        property var adress: root.client?.layout?.pos_in_scrolling_layout ?? [-1, -1]
        text: qsTr("Address: %1, %2").arg(adress[0] ?? -1).arg(adress[1] ?? -1)
        color: Colours.palette.m3primary
    }
    Loader {
        active: root.client?.is_floating ?? false
        sourceComponent: Detail {
            icon: "location_searching"
            property var pos: root.client?.layout?.tile_pos_in_workspace_view ?? [-1, -1]
            text: qsTr("Position: %1, %2").arg(pos[0] ?? -1).arg(pos[1] ?? -1)
        }
    }

    Detail {
        icon: "resize"
        property var size: root.client?.layout?.window_size ?? [-1, -1]
        text: qsTr("Size: %1 x %2").arg(size[0] ?? -1).arg(size[1] ?? -1)
        color: Colours.palette.m3tertiary
    }

    Detail {
        icon: "workspaces"
        text: {
            const workspaceId = root.client?.workspace_id;
            if (workspaceId !== undefined && workspaceId !== null) {
                const ws = Niri.currentOutputWorkspaces.find(w => w.id === workspaceId);
                return qsTr("Workspace: %1 (%2)").arg(ws?.name ?? "unknown").arg(workspaceId);
            }
            return qsTr("Workspace: unknown");
        }
        color: Colours.palette.m3secondary
    }

    Detail {
        icon: "desktop_windows"
        text: {
            if (!Niri.focusedMonitorName || !Niri.outputs)
                return qsTr("Monitor: unknown");
            const mon = Niri.outputs[Niri.focusedMonitorName];
            if (!mon)
                return qsTr("Monitor: unknown");
            const modes = mon.modes?.[0];
            if (!modes)
                return qsTr("Monitor: %1").arg(mon.name ?? "unknown");
            const scale = mon.logical?.scale ?? 1;
            return qsTr("Monitor: %1 (%3px x %4px) @(%2) #(%5)").arg(mon.name ?? "unknown").arg(modes.refresh_rate ?? 0).arg(modes.width ?? 0).arg(modes.height ?? 0).arg(scale);
        }
    }

    Detail {
        icon: "category"
        text: qsTr("App ID: %1").arg(root.client?.app_id ?? "unknown")
    }

    Detail {
        icon: "account_tree"
        text: qsTr("Process id: %1").arg(root.client?.pid ?? -1)
        color: Colours.palette.m3primary
    }

    Detail {
        icon: "picture_in_picture_center"
        text: qsTr("Floating: %1").arg(root.client?.is_floating ? "yes" : "no")
        color: Colours.palette.m3secondary
    }

    // ── Live process stats (CPU / RAM) ────────────────────────────────────────

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.leftMargin: Appearance.padding.xl * 2
        Layout.rightMargin: Appearance.padding.xl * 2
        Layout.topMargin: Appearance.spacing.lg
        Layout.bottomMargin: Appearance.spacing.sm
        color: Colours.palette.m3secondary
        opacity: 0.5
    }

    Detail {
        icon: "memory"
        text: {
            if (!root.proc) return qsTr("CPU: N/A");
            return qsTr("CPU: %1").arg(SysMonitorService.formatCpuUsage(root.proc.cpu));
        }
        color: {
            if (!root.proc) return Colours.palette.m3onSurface;
            if (root.proc.cpu > 80) return Colours.palette.error;
            if (root.proc.cpu > 50) return Colours.palette.warning;
            return Colours.palette.m3primary;
        }
    }

    Detail {
        icon: "sd_card"
        text: {
            if (!root.proc) return qsTr("RAM: N/A");
            return qsTr("RAM: %1").arg(SysMonitorService.formatMemoryUsage(root.proc.memoryKB));
        }
        color: {
            if (!root.proc) return Colours.palette.m3onSurface;
            if (root.proc.memoryKB > 1024 * 1024) return Colours.palette.error;
            if (root.proc.memoryKB > 512 * 1024) return Colours.palette.warning;
            return Colours.palette.m3tertiary;
        }
    }

    Item {
        Layout.fillHeight: true
    }

    component Detail: RowLayout {
        id: detail

        required property string icon
        required property string text
        property alias color: icon.color

        Layout.leftMargin: Appearance.padding.xl
        Layout.rightMargin: Appearance.padding.xl
        Layout.fillWidth: true

        spacing: Appearance.spacing.md

        MaterialIcon {
            id: icon

            Layout.alignment: Qt.AlignVCenter
            text: detail.icon
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            text: detail.text
            elide: Text.ElideRight
            font.pointSize: Appearance.font.size.bodyMedium
        }
    }

    component Label: StyledText {
        Layout.leftMargin: Appearance.padding.xl
        Layout.rightMargin: Appearance.padding.xl
        Layout.fillWidth: true
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        animate: true
    }
}
