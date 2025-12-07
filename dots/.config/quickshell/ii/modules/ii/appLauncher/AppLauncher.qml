import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

Scope {
    id: appLauncherScope

    Variants {
        id: appLauncherVariants
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            property string searchQuery: ""
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            screen: modelData
            visible: GlobalStates.appLauncherOpen

            WlrLayershell.namespace: "quickshell:applauncher"
            WlrLayershell.layer: WlrLayer.Overlay
            color: "transparent"

            mask: Region {
                item: GlobalStates.appLauncherOpen ? mainContent : null
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            HyprlandFocusGrab {
                id: grab
                windows: [root]
                property bool canBeActive: root.monitorIsFocused
                active: false
                onCleared: () => {
                    if (!active)
                        GlobalStates.appLauncherOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onAppLauncherOpenChanged() {
                    if (!GlobalStates.appLauncherOpen) {
                        grab.active = false;
                        root.searchQuery = "";
                        searchInput.text = "";
                    } else {
                        delayedGrabTimer.start();
                        searchInput.forceActiveFocus();
                    }
                }
            }

            Timer {
                id: delayedGrabTimer
                interval: Config.options.hacks.arbitraryRaceConditionDelay
                repeat: false
                onTriggered: {
                    if (!grab.canBeActive)
                        return;
                    grab.active = GlobalStates.appLauncherOpen;
                }
            }

            FocusScope {
                id: mainContent
                visible: GlobalStates.appLauncherOpen
                focus: GlobalStates.appLauncherOpen
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 100
                }
                width: 600
                height: searchBar.height + appList.height + 20

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.appLauncherOpen = false;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        if (appList.count > 0) {
                            appList.currentIndex = Math.min(appList.currentIndex + 1, appList.count - 1);
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        if (appList.count > 0) {
                            appList.currentIndex = Math.max(appList.currentIndex - 1, 0);
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (appList.currentIndex >= 0 && appList.currentIndex < appResults.length) {
                            appResults[appList.currentIndex].execute();
                            GlobalStates.appLauncherOpen = false;
                        }
                        event.accepted = true;
                    }
                }

                StyledRectangularShadow {
                    target: backgroundRect
                }

                Rectangle {
                    id: backgroundRect
                    anchors.fill: parent
                    radius: 12
                    color: Appearance.colors.colBackgroundSurfaceContainer

                    Column {
                        anchors.fill: parent
                        spacing: 0

                        // Search bar
                        Rectangle {
                            id: searchBar
                            width: parent.width
                            height: 56
                            color: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                MaterialSymbol {
                                    id: searchIcon
                                    text: "search"
                                    iconSize: 24
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    color: Appearance.colors.colOnSurfaceVariant
                                }

                                TextField {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    focus: true
                                    placeholderText: "Type to search applications..."
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnSurface
                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    onTextChanged: {
                                        root.searchQuery = text;
                                        if (appList.count > 0) {
                                            appList.currentIndex = 0;
                                        }
                                    }

                                    Keys.onPressed: event => {
                                        // Handle navigation keys
                                        if (event.key === Qt.Key_Down) {
                                            if (appList.count > 0) {
                                                appList.currentIndex = Math.min(appList.currentIndex + 1, appList.count - 1);
                                            }
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Up) {
                                            if (appList.count > 0) {
                                                appList.currentIndex = Math.max(appList.currentIndex - 1, 0);
                                            }
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            if (appList.currentIndex >= 0 && appList.currentIndex < appResults.length) {
                                                appResults[appList.currentIndex].execute();
                                                GlobalStates.appLauncherOpen = false;
                                            }
                                            event.accepted = true;
                                        } else if (event.key === Qt.Key_Escape) {
                                            GlobalStates.appLauncherOpen = false;
                                            event.accepted = true;
                                        }
                                    }
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Appearance.colors.colOutlineVariant
                        }

                        // App list
                        ListView {
                            id: appList
                            width: parent.width
                            height: Math.min(400, contentHeight)
                            clip: true
                            highlightMoveDuration: 100
                            highlightFollowsCurrentItem: true
                            currentIndex: 0

                            model: ScriptModel {
                                id: appListModel
                                objectProp: "id"
                                values: appResults
                            }

                            highlight: Rectangle {
                                color: Appearance.colors.colPrimaryContainer
                                radius: 8
                            }

                            delegate: ItemDelegate {
                                required property var modelData
                                required property int index
                                width: appList.width
                                height: 48

                                background: Rectangle {
                                    color: parent.hovered ? Appearance.colors.colSurfaceContainerHigh : "transparent"
                                    radius: 8
                                }

                                onClicked: {
                                    modelData.execute();
                                    GlobalStates.appLauncherOpen = false;
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    IconImage {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        source: Quickshell.iconPath(parent.parent.modelData.icon || "application-x-executable", "image-missing")
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: parent.parent.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnSurface
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            property var appResults: []

            Timer {
                id: searchTimer
                interval: 100
                onTriggered: {
                    root.appResults = AppSearch.fuzzyQuery(root.searchQuery).slice(0, 15);
                }
            }

            onSearchQueryChanged: {
                searchTimer.restart();
            }

            Component.onCompleted: {
                root.appResults = AppSearch.fuzzyQuery("").slice(0, 15);
            }
        }
    }

    IpcHandler {
        target: "appLauncher"

        function toggle() {
            GlobalStates.appLauncherOpen = !GlobalStates.appLauncherOpen;
        }

        function open() {
            GlobalStates.appLauncherOpen = true;
        }

        function close() {
            GlobalStates.appLauncherOpen = false;
        }
    }

    GlobalShortcut {
        name: "appLauncherToggle"
        description: "Toggles app launcher on press"

        onPressed: {
            GlobalStates.appLauncherOpen = !GlobalStates.appLauncherOpen;
        }
    }

    GlobalShortcut {
        name: "appLauncherToggleRelease"
        description: "Toggles app launcher on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = true;
        }

        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.appLauncherOpen = !GlobalStates.appLauncherOpen;
        }
    }

    GlobalShortcut {
        name: "appLauncherToggleReleaseInterrupt"
        description: "Interrupts possibility of app launcher being toggled on release"

        onPressed: {
            GlobalStates.superReleaseMightTrigger = false;
        }
    }
}
