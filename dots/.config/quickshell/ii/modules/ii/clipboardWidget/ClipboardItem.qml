import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RippleButton {
    id: root
    property string entry
    property string searchQuery: ""
    property bool isImage: Cliphist.entryIsImage(entry)
    property bool isCopied: itemName === Quickshell.clipboardText
    property string itemName: StringUtils.cleanCliphistEntry(entry)
    property string itemType: `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`

    property int itemVerticalPadding: 12
    property int itemHorizontalPadding: 12

    implicitHeight: contentLayout.implicitHeight + itemVerticalPadding * 2
    buttonRadius: Appearance.rounding.normal
    colBackground: (root.down || root.hovered || root.focus) ?
        Appearance.colors.colPrimaryContainer :
        ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 1)
    colBackgroundHover: Appearance.colors.colPrimaryContainer
    colRipple: Appearance.colors.colPrimaryContainerActive

    property string highlightPrefix: `<u><font color="${Appearance.colors.colPrimary}">`
    property string highlightSuffix: `</font></u>`

    function highlightContent(content, query) {
        if (!query || query.length === 0 || content === query)
            return StringUtils.escapeHtml(content);

        let contentLower = content.toLowerCase();
        let queryLower = query.toLowerCase();

        let result = "";
        let lastIndex = 0;
        let qIndex = 0;

        for (let i = 0; i < content.length && qIndex < query.length; i++) {
            if (contentLower[i] === queryLower[qIndex]) {
                if (i > lastIndex)
                    result += StringUtils.escapeHtml(content.slice(lastIndex, i));
                result += root.highlightPrefix + StringUtils.escapeHtml(content[i]) + root.highlightSuffix;
                lastIndex = i + 1;
                qIndex++;
            }
        }
        if (lastIndex < content.length)
            result += StringUtils.escapeHtml(content.slice(lastIndex));

        return result;
    }

    PointingHandInteraction {}

    onClicked: {
        Cliphist.copy(entry);
        GlobalStates.clipboardWidgetOpen = false;
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Delete && event.modifiers === Qt.ShiftModifier) {
            Cliphist.deleteEntry(entry);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.leftMargin: root.itemHorizontalPadding
        anchors.rightMargin: root.itemHorizontalPadding
        spacing: 10

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            RowLayout {
                spacing: 6

                // Copied indicator
                Loader {
                    visible: root.isCopied
                    active: root.isCopied
                    sourceComponent: Rectangle {
                        implicitWidth: checkIcon.implicitHeight
                        implicitHeight: checkIcon.implicitHeight
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colPrimary

                        MaterialSymbol {
                            id: checkIcon
                            anchors.centerIn: parent
                            text: "check"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }

                // Type indicator
                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    visible: root.itemType
                    text: root.itemType
                }
            }

            // Content
            StyledText {
                id: contentText
                Layout.fillWidth: true
                textFormat: Text.StyledText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.m3colors.m3onSurface
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                maximumLineCount: 3
                wrapMode: Text.Wrap
                text: highlightContent(root.itemName, root.searchQuery)
            }

            // Image preview
            Loader {
                active: root.isImage
                Layout.fillWidth: true

                sourceComponent: CliphistImage {
                    entry: root.entry
                    maxWidth: contentLayout.width - root.itemHorizontalPadding * 2
                    maxHeight: 120
                    blur: false
                }
            }
        }

        // Actions
        RowLayout {
            id: actionsColumn
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: root.itemVerticalPadding
            Layout.bottomMargin: -root.itemVerticalPadding
            spacing: 4

            // Copy button
            RippleButton {
                implicitHeight: 32
                implicitWidth: 32
                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                colRipple: Appearance.colors.colSecondaryContainerActive

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "content_copy"
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.m3colors.m3onSurface
                }

                onClicked: {
                    Cliphist.copy(root.entry);
                    GlobalStates.clipboardWidgetOpen = false;
                }

                StyledToolTip {
                    text: Translation.tr("Copy")
                }
            }

            // Delete button
            RippleButton {
                implicitHeight: 32
                implicitWidth: 32
                colBackgroundHover: Appearance.colors.colErrorContainerHover
                colRipple: Appearance.colors.colErrorContainerActive

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete"
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnErrorContainer
                }

                onClicked: {
                    Cliphist.deleteEntry(root.entry);
                }

                StyledToolTip {
                    text: Translation.tr("Delete (Shift+Del)")
                }
            }
        }
    }
}
