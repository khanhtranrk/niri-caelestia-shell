// caelestia-sddm-theme — Main.qml
// Faithful port of niri-caelestia-shell Center.qml / LockSurface.qml
// CENTER PANEL ONLY (no left/right extras panels).
//
// Visual spec from source:
//   - Blurred wallpaper + screencopy-style dim scrim
//   - Floating frosted-glass card: ~420×600px, large rounding, drop shadow
//   - Clock: bold hh:mm, primary-colored blinking colon, secondary :ss NOT used
//     (source uses hh:mm + blinking colon only, no separate seconds)
//   - Date: mono font, m3onSurfaceVariant, letter-spaced
//   - Gradient divider (fades at edges)
//   - Avatar: 96px circle, secondaryContainer bg, primary accent ring
//   - Username: bodyMedium, mono, m3onSurfaceVariant
//   - Password bar: full-width pill, surfaceContainerHigh@0.75,
//     lock icon | animated dot chars | arrow button (→ turns primary on input)
//   - Status area: error in m3error, caps/kb in m3onSurfaceVariant
//   - Bottom bar: session + keyboard (SDDM ComboBox) + power buttons

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import SddmComponents

Rectangle {
    id: root
    width:  Screen.width
    height: Screen.height

    // ── Material You color tokens ─────────────────────────────────────────
    // Names match m3 spec; patched by Matugen / apply script.
    property color m3background:             "#111118"
    property color m3surface:                "#1c1b1f"
    property color m3surfaceContainer:        "#211f26"
    property color m3surfaceContainerHigh:    "#2b2930"
    property color m3surfaceContainerHighest: "#36343b"
    property color m3primary:                "#d0bcff"
    property color m3onPrimary:              "#21005d"
    property color m3primaryContainer:       "#4f378b"
    property color m3secondary:              "#cbc2db"
    property color m3secondaryContainer:     "#4a4458"
    property color m3onSecondaryContainer:   "#e8def8"
    property color m3onSurface:              "#e6e1e5"
    property color m3onSurfaceVariant:       "#cac4d0"
    property color m3outlineVariant:         "#49454f"
    property color m3error:                  "#f2b8b5"
    property color m3shadow:                 "#000000"

    // ── Config ────────────────────────────────────────────────────────────
    property string wallpaperPath:  ""
    property bool   blurWallpaper:  true
    property int    blurRadius:     64
    property real   dimOpacity:     0.20
    property string fontClock:      "Rubik"
    property string fontUi:         "Rubik"
    property string fontMono:       "JetBrains Mono Nerd Font"
    property bool   showAvatar:     true
    property int    animMs:         300

    // Derived sizing — matches panelScale logic from source
    readonly property real panelScale:  Math.min(1.0, root.height / 1080)
    readonly property int  panelWidth:  Math.round(420 * panelScale)
    readonly property int  panelHeight: Math.round(600 * panelScale)
    readonly property int  panelRadius: Math.round(28 * panelScale)   // rounding.large * 1.5

    // ── Auth state ────────────────────────────────────────────────────────
    property string pwBuffer:   ""
    property bool   authFailed: false
    property string statusMsg:  ""

    color: m3background

    // ═══════════════════════════════════════════════════════════════════════
    // BACKGROUND LAYERS  (matches LockSurface.qml layer stack)
    // ═══════════════════════════════════════════════════════════════════════

    // Layer 0: solid surface fallback
    Rectangle {
        anchors.fill: parent
        color: root.m3surface
    }

    // Layer 1: blurred wallpaper
    Image {
        id: wallImg
        anchors.fill: parent
        source: wallpaperPath !== ""
            ? (wallpaperPath.indexOf("file://") === 0
                ? wallpaperPath
                : "file://" + wallpaperPath)
            : ""
        fillMode:     Image.PreserveAspectCrop
        asynchronous: true
        cache:        false
        visible:      false
    }

    MultiEffect {
        source:         wallImg
        anchors.fill:   parent
        visible:        wallImg.status === Image.Ready
        blurEnabled:    blurWallpaper
        blur:           blurWallpaper ? 1.0 : 0.0
        blurMax:        blurRadius
        blurMultiplier: 1.0
    }

    // Layer 2: dark scrim (dimScrim in source — subtle, 0.20)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, dimOpacity)
    }

    // ═══════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════

    Connections {
        target: sddm
        function onLoginFailed() {
            root.authFailed = true
            root.statusMsg  = "Incorrect password. Please try again."
            root.pwBuffer   = ""
            failTimer.restart()
        }
        function onLoginSucceeded() {
            root.authFailed = false
            root.statusMsg  = ""
            root.pwBuffer   = ""
        }
    }

    Timer {
        id: failTimer
        interval: 4000
        onTriggered: {
            root.authFailed = false
            root.statusMsg  = ""
        }
    }

    function doLogin() {
        if (pwInput.text.length === 0) return
        root.pwBuffer = pwInput.text
        var u = (typeof userModel !== "undefined" && userModel.lastUser !== "")
                    ? userModel.lastUser : "user"
        sddm.login(u, pwInput.text, sessionModel.lastIndex)
    }

    // ═══════════════════════════════════════════════════════════════════════
    // FLOATING CARD  (lockContent + lockBg from LockSurface.qml)
    // ═══════════════════════════════════════════════════════════════════════

    Item {
        id: lockContent
        anchors.centerIn: parent
        width:  root.panelWidth
        height: root.panelHeight

        // Entry animation: scale from 0 + fade in (mirrors initAnim in source)
        scale:   0.88
        opacity: 0.0
        Component.onCompleted: cardEntryAnim.start()
        ParallelAnimation {
            id: cardEntryAnim
            NumberAnimation {
                target: lockContent; property: "opacity"
                from: 0.0; to: 1.0
                duration: root.animMs * 2
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockContent; property: "scale"
                from: 0.88; to: 1.0
                duration: root.animMs * 2
                easing.type: Easing.OutBack
            }
        }

        // Frosted glass card background (lockBg in source)
        Rectangle {
            id: lockBg
            anchors.fill: parent
            radius: root.panelRadius
            color: Qt.rgba(
                root.m3surfaceContainer.r,
                root.m3surfaceContainer.g,
                root.m3surfaceContainer.b,
                0.85
            )
        }

        // Subtle inner border (depth layer in source)
        Rectangle {
            anchors.fill: parent
            radius: root.panelRadius
            color: "transparent"
            border {
                width: 1
                color: Qt.rgba(root.m3outlineVariant.r, root.m3outlineVariant.g, root.m3outlineVariant.b, 0.50)
            }
        }

        // Drop shadow (layer.effect MultiEffect in source)
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled:         true
            blurMax:               36
            shadowVerticalOffset:  8
            shadowHorizontalOffset: 0
            shadowBlur:            0.7
            shadowColor:           Qt.rgba(0, 0, 0, 0.45)
        }

        // ── CENTER CONTENT  (Center.qml → ColumnLayout) ───────────────────
        ColumnLayout {
            id: centerCol
            anchors {
                fill:    parent
                margins: Math.round(24 * root.panelScale)
            }
            spacing: 0

            // Flex top spacer (1 part)
            Item {
                Layout.fillHeight:    true
                Layout.preferredHeight: 1
            }

            // ── CLOCK ──────────────────────────────────────────────────────
            // Source: two StyledText (hours + minutes) with blinking primary colon between
            Item {
                Layout.fillWidth:  true
                Layout.bottomMargin: Math.round(4 * root.panelScale)
                implicitHeight: clockRow.implicitHeight

                Timer {
                    interval: 1000; repeat: true; running: true; triggeredOnStart: true
                    onTriggered: {
                        var n = new Date()
                        clockHours.text   = Qt.formatTime(n, "hh")
                        clockMinutes.text = Qt.formatTime(n, "mm")
                        clockDate.text    = Qt.formatDate(n, "dddd, d MMMM yyyy")
                        // Blink colon: flash on each second tick
                        colonText.opacity = 1.0
                        colonFade.restart()
                    }
                }

                Row {
                    id: clockRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Math.round(2 * root.panelScale)

                    Text {
                        id: clockHours
                        font {
                            family:    root.fontClock
                            pixelSize: Math.round(82 * root.panelScale)
                            weight:    Font.Bold
                        }
                        color: root.m3onSurface
                    }

                    // Blinking colon — primary color, matches source exactly
                    Text {
                        id: colonText
                        text: ":"
                        font {
                            family:    root.fontClock
                            pixelSize: Math.round(82 * root.panelScale)
                            weight:    Font.Bold
                        }
                        color: root.m3primary
                        opacity: 1.0

                        SequentialAnimation {
                            id: colonFade
                            PauseAnimation { duration: 300 }
                            NumberAnimation {
                                target: colonText; property: "opacity"
                                to: 0.25
                                duration: 300
                                easing.type: Easing.InOutSine
                            }
                            PauseAnimation { duration: 100 }
                            NumberAnimation {
                                target: colonText; property: "opacity"
                                to: 1.0
                                duration: 300
                                easing.type: Easing.InOutSine
                            }
                        }
                    }

                    Text {
                        id: clockMinutes
                        font {
                            family:    root.fontClock
                            pixelSize: Math.round(82 * root.panelScale)
                            weight:    Font.Bold
                        }
                        color: root.m3onSurface
                    }
                }
            }

            // ── DATE ───────────────────────────────────────────────────────
            // Source: mono font, m3onSurfaceVariant, bodyMedium size
            Text {
                id: clockDate
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Math.round(4 * root.panelScale)
                font {
                    family:        root.fontMono
                    pixelSize:     Math.round(13 * root.panelScale)
                    letterSpacing: 0.5
                }
                color: root.m3onSurfaceVariant
            }

            // ── GRADIENT DIVIDER ───────────────────────────────────────────
            // Source: 1px, fades to transparent at both ends
            Rectangle {
                Layout.fillWidth:    true
                Layout.topMargin:    Math.round(16 * root.panelScale)
                Layout.bottomMargin: Math.round(16 * root.panelScale)
                Layout.leftMargin:   Math.round(20 * root.panelScale)
                Layout.rightMargin:  Math.round(20 * root.panelScale)
                height: 1
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.00; color: "transparent" }
                    GradientStop { position: 0.15; color: Qt.rgba(root.m3outlineVariant.r, root.m3outlineVariant.g, root.m3outlineVariant.b, 0.60) }
                    GradientStop { position: 0.85; color: Qt.rgba(root.m3outlineVariant.r, root.m3outlineVariant.g, root.m3outlineVariant.b, 0.60) }
                    GradientStop { position: 1.00; color: "transparent" }
                }
            }

            // ── AVATAR ─────────────────────────────────────────────────────
            // Source: 96px circle, secondaryContainer bg, primary accent ring (margin -3)
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Math.round(8 * root.panelScale)
                implicitWidth:  avatarSize
                implicitHeight: avatarSize
                visible: root.showAvatar

                readonly property int avatarSize: Math.round(96 * root.panelScale)

                // secondaryContainer circle background
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(root.m3secondaryContainer.r, root.m3secondaryContainer.g, root.m3secondaryContainer.b, 0.55)
                }

                // Primary accent ring (border at -3px margin like source)
                Rectangle {
                    anchors {
                        fill:    parent
                        margins: -3
                    }
                    radius: width / 2
                    color:  "transparent"
                    border {
                        width: 2
                        color: Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.45)
                    }
                }

                // Avatar image — clipped circle
                Rectangle {
                    id: avatarClip
                    anchors.fill: parent
                    radius: width / 2
                    clip:   true
                    color:  "transparent"

                    // ~/.face first
                    Image {
                        id: faceImg
                        anchors.fill: parent
                        source: {
                            if (typeof userModel === "undefined") return ""
                            var u = userModel.lastUser
                            return (u !== "") ? "file:///home/" + u + "/.face" : ""
                        }
                        fillMode:     Image.PreserveAspectCrop
                        asynchronous: true
                        visible:      status === Image.Ready
                    }

                    // AccountsService fallback
                    Image {
                        id: accountImg
                        anchors.fill: parent
                        source: {
                            if (typeof userModel === "undefined") return ""
                            var u = userModel.lastUser
                            return (faceImg.status !== Image.Ready && u !== "")
                                ? "file:///var/lib/AccountsService/icons/" + u : ""
                        }
                        fillMode:     Image.PreserveAspectCrop
                        asynchronous: true
                        visible:      status === Image.Ready && faceImg.status !== Image.Ready
                    }

                    // Person icon fallback (Material Symbols text glyph)
                    Text {
                        anchors.centerIn: parent
                        visible: faceImg.status !== Image.Ready && accountImg.status !== Image.Ready
                        text: "\uE7FD"
                        font {
                            family:    "Material Symbols Rounded"
                            pixelSize: Math.round(parent.width * 0.50)
                        }
                        color: root.m3onSurfaceVariant
                    }
                }
            }

            // ── USERNAME ───────────────────────────────────────────────────
            // Source: SysInfo.user, bodyMedium, mono, m3onSurfaceVariant, Font.Medium
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Math.round(8 * root.panelScale)
                text: (typeof userModel !== "undefined" && userModel.lastUser !== "")
                          ? userModel.lastUser : "user"
                font {
                    family:    root.fontMono
                    pixelSize: Math.round(13 * root.panelScale)
                    weight:    Font.Medium
                }
                color: root.m3onSurfaceVariant
            }

            // ── PASSWORD INPUT BAR ─────────────────────────────────────────
            // Source: full-width pill, surfaceContainerHigh@0.75
            //   [lock icon] [password dots] [→ button, turns primary on input]
            Rectangle {
                id: inputBar
                Layout.fillWidth:    true
                Layout.topMargin:    Math.round(12 * root.panelScale)
                Layout.leftMargin:   Math.round(4 * root.panelScale)
                Layout.rightMargin:  Math.round(4 * root.panelScale)
                implicitHeight: Math.round(52 * root.panelScale)
                radius: implicitHeight / 2

                color: Qt.rgba(
                    root.m3surfaceContainerHigh.r,
                    root.m3surfaceContainerHigh.g,
                    root.m3surfaceContainerHigh.b,
                    0.75
                )

                border {
                    width: pwInput.activeFocus ? 2 : 0
                    color: root.m3primary
                }

                Behavior on border.width { NumberAnimation { duration: 120 } }

                Row {
                    anchors {
                        fill:        parent
                        leftMargin:  Math.round(14 * root.panelScale)
                        rightMargin: Math.round(8  * root.panelScale)
                    }
                    spacing: Math.round(10 * root.panelScale)

                    // Lock / fingerprint icon
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.authFailed ? "\uE899" : "\uE897"
                        font {
                            family:    "Material Symbols Rounded"
                            pixelSize: Math.round(20 * root.panelScale)
                        }
                        color: root.authFailed
                            ? root.m3error
                            : pwInput.activeFocus
                                ? root.m3secondary
                                : root.m3onSurfaceVariant

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // Actual password TextField (invisible — drives the dot display)
                    TextField {
                        id: pwInput
                        width:  parent.width
                                - lockIcon.width
                                - submitBtn.width
                                - parent.spacing * 2
                                - Math.round(22 * root.panelScale)
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter

                        echoMode:          TextInput.Password
                        passwordCharacter: "\u25CF"   // filled circle
                        placeholderText:   root.authFailed ? "Incorrect password" : ""

                        font {
                            family:    root.fontMono
                            pixelSize: Math.round(14 * root.panelScale)
                        }

                        color:                root.m3onSurface
                        placeholderTextColor: Qt.rgba(root.m3error.r, root.m3error.g, root.m3error.b, 0.70)
                        selectionColor:       Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.35)

                        background: Item {}

                        Keys.onReturnPressed: doLogin()
                        Keys.onEnterPressed:  doLogin()
                        Component.onCompleted: forceActiveFocus()
                    }

                    // Submit button — turns m3primary when there is input (matches source)
                    Rectangle {
                        id: submitBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width:  Math.round(36 * root.panelScale)
                        height: Math.round(36 * root.panelScale)
                        radius: width / 2

                        color: pwInput.text.length > 0
                            ? root.m3primary
                            : Qt.rgba(root.m3surfaceContainerHigh.r, root.m3surfaceContainerHigh.g, root.m3surfaceContainerHigh.b, 0.80)

                        Behavior on color { ColorAnimation { duration: root.animMs } }

                        Text {
                            anchors.centerIn: parent
                            text: "\uE5C8"   // arrow_forward (Material Symbols)
                            font {
                                family:    "Material Symbols Rounded"
                                pixelSize: Math.round(18 * root.panelScale)
                            }
                            color: pwInput.text.length > 0
                                ? root.m3onPrimary
                                : root.m3onSurface

                            Behavior on color { ColorAnimation { duration: root.animMs } }
                        }

                        MouseArea {
                            id: submitMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    doLogin()
                        }
                    }
                }

                // Invisible alias so lockIcon id resolves for width calculation
                Text {
                    id: lockIcon
                    visible: false
                    text: "\uE897"
                    font {
                        family:    "Material Symbols Rounded"
                        pixelSize: Math.round(20 * root.panelScale)
                    }
                }
            }

            // ── STATUS MESSAGES ────────────────────────────────────────────
            // Source: error (m3error) + caps/kb hint (m3onSurfaceVariant), mono
            Item {
                Layout.fillWidth:    true
                Layout.topMargin:    Math.round(8  * root.panelScale)
                Layout.bottomMargin: Math.round(8  * root.panelScale)
                Layout.leftMargin:   Math.round(4  * root.panelScale)
                Layout.rightMargin:  Math.round(4  * root.panelScale)
                implicitHeight: Math.round(20 * root.panelScale)

                Text {
                    id: errorText
                    anchors {
                        left:  parent.left
                        right: parent.right
                    }
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text:    root.statusMsg
                    color:   root.m3error
                    opacity: root.authFailed ? 1.0 : 0.0
                    font {
                        family:    root.fontMono
                        pixelSize: Math.round(12 * root.panelScale)
                    }
                    Behavior on opacity { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                }
            }

            // Flex bottom spacer (2 parts — matches source ratio)
            Item {
                Layout.fillHeight:    true
                Layout.preferredHeight: 2
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BOTTOM BAR  — session | keyboard | power
    // Uses SDDM native ComboBox API (model/index/valueChanged — not QtQuick.Controls)
    // ═══════════════════════════════════════════════════════════════════════

    Item {
        id: bottomBar
        anchors {
            left:         parent.left
            right:        parent.right
            bottom:       parent.bottom
            bottomMargin: 20
        }
        height: 40

        // ── Session pill ──────────────────────────────────────────────────
        Rectangle {
            anchors {
                left:           parent.left
                leftMargin:     28
                verticalCenter: parent.verticalCenter
            }
            height: 32
            radius: 16
            width: sessionIconText.implicitWidth + sessionCombo.width + 28
            color: Qt.rgba(root.m3surfaceContainer.r, root.m3surfaceContainer.g, root.m3surfaceContainer.b, 0.75)
            border {
                width: 1
                color: Qt.rgba(root.m3outlineVariant.r, root.m3outlineVariant.g, root.m3outlineVariant.b, 0.40)
            }

            Text {
                id: sessionIconText
                anchors {
                    left:           parent.left
                    leftMargin:     12
                    verticalCenter: parent.verticalCenter
                }
                text: "\ue84f"
                font { family: "Material Symbols Rounded"; pixelSize: 14 }
                color: root.m3onSurfaceVariant
            }

            ComboBox {
                id: sessionCombo
                anchors {
                    left:           sessionIconText.right
                    right:          parent.right
                    rightMargin:    6
                    verticalCenter: parent.verticalCenter
                }
                width:  140
                height: 24
                model:       sessionModel
                index:       sessionModel.lastIndex
                color:       "transparent"
                menuColor:   Qt.rgba(root.m3surfaceContainerHigh.r, root.m3surfaceContainerHigh.g, root.m3surfaceContainerHigh.b, 0.97)
                textColor:   root.m3onSurface
                borderColor: "transparent"
                hoverColor:  Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.18)
                focusColor:  Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.35)
                font.family:    root.fontUi
                font.pixelSize: 12
                onValueChanged: sessionModel.lastIndex = id
            }
        }

        // ── Keyboard pill ─────────────────────────────────────────────────
        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter:   parent.verticalCenter
            }
            height: 32
            radius: 16
            width: kbIconText.implicitWidth + kbCombo.width + 28
            color: Qt.rgba(root.m3surfaceContainer.r, root.m3surfaceContainer.g, root.m3surfaceContainer.b, 0.75)
            border {
                width: 1
                color: Qt.rgba(root.m3outlineVariant.r, root.m3outlineVariant.g, root.m3outlineVariant.b, 0.40)
            }

            Text {
                id: kbIconText
                anchors {
                    left:           parent.left
                    leftMargin:     12
                    verticalCenter: parent.verticalCenter
                }
                text: "\ue312"
                font { family: "Material Symbols Rounded"; pixelSize: 14 }
                color: root.m3onSurfaceVariant
            }

            ComboBox {
                id: kbCombo
                anchors {
                    left:           kbIconText.right
                    right:          parent.right
                    rightMargin:    6
                    verticalCenter: parent.verticalCenter
                }
                width:  150
                height: 24
                model:       keyboard.layouts
                index:       keyboard.currentLayout
                color:       "transparent"
                menuColor:   Qt.rgba(root.m3surfaceContainerHigh.r, root.m3surfaceContainerHigh.g, root.m3surfaceContainerHigh.b, 0.97)
                textColor:   root.m3onSurface
                borderColor: "transparent"
                hoverColor:  Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.18)
                focusColor:  Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.35)
                font.family:    root.fontUi
                font.pixelSize: 12
                onValueChanged: keyboard.currentLayout = id
            }
        }

        // ── Power pill ────────────────────────────────────────────────────
        Rectangle {
            anchors {
                right:          parent.right
                rightMargin:    28
                verticalCenter: parent.verticalCenter
            }
            height: 32
            radius: 16
            width: 112
            color: Qt.rgba(root.m3surfaceContainer.r, root.m3surfaceContainer.g, root.m3surfaceContainer.b, 0.75)
            border {
                width: 1
                color: Qt.rgba(root.m3outlineVariant.r, root.m3outlineVariant.g, root.m3outlineVariant.b, 0.40)
            }

            Row {
                anchors.centerIn: parent
                spacing: 0

                // Suspend
                Item {
                    width: 36; height: 32
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 13
                        color: sMa.pressed
                            ? Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.28)
                            : sMa.containsMouse
                                ? Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.16)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: "\uef44"
                            font { family: "Material Symbols Rounded"; pixelSize: 15 }
                            color: sMa.containsMouse ? root.m3primary : root.m3onSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                    MouseArea {
                        id: sMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.suspend()
                    }
                }

                // Reboot
                Item {
                    width: 36; height: 32
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 13
                        color: rMa.pressed
                            ? Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.28)
                            : rMa.containsMouse
                                ? Qt.rgba(root.m3primary.r, root.m3primary.g, root.m3primary.b, 0.16)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: "\uf053"
                            font { family: "Material Symbols Rounded"; pixelSize: 16 }
                            color: rMa.containsMouse ? root.m3primary : root.m3onSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                    MouseArea {
                        id: rMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.reboot()
                    }
                }

                // Power off
                Item {
                    width: 36; height: 32
                    Rectangle {
                        anchors.centerIn: parent
                        width: 26; height: 26; radius: 13
                        color: pMa.pressed
                            ? Qt.rgba(root.m3error.r, root.m3error.g, root.m3error.b, 0.28)
                            : pMa.containsMouse
                                ? Qt.rgba(root.m3error.r, root.m3error.g, root.m3error.b, 0.16)
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text {
                            anchors.centerIn: parent
                            text: "\ue8ac"
                            font { family: "Material Symbols Rounded"; pixelSize: 16 }
                            color: pMa.containsMouse ? root.m3error : root.m3onSurfaceVariant
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                    MouseArea {
                        id: pMa; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }

        // Bar fade-in
        opacity: 0
        Component.onCompleted: barFade.start()
        NumberAnimation {
            id: barFade
            target: bottomBar; property: "opacity"
            from: 0; to: 1
            duration: root.animMs * 3
            easing.type: Easing.OutCubic
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // VIRTUAL KEYBOARD (optional)
    // ═══════════════════════════════════════════════════════════════════════

    Loader {
        z: 99
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        active: false
        source: active ? "Components/VirtualKeyboard.qml" : ""
        onStatusChanged: {
            if (status === Loader.Error)
                console.log("[caelestia-sddm] qt6-virtualkeyboard not installed")
        }
    }
}
