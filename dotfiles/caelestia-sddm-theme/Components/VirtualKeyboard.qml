// VirtualKeyboard.qml — loaded only when qt6-virtualkeyboard is installed
// This file is loaded via Loader in Main.qml so a missing module won't crash

import QtQuick 2.15
import QtQuick.VirtualKeyboard 2.1

InputPanel {
    id: vkb
    z: 99
    visible: Qt.inputMethod.visible
}
