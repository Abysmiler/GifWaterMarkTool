import QtQuick
import QtQuick.Layouts
import GifWaterMarkTool

// 检视器分组：眉标（中文标题 + 拉丁副题）+ 可折叠内容槽。
Item {
    id: sec
    property string title: ""
    property string subtitle: ""
    property bool collapsible: true
    property bool expanded: true
    default property alias content: inner.data

    implicitWidth: parent ? parent.width : 300
    implicitHeight: header.height + (expanded ? bodyWrap.implicitHeight : 0)
    clip: true
    Behavior on implicitHeight { NumberAnimation { duration: Theme.slide; easing.type: Easing.OutCubic } }

    // 眉标
    Item {
        id: header
        width: parent.width
        height: 34

        Rectangle {
            width: 3; height: 12; radius: 1.5
            color: Theme.seal
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
        }
        Text {
            id: titleText
            text: sec.title
            font.family: Theme.fontUI
            font.pixelSize: 13
            font.bold: true
            color: Theme.text
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: sec.subtitle
            font.family: Theme.fontMono
            font.pixelSize: 9
            color: Theme.textFaint
            anchors.left: titleText.right
            anchors.leftMargin: 8
            anchors.baseline: titleText.baseline
        }
        Text {
            visible: sec.collapsible
            text: "⌄"
            font.pixelSize: 14
            color: Theme.textDim
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            rotation: sec.expanded ? 0 : -90
            Behavior on rotation { NumberAnimation { duration: Theme.quick } }
        }
        MouseArea {
            anchors.fill: parent
            enabled: sec.collapsible
            cursorShape: Qt.PointingHandCursor
            onClicked: sec.expanded = !sec.expanded
        }
    }

    Item {
        id: bodyWrap
        width: parent.width
        anchors.top: header.bottom
        implicitHeight: inner.implicitHeight + 6
        opacity: sec.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.quick } }

        ColumnLayout {
            id: inner
            width: parent.width
            spacing: Theme.gap
        }
    }
}
