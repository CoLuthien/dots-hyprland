import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    required property var modelData
    screen: modelData
    visible: GlobalStates.clipboardWidgetOpen

    WlrLayershell.namespace: "quickshell:clipboardWidget"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    HyprlandFocusGrab {
        active: root.visible
        windows: [root]
        onActiveChanged: {
            if (!active && root.visible) {
                GlobalStates.clipboardWidgetOpen = false;
            }
        }
    }

    color: "transparent"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Rectangle {
        id: backgroundOverlay
        anchors.fill: parent
        color: "black"
        opacity: GlobalStates.clipboardWidgetOpen ? 0.5 : 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.clipboardWidgetOpen = false
        }
    }

    ClipboardWidgetContent {
        id: content
        anchors.centerIn: parent
        width: Math.min(600, parent.width - 40)
        height: Math.min(700, parent.height - 40)

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.clipboardWidgetOpen = false;
                event.accepted = true;
            }
        }
    }
}
