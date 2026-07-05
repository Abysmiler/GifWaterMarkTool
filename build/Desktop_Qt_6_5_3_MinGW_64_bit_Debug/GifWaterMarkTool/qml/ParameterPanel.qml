import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 6

    readonly property bool lightMode: Application.styleHints.colorScheme === Qt.Light
    readonly property color txtColor: lightMode ? "#1f1f1f" : "#e8e8ea"
    readonly property color subColor: lightMode ? "#6b6b70" : "#9a9aa0"

    property real wmScale: 1.0
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property real gifCenterX: 0
    property real gifCenterY: 0
    property bool memoryEnabled: false

    signal wmScaleRequested(real v)
    signal wmOpacityRequested(real v)
    signal wmRotateRequested(real v)
    signal wmXRequested(real x)
    signal wmYRequested(real y)
    signal memoryToggled(bool enabled)

    RowLayout {
        Layout.fillWidth: true; spacing: 6
        Label { text: qsTr("缩放"); color: root.txtColor; Layout.preferredWidth: 32 }
        Slider {
            Layout.fillWidth: true; from: 0.05; to: 5.0; stepSize: 0.05
            value: root.wmScale; onMoved: root.wmScaleRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 56; from: 5; to: 500
            value: Math.round(root.wmScale * 100); editable: true
            onValueModified: root.wmScaleRequested(value / 100)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label { text: "%"; color: root.subColor }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 6
        Label { text: qsTr("透明"); color: root.txtColor; Layout.preferredWidth: 32 }
        Slider {
            Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.05
            value: root.wmOpacity; onMoved: root.wmOpacityRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 56; from: 0; to: 100
            value: Math.round(root.wmOpacity * 100); editable: true
            onValueModified: root.wmOpacityRequested(value / 100)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label { text: "%"; color: root.subColor }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 6
        Label { text: qsTr("旋转"); color: root.txtColor; Layout.preferredWidth: 32 }
        Slider {
            Layout.fillWidth: true; from: -180; to: 180; stepSize: 1
            value: root.wmRotate; onMoved: root.wmRotateRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 56; from: -180; to: 180
            value: Math.round(root.wmRotate); editable: true
            onValueModified: root.wmRotateRequested(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label { text: "°"; color: root.subColor }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 4
        Label { text: "X"; color: root.txtColor }
        SpinBox {
            Layout.fillWidth: true; from: -9999; to: 9999
            value: Math.round(root.gifCenterX); editable: true
            onValueModified: root.wmXRequested(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label { text: "Y"; color: root.txtColor }
        SpinBox {
            Layout.fillWidth: true; from: -9999; to: 9999
            value: Math.round(root.gifCenterY); editable: true
            onValueModified: root.wmYRequested(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Button {
            text: qsTr("重置")
            onClicked: { root.wmScaleRequested(1.0); root.wmOpacityRequested(1.0); root.wmRotateRequested(0.0) }
        }
    }

    CheckBox {
        id: memCheck
        text: qsTr("记住水印位置和大小")
        checked: root.memoryEnabled; onToggled: root.memoryToggled(checked)
    }
}
