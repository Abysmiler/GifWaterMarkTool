import QtQuick
import GifWaterMarkTool

// 数字输入：−/＋ 步进 + 等宽可编辑读数。可选前缀字母（如 X / Y）。
Rectangle {
    id: root
    property string prefix: ""
    property real from: 0
    property real to: 9999
    property real step: 1
    property real value: 0
    property string unit: ""
    signal edited(real v)

    implicitHeight: 32
    implicitWidth: 120
    radius: Theme.radiusSm
    color: Theme.panelHi
    border.width: 1
    border.color: input.activeFocus ? Theme.seal : Theme.line
    Behavior on border.color { ColorAnimation { duration: Theme.quick } }

    function clamp(v) { return Math.max(from, Math.min(to, v)) }
    function bump(d) { root.edited(clamp(root.value + d * root.step)) }

    // − 步进
    StepBtn { id: minus; sign: "−"; anchors.left: parent.left; onTapped: root.bump(-1) }

    Text {
        visible: root.prefix !== ""
        text: root.prefix
        font.family: Theme.fontUI
        font.pixelSize: 12
        color: Theme.textFaint
        anchors.left: minus.right
        anchors.verticalCenter: parent.verticalCenter
    }

    TextInput {
        id: input
        anchors.left: minus.right
        anchors.right: plus.left
        anchors.leftMargin: root.prefix !== "" ? 15 : 0
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        text: Math.round(root.value) + root.unit
        font.family: Theme.fontMono
        font.pixelSize: 13
        color: Theme.text
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        selectByMouse: true
        selectionColor: Theme.seal
        onActiveFocusChanged: if (activeFocus) selectAll()
        onAccepted: { commit(); focus = false }
        onEditingFinished: commit()
        function commit() {
            var n = parseFloat(text)
            if (!isNaN(n)) root.edited(root.clamp(n))
            text = Qt.binding(function() { return Math.round(root.value) + root.unit })
        }
        Binding on text {
            when: !input.activeFocus
            value: Math.round(root.value) + root.unit
        }
    }

    // ＋ 步进
    StepBtn { id: plus; sign: "＋"; anchors.right: parent.right; onTapped: root.bump(1) }

    component StepBtn : Rectangle {
        property string sign: ""
        signal tapped()
        width: 26; height: parent.height
        anchors.verticalCenter: parent.verticalCenter
        color: sm.containsMouse ? Theme.panelHover : "transparent"
        Text {
            anchors.centerIn: parent
            text: parent.sign
            font.pixelSize: 14
            color: Theme.textDim
        }
        MouseArea {
            id: sm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // 首次立即触发，长按后连发
            onPressed: { parent.tapped(); repeatTimer.start() }
            onReleased: repeatTimer.stop()
            onCanceled: repeatTimer.stop()
            Timer {
                id: repeatTimer
                interval: 90; repeat: true
                onTriggered: parent.parent.tapped()
            }
        }
    }
}
