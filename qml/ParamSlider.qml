import QtQuick
import QtQuick.Controls.Basic
import GifWaterMarkTool

// 参数滑条：标签 + 朱砂进度槽 + 等宽可编辑读数。
// 读数以 (value*factor) 显示，可双击输入精确值。
Item {
    id: root
    property string label: ""
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property real value: 0
    property real factor: 1          // 显示 = value*factor
    property int decimals: 0
    property string unit: ""
    signal moved(real v)

    implicitHeight: 46
    width: parent ? parent.width : 220

    function fmt(v) {
        return (v * factor).toFixed(decimals)
    }

    Text {
        id: lbl
        text: root.label
        font.family: Theme.fontUI
        font.pixelSize: 12
        color: Theme.textDim
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 2
    }

    // 读数（可编辑）
    Rectangle {
        id: readout
        width: 66; height: 22
        radius: Theme.radiusXs
        anchors.right: parent.right
        anchors.top: parent.top
        color: edit.activeFocus ? Theme.panel : "transparent"
        border.width: edit.activeFocus ? 1 : 0
        border.color: Theme.seal

        TextInput {
            id: edit
            anchors.fill: parent
            anchors.rightMargin: unitLbl.width + 6
            text: root.fmt(root.value)
            font.family: Theme.fontMono
            font.pixelSize: 13
            color: Theme.text
            horizontalAlignment: TextInput.AlignRight
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            selectionColor: Theme.seal
            activeFocusOnPress: true
            onActiveFocusChanged: if (activeFocus) selectAll()
            onAccepted: { commit(); focus = false }
            onEditingFinished: commit()
            function commit() {
                var n = parseFloat(text)
                if (!isNaN(n)) {
                    var v = Math.max(root.from, Math.min(root.to, n / root.factor))
                    root.moved(v)
                }
                text = Qt.binding(function() { return root.fmt(root.value) })
            }
            // 防止绑定在编辑时被打断
            Binding on text {
                when: !edit.activeFocus
                value: root.fmt(root.value)
            }
        }
        Text {
            id: unitLbl
            text: root.unit
            font.family: Theme.fontMono
            font.pixelSize: 12
            color: Theme.textFaint
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Slider {
        id: slider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        height: 18
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onMoved: root.moved(value)

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: Theme.panelHi
            border.width: 1
            border.color: Theme.line
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: Theme.seal
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 14; height: 14; radius: 7
            color: slider.pressed ? Theme.sealHi : "#EDF1F2"
            border.width: 2
            border.color: Theme.seal
            scale: slider.hovered || slider.pressed ? 1.12 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.quick } }
        }
    }
}
