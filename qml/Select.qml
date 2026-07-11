import QtQuick
import QtQuick.Controls.Basic
import GifWaterMarkTool

// 下拉选择。model 为 [{label, detail}]：label 中文名，detail 等宽技术值。
ComboBox {
    id: box
    property var items: []          // [{label, detail}]
    model: items
    textRole: "label"

    implicitHeight: 36
    font.family: Theme.fontUI
    font.pixelSize: 13

    contentItem: Row {
        leftPadding: 12
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        Text {
            text: box.items[box.currentIndex] ? box.items[box.currentIndex].label : ""
            font.family: Theme.fontUI
            font.pixelSize: 13
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: box.items[box.currentIndex] ? box.items[box.currentIndex].detail : ""
            font.family: Theme.fontMono
            font.pixelSize: 11
            color: Theme.textFaint
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    indicator: Text {
        text: "⌄"
        font.pixelSize: 14
        color: Theme.textDim
        x: box.width - width - 12
        y: (box.height - height) / 2 - 3
        rotation: box.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: Theme.quick } }
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: box.pressed || box.popup.visible ? Theme.panelHover : Theme.panelHi
        border.width: 1
        border.color: box.popup.visible ? Theme.seal : Theme.line
        Behavior on border.color { ColorAnimation { duration: Theme.quick } }
    }

    delegate: ItemDelegate {
        id: dg
        width: box.width
        height: 36
        required property int index
        required property var modelData
        contentItem: Row {
            leftPadding: 12
            spacing: 8
            Text {
                text: dg.modelData.label
                font.family: Theme.fontUI
                font.pixelSize: 13
                color: box.currentIndex === dg.index ? Theme.seal : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: dg.modelData.detail
                font.family: Theme.fontMono
                font.pixelSize: 11
                color: Theme.textFaint
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        background: Rectangle {
            color: dg.hovered ? Theme.panelHover : "transparent"
        }
    }

    popup: Popup {
        y: box.height + 4
        width: box.width
        padding: 4
        background: Rectangle {
            radius: Theme.radiusSm
            color: Theme.panel
            border.width: 1
            border.color: Theme.line
        }
        contentItem: ListView {
            implicitHeight: contentHeight
            model: box.popup.visible ? box.delegateModel : null
            clip: true
            spacing: 2
        }
    }
}
