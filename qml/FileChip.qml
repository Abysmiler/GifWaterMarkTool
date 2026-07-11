import QtQuick
import QtQuick.Controls.Basic
import GifWaterMarkTool

// 文件槽：角色徽记 + 说明 + 文件名。整块可点（打开对话框），设值后可清除。
Rectangle {
    id: chip
    property string glyph: ""
    property string role: ""          // 角色说明（如 "源 GIF"）
    property string value: ""         // 文件名，空=未选
    property string hint: "点击选择"
    property color accent: Theme.seal
    property bool clearable: true
    signal clicked()
    signal cleared()

    readonly property bool active: value !== ""

    implicitHeight: 40
    implicitWidth: Math.min(240, Math.max(150, row.implicitWidth + 22))
    radius: Theme.radiusSm
    color: ma.containsMouse ? Theme.panelHover : Theme.panelHi
    border.width: 1
    border.color: active ? Qt.rgba(chip.accent.r, chip.accent.g, chip.accent.b, 0.45) : Theme.line
    Behavior on color { ColorAnimation { duration: Theme.quick } }

    Row {
        id: row
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: clearBtn.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 9

        Rectangle {
            id: badge
            height: 20
            width: Math.max(20, badgeText.implicitWidth + 12)
            radius: Theme.radiusXs
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
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            width: Math.min(160, implicitWidth)
            Text {
                text: chip.role
                font.family: Theme.fontUI
                font.pixelSize: 10
                color: Theme.textFaint
            }
            Text {
                text: chip.active ? chip.value : chip.hint
                font.family: chip.active ? Theme.fontMono : Theme.fontUI
                font.pixelSize: 12
                color: chip.active ? Theme.text : Theme.textDim
                elide: Text.ElideMiddle
                width: parent.width
            }
        }
    }

    // 清除
    Rectangle {
        id: clearBtn
        visible: chip.active && chip.clearable
        width: visible ? 22 : 0
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
        anchors.rightMargin: (chip.active && chip.clearable) ? 30 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
