import QtQuick
import GifWaterMarkTool

// 带说明的开关行：左侧标题+副说明，右侧朱砂拨钮。
Item {
    id: root
    property string text: ""
    property string caption: ""
    property bool checked: false
    signal toggled(bool v)

    implicitHeight: caption !== "" ? 42 : 30
    width: parent ? parent.width : 260

    Column {
        anchors.left: parent.left
        anchors.right: sw.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            text: root.text
            font.family: Theme.fontUI
            font.pixelSize: 13
            color: Theme.text
            width: parent.width
            elide: Text.ElideRight
        }
        Text {
            visible: root.caption !== ""
            text: root.caption
            font.family: Theme.fontUI
            font.pixelSize: 11
            color: Theme.textFaint
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        id: sw
        width: 40; height: 22; radius: 11
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? Theme.seal : Theme.line
        border.width: 1
        border.color: root.checked ? Theme.seal : Theme.line
        Behavior on color { ColorAnimation { duration: Theme.quick } }

        Rectangle {
            width: 16; height: 16; radius: 8
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: "#FFFFFF"
            border.width: 1
            border.color: root.checked ? Qt.rgba(0,0,0,0.06) : Theme.line
            Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
