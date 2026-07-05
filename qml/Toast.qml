import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion

Rectangle {
    id: root
    visible: false
    width: Math.min(280, parent.width - 32)
    height: 40; radius: 10
    anchors.horizontalCenter: parent.horizontalCenter
    y: 12
    z: 999

    property alias text: msgText.text
    property bool success: true
    property string outPath: ""
    signal openFolderRequested(string path)

    color: success ? "#ecfdf5" : "#fef2f2"
    border.color: success ? "#10b981" : "#ef4444"
    border.width: 1
    opacity: visible ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        id: msgRow
        anchors.centerIn: parent; spacing: 8
        Text {
            text: root.success ? "✓" : "✗"
            color: root.success ? "#10b981" : "#ef4444"
            font.pixelSize: 14
        }
        Text {
            id: msgText
            color: root.success ? "#065f46" : "#991b1b"
            font.pixelSize: 13
        }
        Button {
            visible: root.success && root.outPath !== ""
            text: qsTr("打开"); font.pixelSize: 11
            flat: true
            onClicked: { root.openFolderRequested(root.outPath); root.visible = false }
        }
        Button {
            text: "×"; font.pixelSize: 14; flat: true
            onClicked: root.visible = false
        }
    }

    Timer {
        id: hideTimer; interval: 3000
        onTriggered: root.visible = false
    }

    onVisibleChanged: { if (visible) hideTimer.restart() }

    function show(msg, ok, path) {
        root.text = msg; root.success = ok; root.outPath = path || ""
        root.visible = true
    }
}
