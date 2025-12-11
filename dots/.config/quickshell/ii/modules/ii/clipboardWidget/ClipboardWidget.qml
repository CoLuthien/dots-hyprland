import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: clipboardWidgetScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            screen: modelData
            visible: GlobalStates.clipboardWidgetOpen

            WlrLayershell.namespace: "quickshell:clipboardWidget"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            color: "transparent"
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
                        GlobalStates.clipboardWidgetOpen = false;
                }
            }

            Connections {
                target: GlobalStates
                function onClipboardWidgetOpenChanged() {
                    if (!GlobalStates.clipboardWidgetOpen) {
                        grab.active = false;
                    } else {
                        // Close other overlays when clipboard widget opens
                        GlobalStates.overviewOpen = false;
                        GlobalStates.appLauncherOpen = false;
                        delayedGrabTimer.start();
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
                    grab.active = GlobalStates.clipboardWidgetOpen;
                }
            }

            Rectangle {
                id: backgroundOverlay
                anchors.fill: parent
                color: "black"
                opacity: GlobalStates.clipboardWidgetOpen ? 0.5 : 0
                z: 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        // Check if click is outside content area
                        const contentX = content.x;
                        const contentY = content.y;
                        const contentWidth = content.width;
                        const contentHeight = content.height;

                        if (mouse.x < contentX || mouse.x > contentX + contentWidth ||
                            mouse.y < contentY || mouse.y > contentY + contentHeight) {
                            GlobalStates.clipboardWidgetOpen = false;
                        }
                    }
                }
            }

            ClipboardWidgetContent {
                id: content
                anchors.centerIn: parent
                width: Math.min(600, parent.width - 40)
                height: Math.min(700, parent.height - 40)
                z: 1

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.clipboardWidgetOpen = false;
                        event.accepted = true;
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "clipboardWidget"

        function toggle() {
            GlobalStates.clipboardWidgetOpen = !GlobalStates.clipboardWidgetOpen;
        }

        function open() {
            GlobalStates.clipboardWidgetOpen = true;
        }

        function close() {
            GlobalStates.clipboardWidgetOpen = false;
        }
    }
}
