import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 6
    width: parent.width

    readonly property bool lightMode: Application.styleHints.colorScheme === Qt.Light
    readonly property color txtColor: lightMode ? "#1f1f1f" : "#e8e8ea"
    readonly property color subColor: lightMode ? "#86868b" : "#98989d"
    readonly property color accent: "#3b82f6"
    readonly property color divider: lightMode ? "#e5e5ea" : "#3a3a3c"
    readonly property color sectionBg: lightMode ? "#f9f9fb" : "#222225"

    // 水印参数
    property real wmScale: 1.0
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property real gifCenterX: 0
    property real gifCenterY: 0
    property bool memoryEnabled: false

    // 文字水印
    property bool useTextWater: false
    property string textContent: ""
    property int textFontSize: 24
    property string textColor: "#ffffff"

    // 导出参数
    property int compressPreset: 0
    property int maxWidth: 0
    property int targetFps: 0
    property int qualityLevel: 0
    property int ditherMode: 0
    property bool deepOptimize: false

    // 文件路径
    property string waterPath: ""
    property string outPath: ""

    // 水印参数 signals
    signal wmScaleRequested(real v)
    signal wmOpacityRequested(real v)
    signal wmRotateRequested(real v)
    signal wmXRequested(real x)
    signal wmYRequested(real y)
    signal memoryToggled(bool enabled)

    // 文字水印 signals
    signal useTextWaterToggled(bool v)
    signal textContentChanged(string v)
    signal textFontSizeChanged(int v)
    signal textColorChanged(string v)

    // 导出参数 signals
    signal compressPresetChanged(int v)
    signal maxWidthChanged(int v)
    signal targetFpsChanged(int v)
    signal qualityLevelChanged(int v)
    signal ditherModeChanged(int v)
    signal deepOptimizeToggled(bool v)

    // 文件选择 signals
    signal waterPathRequested()
    signal outPathRequested()

    // === 辅助：分组标题 ===
    component SectionLabel : Label {
        font.pixelSize: 12
        font.bold: true
        color: root.subColor
        topPadding: 12
        bottomPadding: 4
    }

    // === 辅助：分隔线 ===
    component Divider : Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: root.divider
    }

    // === 水印图片 ===
    SectionLabel {
        Layout.fillWidth: true
        text: qsTr("水印图片")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Button {
            text: qsTr("选择 PNG")
            font.pixelSize: 12
            Layout.preferredWidth: 80
            onClicked: root.waterPathRequested()
        }
        Label {
            Layout.fillWidth: true
            text: root.waterPath ? root.waterPath.replace(/^.*[\\/]/, "") : qsTr("未选择")
            color: root.waterPath ? root.txtColor : root.subColor
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    Divider {}

    // === 缩放 ===
    SectionLabel {
        Layout.fillWidth: true
        text: qsTr("缩放")
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Slider {
            id: scaleSlider
            Layout.fillWidth: true
            from: 0.05
            to: 5.0
            stepSize: 0.05
            value: root.wmScale
            onMoved: root.wmScaleRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 64
            from: 5
            to: 500
            value: Math.round(root.wmScale * 100)
            editable: true
            onValueModified: root.wmScaleRequested(value / 100)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label {
            text: "%"
            color: root.subColor
            font.pixelSize: 12
        }
    }

    // === 透明度 ===
    SectionLabel {
        Layout.fillWidth: true
        text: qsTr("透明度")
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Slider {
            id: opacitySlider
            Layout.fillWidth: true
            from: 0.0
            to: 1.0
            stepSize: 0.05
            value: root.wmOpacity
            onMoved: root.wmOpacityRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 64
            from: 0
            to: 100
            value: Math.round(root.wmOpacity * 100)
            editable: true
            onValueModified: root.wmOpacityRequested(value / 100)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label {
            text: "%"
            color: root.subColor
            font.pixelSize: 12
        }
    }

    // === 旋转 ===
    SectionLabel {
        Layout.fillWidth: true
        text: qsTr("旋转")
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Slider {
            id: rotateSlider
            Layout.fillWidth: true
            from: -180
            to: 180
            stepSize: 1
            value: root.wmRotate
            onMoved: root.wmRotateRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 64
            from: -180
            to: 180
            value: Math.round(root.wmRotate)
            editable: true
            onValueModified: root.wmRotateRequested(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label {
            text: "°"
            color: root.subColor
            font.pixelSize: 12
        }
    }

    Divider {}

    // === 位置 ===
    SectionLabel {
        Layout.fillWidth: true
        text: qsTr("位置")
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Label {
            text: "X"
            color: root.txtColor
            font.pixelSize: 12
        }
        SpinBox {
            Layout.fillWidth: true
            from: -9999
            to: 9999
            value: Math.round(root.gifCenterX)
            editable: true
            onValueModified: root.wmXRequested(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Label {
            text: "Y"
            color: root.txtColor
            font.pixelSize: 12
        }
        SpinBox {
            Layout.fillWidth: true
            from: -9999
            to: 9999
            value: Math.round(root.gifCenterY)
            editable: true
            onValueModified: root.wmYRequested(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
        Button {
            text: qsTr("重置")
            font.pixelSize: 12
            onClicked: {
                root.wmScaleRequested(1.0)
                root.wmOpacityRequested(1.0)
                root.wmRotateRequested(0.0)
            }
        }
    }

    Divider {}

    // === 文字水印 ===
    SectionLabel {
        Layout.fillWidth: true
        text: qsTr("文字水印")
    }
    CheckBox {
        id: textWmCheck
        text: qsTr("启用文字水印")
        font.pixelSize: 12
        checked: root.useTextWater
        onToggled: root.useTextWaterToggled(checked)
    }
    ColumnLayout {
        visible: root.useTextWater
        spacing: 6

        TextField {
            Layout.fillWidth: true
            placeholderText: qsTr("水印文字")
            text: root.textContent
            onTextChanged: root.textContentChanged(text)
            font.pixelSize: 13
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                text: qsTr("字号")
                color: root.txtColor
                font.pixelSize: 12
            }
            SpinBox {
                Layout.fillWidth: true
                from: 8
                to: 200
                value: root.textFontSize
                editable: true
                onValueModified: root.textFontSizeChanged(value)
                up.indicator: Item { }
                down.indicator: Item { }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                text: qsTr("颜色")
                color: root.txtColor
                font.pixelSize: 12
            }
            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 4
                color: root.textColor
                border.color: root.divider
                border.width: 1
            }
            TextField {
                Layout.fillWidth: true
                text: root.textColor
                onTextChanged: root.textColorChanged(text)
                font.pixelSize: 13
                Layout.maximumWidth: 100
            }
        }
    }

    Divider {}

    // === 导出参数 ===
    SectionLabel {
        Layout.fillWidth: true
        text: qsTr("导出参数")
    }

    ComboBox {
        id: compressCombo
        Layout.fillWidth: true
        model: [ qsTr("原图高质量"), qsTr("平衡 (推荐)"), qsTr("极限小体积") ]
        currentIndex: root.compressPreset
        onActivated: function(index) {
            root.compressPresetChanged(index)
            root.targetFpsChanged(0)
            if (index === 0) {
                root.maxWidthChanged(0); root.qualityLevelChanged(0)
                root.ditherModeChanged(0); root.deepOptimizeToggled(false)
            } else if (index === 1) {
                root.maxWidthChanged(360); root.qualityLevelChanged(1)
                root.ditherModeChanged(0); root.deepOptimizeToggled(true)
            } else {
                root.maxWidthChanged(280); root.qualityLevelChanged(2)
                root.ditherModeChanged(1); root.deepOptimizeToggled(true)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Label {
            text: qsTr("最大宽")
            color: root.txtColor
            font.pixelSize: 12
        }
        SpinBox {
            Layout.fillWidth: true
            from: 0
            to: 1920
            value: root.maxWidth
            editable: true
            onValueModified: root.maxWidthChanged(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
    }
    Label {
        Layout.fillWidth: true
        font.pixelSize: 10
        color: root.subColor
        text: qsTr("0=不限；按宽等比缩，只缩不放")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Label {
            text: qsTr("帧率")
            color: root.txtColor
            font.pixelSize: 12
        }
        SpinBox {
            Layout.fillWidth: true
            from: 0
            to: 60
            value: root.targetFps
            editable: true
            onValueModified: root.targetFpsChanged(value)
            up.indicator: Item { }
            down.indicator: Item { }
        }
    }
    Label {
        Layout.fillWidth: true
        font.pixelSize: 10
        color: root.subColor
        text: qsTr("0=保持原帧率")
    }

    ComboBox {
        Layout.fillWidth: true
        model: [ qsTr("原画 256色"), qsTr("中等 128色"), qsTr("压缩 64色"), qsTr("高压缩 32色") ]
        currentIndex: root.qualityLevel
        onActivated: function(index) { root.qualityLevelChanged(index) }
    }

    ComboBox {
        Layout.fillWidth: true
        model: [ qsTr("抖动: bayer"), qsTr("抖动: none"), qsTr("抖动: sierra") ]
        currentIndex: root.ditherMode
        onActivated: function(index) { root.ditherModeChanged(index) }
    }

    CheckBox {
        text: qsTr("深度优化 (gifsicle)")
        font.pixelSize: 12
        checked: root.deepOptimize
        onToggled: root.deepOptimizeToggled(checked)
    }

    // 导出路径
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Button {
            text: qsTr("导出路径")
            font.pixelSize: 12
            onClicked: root.outPathRequested()
        }
        Label {
            Layout.fillWidth: true
            text: root.outPath ? root.outPath.replace(/^.*[\\/]/, "") : qsTr("未设置")
            color: root.outPath ? root.txtColor : root.subColor
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    Divider {}

    // === 记忆 ===
    CheckBox {
        id: memCheck
        text: qsTr("记住水印参数（换 GIF 时保留）")
        font.pixelSize: 12
        checked: root.memoryEnabled
        onToggled: root.memoryToggled(checked)
    }
}
