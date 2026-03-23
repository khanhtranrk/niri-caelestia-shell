// VirtualKeyboard.qml — loaded only when qt6-virtualkeyboard is installed
// This file is loaded via Loader in Main.qml so a missing module won't crash

import QtQuick
import QtQuick.VirtualKeyboard

InputPanel {
    id: vkb
    z: 99
    visible: Qt.inputMethod.visible
}
