import QtQuick
import GifWaterMarkTool

// 分段选择器：底槽 + 朱砂滑块。model 为字符串数组。
Rectangle {
    id: seg
    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    implicitHeight: 32
    implicitWidth: 200
    radius: Theme.radiusSm
    color: Theme.panelHi
    border.width: 1
    border.color: Theme.line

    readonly property real cellW: (width - 4) / Math.max(1, model.length)

    // 滑块
    Rectangle {
        height: parent.height - 6
        width: seg.cellW - 2
        radius: Theme.radiusXs
        y: 3
        x: 3 + seg.currentIndex * seg.cellW
        color: Theme.seal
        Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 3
        Repeater {
            model: seg.model
            delegate: Item {
                width: seg.cellW; height: parent.height
                required property int index
                required property var modelData
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData
                    font.family: Theme.fontUI
                    font.pixelSize: 12
                    font.bold: seg.currentIndex === parent.index
                    color: seg.currentIndex === parent.index ? "#ffffff" : Theme.textDim
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.activated(parent.index)
                }
            }
        }
    }
}
