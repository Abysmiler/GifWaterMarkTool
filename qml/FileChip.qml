import QtQuick
import QtQuick.Controls.Basic
import GifWaterMarkTool

// 文件槽：角色徽记 + 说明 + 文件名。整块可点（打开对话框），设值后可清除。
// 文件名占满可用宽度（不再硬截到 160px）；在条带里最宽到 maxWidth，在检视器里随面板铺满。
Rectangle {
    id: chip
    property string glyph: ""
    property string role: ""          // 角色说明（如 "GIF 文件"）
    property string value: ""         // 文件名，空=未选
    property string hint: "点击选择"
    property color accent: Theme.seal
    property bool clearable: true
    property real maxWidth: 300        // 条带内最大宽度（检视器用 Layout.fillWidth 时不受此限）
    signal clicked()
    signal cleared()
    signal openFolderRequested()      // 右键菜单「打开文件夹」（打开文件所在目录，非选择对话框）

    readonly property bool active: value !== ""
    readonly property real _clearW: (active && clearable) ? 22 : 0
    readonly property real _textW: Math.max(roleText.implicitWidth, valueText.implicitWidth)

    implicitHeight: 40
    implicitWidth: Math.min(maxWidth,
                            Math.max(160, 8 + badge.width + 9 + _textW + 10 + _clearW + 8))
    radius: Theme.radiusSm
    color: ma.containsMouse ? Theme.panelHover : Theme.panelHi
    border.width: 1
    border.color: active ? Qt.rgba(chip.accent.r, chip.accent.g, chip.accent.b, 0.45) : Theme.line
    Behavior on color { ColorAnimation { duration: Theme.quick } }

    Rectangle {
        id: badge
        height: 20
        width: Math.max(20, badgeText.implicitWidth + 12)
        radius: Theme.radiusXs
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        color: chip.active ? Qt.rgba(chip.accent.r, chip.accent.g, chip.accent.b, 0.16)
                           : Theme.panelHi
        Text {
            id: badgeText
            anchors.centerIn: parent
            text: chip.glyph
            font.pixelSize: 10
            font.bold: true
            font.family: Theme.fontMono
            font.letterSpacing: 0.5
            color: chip.active ? chip.accent : Theme.textFaint
        }
    }

    Column {
        id: info
        anchors.left: badge.right
        anchors.leftMargin: 9
        anchors.right: clearBtn.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            id: roleText
            width: parent.width
            text: chip.role
            font.family: Theme.fontUI
            font.pixelSize: 10
            color: Theme.textFaint
            elide: Text.ElideRight
        }
        Text {
            id: valueText
            width: parent.width
            text: chip.active ? chip.value : chip.hint
            font.family: chip.active ? Theme.fontMono : Theme.fontUI
            font.pixelSize: 12
            color: chip.active ? Theme.text : Theme.textDim
            elide: Text.ElideMiddle
        }
    }

    // 清除
    Rectangle {
        id: clearBtn
        visible: chip.active && chip.clearable
        width: chip._clearW
        height: 22; radius: 11
        anchors.right: parent.right
        anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        color: clearMa.containsMouse ? Theme.line : "transparent"
        Text {
            anchors.centerIn: parent
            text: "×"
            font.pixelSize: 14
            color: Theme.textDim
        }
        MouseArea {
            id: clearMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.cleared()
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.rightMargin: chip._clearW > 0 ? 30 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (chip.active) chipMenu.popup()
                return
            }
            chip.clicked()
        }
    }

    // 右键菜单：打开文件所在文件夹（未选文件时不弹）
    Menu {
        id: chipMenu
        width: 140
        padding: 4
        background: Rectangle {
            radius: Theme.radiusSm
            color: Theme.panel
            border.width: 1
            border.color: Theme.line
        }
        MenuItem {
            id: openFolderItem
            height: 30
            text: qsTr("打开文件夹")
            contentItem: Text {
                text: openFolderItem.text
                font.family: Theme.fontUI
                font.pixelSize: 12
                color: openFolderItem.hovered ? Theme.text : Theme.textDim
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
            }
            background: Rectangle {
                radius: Theme.radiusXs
                color: openFolderItem.hovered ? Theme.panelHover : "transparent"
            }
            onTriggered: chip.openFolderRequested()
        }
    }
}
