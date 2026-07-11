import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import GifWaterMarkTool

// 颜色选择：当前色块 + 等宽 HEX + 常用预设点 + 取色器。
ColumnLayout {
    id: root
    property string value: "#ffffff"
    signal picked(string hex)
    spacing: 8

    readonly property var presets: ["#ffffff", "#000000", "#E4572E", "#F2C14E", "#86C0AF"]

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 32; Layout.preferredHeight: 32
            radius: Theme.radiusSm
            color: root.value
            border.width: 1
            border.color: Theme.line
            // 透明棋盘垫底（若将来支持透明）
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: colorDlg.open()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: Theme.radiusSm
            color: Theme.panelHi
            border.width: 1
            border.color: hexInput.activeFocus ? Theme.seal : Theme.line
            TextInput {
                id: hexInput
                anchors.fill: parent
                anchors.leftMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: root.value
                font.family: Theme.fontMono
                font.pixelSize: 13
                color: Theme.text
                selectByMouse: true
                selectionColor: Theme.seal
                onEditingFinished: {
                    var v = text.trim()
                    if (/^#?[0-9a-fA-F]{6}$/.test(v)) {
                        if (v[0] !== "#") v = "#" + v
                        root.picked(v)
                    }
                    text = Qt.binding(function() { return root.value })
                }
            }
        }

        AppButton {
            text: qsTr("取色")
            kind: "ghost"
            implicitHeight: 32
            onClicked: colorDlg.open()
        }
    }

    Row {
        spacing: 8
        Repeater {
            model: root.presets
            delegate: Rectangle {
                required property var modelData
                width: 22; height: 22; radius: 11
                color: modelData
                border.width: root.value.toLowerCase() === modelData.toLowerCase() ? 2 : 1
                border.color: root.value.toLowerCase() === modelData.toLowerCase()
                              ? Theme.seal : Theme.line
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.modelData)
                }
            }
        }
    }

    ColorDialog {
        id: colorDlg
        selectedColor: root.value
        onAccepted: root.picked(selectedColor.toString())
    }
}
