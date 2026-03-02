pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    property bool showExtras: Config.lock.showExtras ?? true
    property bool recolourLogo: Config.lock.recolourLogo ?? false
    property bool enableFprint: Config.lock.enableFprint ?? true
    property int maxFprintTries: Config.lock.maxFprintTries ?? 3
    property int centerWidth: Config.lock.sizes.centerWidth ?? 600
    property real heightMult: Config.lock.sizes.heightMult ?? 0.7
    property real ratio: Config.lock.sizes.ratio ?? (16 / 9)

    anchors.fill: parent

    function saveConfig() {
        Config.lock.showExtras = root.showExtras;
        Config.lock.recolourLogo = root.recolourLogo;
        Config.lock.enableFprint = root.enableFprint;
        Config.lock.maxFprintTries = root.maxFprintTries;
        Config.lock.sizes.centerWidth = root.centerWidth;
        Config.lock.sizes.heightMult = root.heightMult;
        Config.lock.sizes.ratio = root.ratio;
        Config.save();
    }

    ClippingRectangle {
        id: lockClippingRect
        anchors.fill: parent
        anchors.margins: Appearance.padding.md
        anchors.leftMargin: 0
        anchors.rightMargin: Appearance.padding.md

        radius: lockBorder.innerRadius
        color: "transparent"

        Loader {
            id: lockLoader
            anchors.fill: parent
            anchors.margins: Appearance.padding.xl + Appearance.padding.md
            anchors.leftMargin: Appearance.padding.xl
            anchors.rightMargin: Appearance.padding.xl

            sourceComponent: lockContentComponent
        }
    }

    InnerBorder {
        id: lockBorder
        leftThickness: 0
        rightThickness: Appearance.padding.md
    }

    Component {
        id: lockContentComponent

        StyledFlickable {
            id: lockFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: lockLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: lockFlickable
            }

            ColumnLayout {
                id: lockLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Appearance.spacing.lg

                RowLayout {
                    spacing: Appearance.spacing.md

                    StyledText {
                        text: qsTr("Lock Screen")
                        font.pointSize: Appearance.font.size.titleMedium
                        font.weight: 500
                    }
                }

                // Layout Section
                SectionContainer {
                    alignTop: true

                    StyledText {
                        text: qsTr("Layout")
                        font.pointSize: Appearance.font.size.bodyMedium
                    }

                    SwitchRow {
                        label: qsTr("Show side panels")
                        checked: root.showExtras
                        onToggled: checked => {
                            root.showExtras = checked;
                            root.saveConfig();
                        }
                    }

                    SwitchRow {
                        label: qsTr("Recolour logo")
                        checked: root.recolourLogo
                        onToggled: checked => {
                            root.recolourLogo = checked;
                            root.saveConfig();
                        }
                    }
                }

                // Authentication Section
                SectionContainer {
                    alignTop: true

                    StyledText {
                        text: qsTr("Authentication")
                        font.pointSize: Appearance.font.size.bodyMedium
                    }

                    SwitchRow {
                        label: qsTr("Fingerprint unlock")
                        checked: root.enableFprint
                        onToggled: checked => {
                            root.enableFprint = checked;
                            root.saveConfig();
                        }
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.lg

                        SliderInput {
                            Layout.fillWidth: true

                            label: qsTr("Max fingerprint attempts")
                            value: root.maxFprintTries
                            from: 1
                            to: 10
                            stepSize: 1
                            validator: IntValidator { bottom: 1; top: 10 }
                            formatValueFunction: val => Math.round(val).toString()
                            parseValueFunction: text => parseInt(text)

                            onValueModified: newValue => {
                                root.maxFprintTries = Math.round(newValue);
                                root.saveConfig();
                            }
                        }
                    }
                }

                // Sizing Section
                SectionContainer {
                    alignTop: true

                    StyledText {
                        text: qsTr("Sizing")
                        font.pointSize: Appearance.font.size.bodyMedium
                    }

                    SectionContainer {
                        contentSpacing: Appearance.spacing.lg

                        SliderInput {
                            Layout.fillWidth: true

                            label: qsTr("Center panel width")
                            value: root.centerWidth
                            from: 300
                            to: 1200
                            stepSize: 50
                            suffix: "px"
                            validator: IntValidator { bottom: 300; top: 1200 }
                            formatValueFunction: val => Math.round(val).toString()
                            parseValueFunction: text => parseInt(text)

                            onValueModified: newValue => {
                                root.centerWidth = Math.round(newValue);
                                root.saveConfig();
                            }
                        }

                        SliderInput {
                            Layout.fillWidth: true

                            label: qsTr("Height scale")
                            value: root.heightMult
                            from: 0.3
                            to: 1.0
                            stepSize: 0.05
                            decimals: 2
                            validator: DoubleValidator { bottom: 0.3; top: 1.0; decimals: 2 }

                            onValueModified: newValue => {
                                root.heightMult = newValue;
                                root.saveConfig();
                            }
                        }

                        SliderInput {
                            Layout.fillWidth: true

                            label: qsTr("Aspect ratio")
                            value: root.ratio
                            from: 1.0
                            to: 2.5
                            stepSize: 0.1
                            decimals: 1
                            validator: DoubleValidator { bottom: 1.0; top: 2.5; decimals: 1 }

                            onValueModified: newValue => {
                                root.ratio = newValue;
                                root.saveConfig();
                            }
                        }
                    }
                }
            }
        }
    }
}
