import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property real padding: 4
    property var inputField: commandInput

    // Output history
    property var outputHistory: []
    property int historyIndex: -1
    property var commandHistory: []

    // Process state
    property bool pythonReady: false
    property bool isExecuting: false
    property string outputBuffer: ""
    property string promptMarker: ">>>"

    onFocusChanged: focus => {
        if (focus) {
            root.inputField.forceActiveFocus();
        }
    }

    Keys.onPressed: event => {
        commandInput.forceActiveFocus();
        if (event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageUp) {
                outputListView.contentY = Math.max(0, outputListView.contentY - outputListView.height / 2);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                outputListView.contentY = Math.min(outputListView.contentHeight - outputListView.height / 2, outputListView.contentY + outputListView.height / 2);
                event.accepted = true;
            }
        }
    }

    Component.onCompleted: {
        root.addOutput("system", "Starting IPython interpreter...");
        pythonProcess.running = true;
    }

    Component.onDestruction: {
        if (pythonProcess.running) {
            pythonProcess.write("exit()\n");
            pythonProcess.stdinEnabled = false;
            pythonProcess.running = false;
        }
    }

    // IPython REPL Process - persistent process
    Process {
        id: pythonProcess
        command: ["ipython", "--simple-prompt", "--no-confirm-exit", "--no-banner", "--colors=NoColor", "--no-autoindent"]
        running: false
        stdinEnabled: true

        stdout: SplitParser {
            onRead: data => {
                // Filter out IPython prompts and markers
                let cleanData = data
                    .replace(/^In \[\d+\]:\s*/gm, '')
                    .replace(/^Out\[\d+\]:\s*/gm, '')
                    .replace(/^\.\.\.\s*/gm, '')
                    .trim();

                // Mark as ready after first output
                if (!root.pythonReady && pythonProcess.running) {
                    root.pythonReady = true;
                    root.addOutput("system", "IPython ready");
                    return;
                }

                // Display output
                if (cleanData.length > 0 && root.isExecuting) {
                    root.addOutput("output", cleanData);
                    root.isExecuting = false;
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                let cleanData = data.trim();
                if (cleanData.length > 0) {
                    root.addOutput("error", cleanData);
                    if (root.isExecuting) {
                        root.isExecuting = false;
                    }
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.pythonReady = false;
            root.addOutput("error", "IPython process exited with code: " + exitCode + ", status: " + exitStatus);
        }

        onRunningChanged: {
            if (!running) {
                root.pythonReady = false;
            } else {
                // Mark as ready shortly after starting
                Qt.callLater(() => {
                    if (running) {
                        root.pythonReady = true;
                    }
                });
            }
        }
    }

    function executeCommand(code) {
        if (!pythonProcess.running) {
            root.addOutput("error", "IPython interpreter is not running. Restarting...");
            pythonProcess.running = true;
            // Retry after a delay
            retryTimer.code = code;
            retryTimer.start();
            return;
        }

        if (!root.pythonReady) {
            root.addOutput("error", "IPython interpreter is not ready yet. Please wait...");
            return;
        }

        root.isExecuting = true;

        // Add command to output
        root.addOutput("input", code);

        // Send command to IPython via stdin
        pythonProcess.write(code + "\n");
    }

    Timer {
        id: retryTimer
        interval: 1000
        repeat: false
        property string code: ""
        onTriggered: {
            if (code.length > 0 && root.pythonReady) {
                root.executeCommand(code);
                code = "";
            }
        }
    }

    function addOutput(type, text) {
        outputHistory.push({
            type: type,  // "input", "output", "error", "system"
            text: text,
            timestamp: new Date()
        });
        outputHistoryChanged();
        Qt.callLater(() => {
            outputListView.positionViewAtEnd();
        });
    }

    function executeInput() {
        const code = commandInput.text.trim();
        if (code.length === 0) return;

        // Add to command history
        commandHistory.push(code);
        historyIndex = commandHistory.length;

        // Execute
        executeCommand(code);

        // Clear input
        commandInput.text = "";
    }

    function clearHistory() {
        outputHistory = [];
        outputHistoryChanged();
    }

    function navigateHistory(direction) {
        if (commandHistory.length === 0) return;

        if (direction === "up") {
            historyIndex = Math.max(0, historyIndex - 1);
        } else {
            historyIndex = Math.min(commandHistory.length, historyIndex + 1);
        }

        if (historyIndex < commandHistory.length) {
            commandInput.text = commandHistory[historyIndex];
            commandInput.cursorPosition = commandInput.text.length;
        } else {
            commandInput.text = "";
        }
    }

    function restartPython() {
        if (pythonProcess.running) {
            pythonProcess.write("exit()\n");
            pythonProcess.stdinEnabled = false;
            pythonProcess.running = false;
        }
        Qt.callLater(() => {
            pythonProcess.stdinEnabled = true;
            pythonProcess.running = true;
        });
    }

    ColumnLayout {
        id: columnLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: root.padding

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 32
            radius: Appearance.rounding.normal - root.padding
            color: Appearance.colors.colLayer2

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                MaterialSymbol {
                    text: pythonProcess.running ? "circle" : "cancel"
                    iconSize: Appearance.font.pixelSize.normal
                    color: root.pythonReady ? Appearance.colors.colGreen : (pythonProcess.running ? Appearance.colors.colYellow : Appearance.colors.colRed)
                }

                StyledText {
                    text: root.pythonReady ? "IPython Ready" : (pythonProcess.running ? "Starting..." : "Stopped")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                Item { Layout.fillWidth: true }

                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.small
                    toggled: true

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.restartPython()
                    }

                    StyledToolTip {
                        text: "Restart IPython interpreter"
                        extraVisibleCondition: false
                        alternativeVisibleCondition: parent.parent.hovered
                    }
                }

                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.small
                    toggled: true

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete_sweep"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearHistory()
                    }

                    StyledToolTip {
                        text: "Clear output history"
                        extraVisibleCondition: false
                        alternativeVisibleCondition: parent.parent.hovered
                    }
                }
            }
        }

        // Output area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.normal - root.padding
                color: Appearance.colors.colLayer1

                StyledListView {
                    id: outputListView
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4
                    clip: true

                    model: ScriptModel {
                        values: root.outputHistory
                    }

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: outputListView.width - 16
                        implicitHeight: outputText.implicitHeight + 8

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: {
                                switch (modelData.type) {
                                    case "input": return Appearance.colors.colLayer2;
                                    case "error": return Qt.rgba(Appearance.colors.colRed.r, Appearance.colors.colRed.g, Appearance.colors.colRed.b, 0.1);
                                    case "system": return Qt.rgba(Appearance.colors.colBlue.r, Appearance.colors.colBlue.g, Appearance.colors.colBlue.b, 0.1);
                                    default: return "transparent";
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 6

                                StyledText {
                                    text: {
                                        switch (modelData.type) {
                                            case "input": return ">>>";
                                            case "error": return "!!!";
                                            case "system": return "---";
                                            default: return "   ";
                                        }
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.family: Appearance.font.family.mono
                                    color: {
                                        switch (modelData.type) {
                                            case "input": return Appearance.colors.colBlue;
                                            case "error": return Appearance.colors.colRed;
                                            case "system": return Appearance.colors.colYellow;
                                            default: return Appearance.colors.colGreen;
                                        }
                                    }
                                    Layout.alignment: Qt.AlignTop
                                }

                                StyledText {
                                    id: outputText
                                    text: modelData.text
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.family: Appearance.font.family.mono
                                    color: modelData.type === "error" ? Appearance.colors.colRed : Appearance.colors.colOnLayer1
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    PagePlaceholder {
                        shown: root.outputHistory.length === 0
                        icon: "terminal"
                        title: "IPython Interpreter"
                        description: "Type Python code below to execute\nCtrl+L to clear output\nUp/Down arrows for command history"
                        shape: MaterialShape.Shape.PixelCircle
                    }
                }
            }
        }

        // Input area
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(inputRowLayout.implicitHeight + 16, 50)
            radius: Appearance.rounding.normal - root.padding
            color: Appearance.colors.colLayer2

            RowLayout {
                id: inputRowLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                StyledText {
                    text: ">>>"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.family: Appearance.font.family.mono
                    color: Appearance.colors.colBlue
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 6
                }

                StyledTextArea {
                    id: commandInput
                    Layout.fillWidth: true
                    wrapMode: TextArea.Wrap
                    placeholderText: "Enter Python code..."
                    font.family: Appearance.font.family.mono
                    background: null

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                // Shift+Enter: insert newline
                                commandInput.insert(commandInput.cursorPosition, "\n");
                            } else {
                                // Enter: execute
                                root.executeInput();
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up && commandInput.cursorPosition === 0 && commandInput.text.length === 0) {
                            root.navigateHistory("up");
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down && commandInput.cursorPosition === commandInput.text.length && commandInput.text.length === 0) {
                            root.navigateHistory("down");
                            event.accepted = true;
                        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L) {
                            root.clearHistory();
                            event.accepted = true;
                        }
                    }
                }

                RippleButton {
                    id: executeButton
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    enabled: commandInput.text.trim().length > 0 && !root.isExecuting && root.pythonReady
                    toggled: enabled

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.isExecuting ? "hourglass_empty" : "play_arrow"
                        iconSize: Appearance.font.pixelSize.larger
                        color: executeButton.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer2Disabled
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: executeButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (executeButton.enabled) {
                                root.executeInput();
                            }
                        }
                    }
                }
            }
        }
    }
}
