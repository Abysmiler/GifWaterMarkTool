import QtQuick
import GifWaterMarkTool

// 顶部滑入提示条。成功=朱砂封印语气「已盖章」。
Rectangle {
    id: root
    visible: false
    width: Math.min(360, parent.width - 32)
    height: 46
    radius: Theme.radiusSm
    y: visible ? 14 : -60
    z: 999

    property alias text: msgText.text
    property bool success: true
    property string outPath: ""
    signal openFolderRequested(string path)

    color: success ? Theme.okWash : Theme.warnWash
    border.width: 1
    border.color: success ? Theme.ok : Theme.warn
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.quick } }
    Behavior on y { NumberAnimation { duration: Theme.slide; easing.type: Easing.OutCubic } }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: actions.left
        anchors.rightMargin: 8
        spacing: 10

        Rectangle {
            width: 24; height: 24; radius: Theme.radiusXs
            anchors.verticalCenter: parent.verticalCenter
            color: root.success ? Theme.ok : Theme.warn
            Text {
                anchors.centerIn: parent
                text: root.success ? "印" : "!"
                font.family: Theme.fontUI
                font.pixelSize: root.success ? 13 : 15
                font.bold: true
                color: root.success ? Theme.okWash : Theme.warnWash
            }
        }
        Text {
            id: msgText
            anchors.verticalCenter: parent.verticalCenter
            color: root.success ? Theme.ok : Theme.warn
            font.family: Theme.fontUI
            font.pixelSize: 13
            font.bold: true
        }
    }

    Row {
        id: actions
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Rectangle {
            visible: root.success && root.outPath !== ""
            width: openLbl.width + 20; height: 28; radius: Theme.radiusXs
            anchors.verticalCenter: parent.verticalCenter
            color: openMa.containsMouse ? Qt.rgba(0,0,0,0.06) : "transparent"
            Text {
                id: openLbl
                anchors.centerIn: parent
                text: qsTr("打开文件夹")
                font.family: Theme.fontUI
                font.pixelSize: 12
                color: Theme.ok
            }
            MouseArea {
                id: openMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.openFolderRequested(root.outPath); root.visible = false }
            }
        }
        Rectangle {
            width: 28; height: 28; radius: Theme.radiusXs
            anchors.verticalCenter: parent.verticalCenter
            color: closeMa.containsMouse ? Qt.rgba(0,0,0,0.06) : "transparent"
            Text {
                anchors.centerIn: parent
                text: "×"; font.pixelSize: 16
                color: root.success ? Theme.ok : Theme.warn
            }
            MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.visible = false
            }
        }
    }

    Timer {
        id: hideTimer; interval: 3200
        onTriggered: root.visible = false
    }
    onVisibleChanged: if (visible) hideTimer.restart()

    function show(msg, ok, path) {
        root.text = msg; root.success = ok; root.outPath = path || ""
        root.visible = true
    }
}
