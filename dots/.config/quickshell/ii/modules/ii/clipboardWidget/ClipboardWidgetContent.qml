import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string searchText: ""

    Component.onCompleted: {
        Cliphist.refresh();
    }

    Connections {
        target: GlobalStates
        function onClipboardWidgetOpenChanged() {
            if (GlobalStates.clipboardWidgetOpen) {
                Cliphist.refresh();
                // Force focus on search field when widget opens
                searchField.forceActiveFocus();
            }
        }
    }

    StyledRectangularShadow {
        target: mainRect
    }

    Rectangle {
        id: mainRect
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: Appearance.colors.colBackgroundSurfaceContainer

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                spacing: 10

                MaterialSymbol {
                    text: "content_paste"
                    iconSize: 24
                    color: Appearance.m3colors.m3onSurface
                }

                StyledText {
                    text: Translation.tr("Clipboard History")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.m3colors.m3onSurface
                }

                Item { Layout.fillWidth: true }

                // Clear all button
                RippleButton {
                    implicitWidth: 100
                    implicitHeight: 32
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    colRipple: Appearance.colors.colErrorContainerActive
                    buttonRadius: Appearance.rounding.normal

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        MaterialSymbol {
                            text: "delete_sweep"
                            iconSize: 18
                            color: Appearance.colors.colOnErrorContainer
                        }

                        StyledText {
                            text: Translation.tr("Clear")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnErrorContainer
                        }
                    }

                    onClicked: {
                        Cliphist.wipe();
                    }

                    StyledToolTip {
                        text: Translation.tr("Clear clipboard history")
                    }
                }

                // Close button
                RippleButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    colBackgroundHover: Appearance.colors.colPrimaryContainer
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    buttonRadius: Appearance.rounding.full

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 20
                        color: Appearance.m3colors.m3onSurface
                    }

                    onClicked: GlobalStates.clipboardWidgetOpen = false

                    StyledToolTip {
                        text: Translation.tr("Close")
                    }
                }
            }

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 40
                Layout.maximumHeight: 40
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    MaterialSymbol {
                        text: "search"
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: Translation.tr("Search clipboard...")
                        color: Appearance.m3colors.m3onSurface
                        placeholderTextColor: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                        background: Item {}
                        selectByMouse: true

                        KeyNavigation.down: clipboardList

                        onTextChanged: root.searchText = text

                        Component.onCompleted: forceActiveFocus()

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                if (clipboardList.count > 0) {
                                    clipboardList.forceActiveFocus();
                                    clipboardList.currentIndex = 0;
                                }
                                event.accepted = true;
                            }
                        }
                    }

                    Loader {
                        active: searchField.text.length > 0
                        sourceComponent: RippleButton {
                            implicitWidth: 24
                            implicitHeight: 24
                            colBackgroundHover: Appearance.colors.colPrimaryContainer
                            colRipple: Appearance.colors.colPrimaryContainerActive
                            buttonRadius: Appearance.rounding.full

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 16
                                color: Appearance.colors.colSubtext
                            }

                            onClicked: searchField.text = ""
                        }
                    }
                }
            }

            // Clipboard items list
            ListView {
                id: clipboardList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                topMargin: 4
                bottomMargin: 4
                focus: true
                highlightMoveDuration: 100

                KeyNavigation.up: searchField

                model: ScriptModel {
                    id: clipboardModel
                    objectProp: "entry"
                    values: {
                        const entries = Cliphist.fuzzyQuery(root.searchText);
                        return entries.slice(0, 100);
                    }
                }

                delegate: ClipboardItem {
                    required property var modelData
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    entry: modelData
                    searchQuery: root.searchText
                    focus: clipboardList.currentIndex === index
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Component.onCompleted: {
                    if (clipboardList.count > 0) {
                        clipboardList.currentIndex = 0;
                    }
                }

                Connections {
                    target: root
                    function onSearchTextChanged() {
                        if (clipboardList.count > 0) {
                            clipboardList.currentIndex = 0;
                        }
                    }
                }
            }

            // Empty state
            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                visible: clipboardList.count === 0
                active: clipboardList.count === 0

                sourceComponent: Column {
                    anchors.centerIn: parent
                    spacing: 10

                    MaterialSymbol {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "content_paste_off"
                        iconSize: 48
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.searchText.length > 0 ?
                            Translation.tr("No results found") :
                            Translation.tr("Clipboard is empty")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
