import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool terminalLaunched: false
    property bool shouldRun: true

    // Terminal process - launched once and kept alive
    Process {
        id: terminalProcess
        running: root.shouldRun

        command: ["alacritty",
                  "--class", "dropdown-terminal",
                  "-o", "window.decorations=none",
                  "-o", "window.opacity=0.95"]

        onRunningChanged: {
            if (running) {
                root.terminalLaunched = true
            }
        }

        onExited: {
            root.terminalLaunched = false
            GlobalStates.dropdownTerminalOpen = false
        }
    }

    // Cleanup on Quickshell exit
    Component.onDestruction: {
        root.shouldRun = false
        Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "class:^(dropdown-terminal)$"])
    }

    // Monitor terminal window and show/hide it
    Connections {
        target: GlobalStates
        function onDropdownTerminalOpenChanged() {
            if (GlobalStates.dropdownTerminalOpen) {
                // If terminal is not running, restart it
                if (!root.terminalLaunched) {
                    console.log("Dropdown terminal not found, restarting...")
                    root.shouldRun = false
                    root.shouldRun = true
                } else {
                    // Show the terminal window - toggle special workspace
                    Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace", "dropdown"])
                }
            } else {
                if (root.terminalLaunched) {
                    // Hide the terminal window - toggle special workspace
                    Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace", "dropdown"])
                }
            }
        }
    }

    IpcHandler {
        target: "dropdownTerminal"

        function toggle(): void {
            GlobalStates.dropdownTerminalOpen = !GlobalStates.dropdownTerminalOpen
        }

        function close(): void {
            GlobalStates.dropdownTerminalOpen = false
        }

        function open(): void {
            GlobalStates.dropdownTerminalOpen = true
        }
    }

    GlobalShortcut {
        name: "dropdownTerminalToggle"
        description: "Toggles dropdown terminal on press"

        onPressed: {
            GlobalStates.dropdownTerminalOpen = !GlobalStates.dropdownTerminalOpen;
        }
    }

    GlobalShortcut {
        name: "dropdownTerminalOpen"
        description: "Opens dropdown terminal on press"

        onPressed: {
            GlobalStates.dropdownTerminalOpen = true;
        }
    }

    GlobalShortcut {
        name: "dropdownTerminalClose"
        description: "Closes dropdown terminal on press"

        onPressed: {
            GlobalStates.dropdownTerminalOpen = false;
        }
    }
}
