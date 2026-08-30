import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import GifWaterMarkTool

// 检视器：常驻右栏（不再是遮挡预览的抽屉）。所有调整即时反映到台面。
Flickable {
    id: root
    contentWidth: width
    contentHeight: col.implicitHeight + 2 * Theme.pad
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    // ---- 状态入参（Main 绑定）----
    property bool useTextWater: false
    property string waterPath: ""
    property string textContent: ""
    property int textFontSize: 24
    property string textColor: "#ffffff"
    property real wmScale: 1.0
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property real gifCenterX: 0
    property real gifCenterY: 0
    property int maxWidth: 0
    property int targetFps: 0
    property int qualityLevel: 0
    property int ditherMode: 0
    property bool deepOptimize: false
    property bool memoryEnabled: false
    property bool hasGif: false
    property string canvasBg: "#5E6A74"
    property bool canvasChecker: false

    // ---- 出参信号 ----
    signal useTextWaterRequested(bool v)
    signal waterPathRequested()
    signal openWaterFolderRequested()
    signal textContentEdited(string v)
    signal textFontSizeEdited(int v)
    signal textColorEdited(string v)
    signal wmScaleRequested(real v)
    signal wmOpacityRequested(real v)
    signal wmRotateRequested(real v)
    signal wmXRequested(real v)
    signal wmYRequested(real v)
    signal centerRequested()
    signal defaultRequested()
    signal maxWidthEdited(int v)
    signal targetFpsEdited(int v)
    signal qualityLevelEdited(int v)
    signal ditherModeEdited(int v)
    signal deepOptimizeToggled(bool v)
    signal memoryToggled(bool v)
    signal canvasCheckerRequested()
    signal canvasColorRequested(string hex)

    readonly property var canvasPresets: ["#D9DEE4", "#8A95A0", "#3B444D"]
    function _isPreset(c) { return canvasPresets.indexOf((c || "").toLowerCase()) >= 0 }
    function _sameHex(a, b) { return (a || "").toLowerCase() === (b || "").toLowerCase() }

    component HRule : Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        Layout.preferredHeight: 1
        color: Theme.lineSoft
    }
    component FieldLabel : Text {
        font.family: Theme.fontUI
        font.pixelSize: 12
        color: Theme.textDim
    }
    // 台面底色色块
    component CanvasSwatch : Rectangle {
        property color swatchColor: "#000000"
        property bool checker: false
        property bool custom: false
        property bool selected: false
        signal picked()
        width: 28; height: 28; radius: Theme.radiusXs
        color: checker ? Theme.stageA : swatchColor
        border.width: selected ? 2 : 1
        border.color: selected ? Theme.seal : Theme.line
        clip: true
        // 棋盘迷你图
        Rectangle { visible: parent.checker; x: 0; y: 0; width: 14; height: 14; color: Theme.stageB }
        Rectangle { visible: parent.checker; x: 14; y: 14; width: 14; height: 14; color: Theme.stageB }
        // 自定义标记
        Text {
            visible: parent.custom
            anchors.centerIn: parent
            text: "＋"
            font.pixelSize: 13
            color: (parent.swatchColor.r + parent.swatchColor.g + parent.swatchColor.b) > 1.6
                   ? Theme.text : "#FFFFFF"
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.picked()
        }
    }

    ColumnLayout {
        id: col
        x: Theme.pad
        y: Theme.pad
        width: root.width - 2 * Theme.pad
        spacing: Theme.gap

        // ===== 水印 =====
        Section {
            Layout.fillWidth: true
            title: qsTr("水印")
            subtitle: "WATERMARK"

            Segmented {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                model: [qsTr("图片"), qsTr("文字")]
                currentIndex: root.useTextWater ? 1 : 0
                onActivated: function(i) { root.useTextWaterRequested(i === 1) }
            }

            // —— 图片模式 ——
            FileChip {
                Layout.fillWidth: true
                visible: !root.useTextWater
                glyph: "PNG"
                role: qsTr("水印图片")
                accent: Theme.seal
                value: root.waterPath ? root.waterPath.replace(/^.*[\\/]/, "") : ""
                hint: qsTr("选择透明 PNG")
                clearable: false
                onClicked: root.waterPathRequested()
                onOpenFolderRequested: root.openWaterFolderRequested()
            }

            // —— 文字模式 ——
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.useTextWater
                spacing: Theme.gap

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: Theme.radiusSm
                    color: Theme.panelHi
                    border.width: 1
                    border.color: contentInput.activeFocus ? Theme.seal : Theme.line
                    TextInput {
                        id: contentInput
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.textContent
                        font.family: Theme.fontUI
                        font.pixelSize: 14
                        color: Theme.text
                        clip: true
                        selectByMouse: true
                        selectionColor: Theme.seal
                        onTextEdited: root.textContentEdited(text)
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: contentInput.text === "" && !contentInput.activeFocus
                            text: qsTr("输入水印文字")
                            font.family: Theme.fontUI
                            font.pixelSize: 14
                            color: Theme.textFaint
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    FieldLabel { text: qsTr("字号") }
                    NumberField {
                        Layout.fillWidth: true
                        from: 8; to: 200; step: 1; unit: "px"
                        value: root.textFontSize
                        onEdited: function(v) { root.textFontSizeEdited(v) }
                    }
                }

                ColorField {
                    Layout.fillWidth: true
                    value: root.textColor
                    onPicked: function(hex) { root.textColorEdited(hex) }
                }
            }

            // —— 变换（两模式共用透明度；缩放/旋转仅图片）——
            ParamSlider {
                Layout.fillWidth: true
                label: qsTr("不透明度")
                from: 0; to: 1; stepSize: 0.01; factor: 100; unit: "%"
                value: root.wmOpacity
                onMoved: function(v) { root.wmOpacityRequested(v) }
            }
            ParamSlider {
                Layout.fillWidth: true
                visible: !root.useTextWater
                label: qsTr("缩放")
                from: 0.05; to: 5; stepSize: 0.01; factor: 100; unit: "%"
                value: root.wmScale
                onMoved: function(v) { root.wmScaleRequested(v) }
            }
            ParamSlider {
                Layout.fillWidth: true
                visible: !root.useTextWater
                label: qsTr("旋转")
                from: -180; to: 180; stepSize: 1; factor: 1; unit: "°"
                value: root.wmRotate
                onMoved: function(v) { root.wmRotateRequested(v) }
            }
        }

        HRule {}

        // ===== 位置 =====
        Section {
            Layout.fillWidth: true
            title: qsTr("位置")
            subtitle: "POSITION · px"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                NumberField {
                    Layout.fillWidth: true
                    prefix: "X"; from: -9999; to: 9999; step: 1
                    value: root.gifCenterX
                    enabled: root.hasGif
                    onEdited: function(v) { root.wmXRequested(v) }
                }
                NumberField {
                    Layout.fillWidth: true
                    prefix: "Y"; from: -9999; to: 9999; step: 1
                    value: root.gifCenterY
                    enabled: root.hasGif
                    onEdited: function(v) { root.wmYRequested(v) }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                AppButton {
                    Layout.fillWidth: true
                    text: qsTr("默认位置")
                    kind: "ghost"
                    enabled: root.hasGif
                    onClicked: root.defaultRequested()
                }
                AppButton {
                    Layout.fillWidth: true
                    text: qsTr("移到正中")
                    kind: "ghost"
                    enabled: root.hasGif
                    onClicked: root.centerRequested()
                }
            }
        }

        HRule {}

        // ===== 台面 =====
        Section {
            Layout.fillWidth: true
            title: qsTr("预览底色")
            subtitle: "CANVAS"

            Text {
                Layout.fillWidth: true
                text: qsTr("换个底色，白色或深色水印都更容易看清位置")
                font.family: Theme.fontUI
                font.pixelSize: 11
                color: Theme.textFaint
                wrapMode: Text.WordWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                CanvasSwatch {
                    checker: true
                    selected: root.canvasChecker
                    onPicked: root.canvasCheckerRequested()
                }
                Repeater {
                    model: root.canvasPresets
                    delegate: CanvasSwatch {
                        required property var modelData
                        swatchColor: modelData
                        selected: !root.canvasChecker && root._sameHex(root.canvasBg, modelData)
                        onPicked: root.canvasColorRequested(modelData)
                    }
                }
                CanvasSwatch {
                    swatchColor: root.canvasBg
                    custom: true
                    selected: !root.canvasChecker && !root._isPreset(root.canvasBg)
                    onPicked: canvasColorDlg.open()
                }
                Item { Layout.fillWidth: true }
            }
            ColorDialog {
                id: canvasColorDlg
                selectedColor: root.canvasBg
                onAccepted: root.canvasColorRequested(selectedColor.toString())
            }
        }

        HRule {}

        // ===== 导出 =====
        Section {
            Layout.fillWidth: true
            title: qsTr("导出")
            subtitle: "EXPORT"

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    FieldLabel { text: qsTr("最大宽度") }
                    Text {
                        text: qsTr("0 = 保持原宽（只缩小、不放大）")
                        font.family: Theme.fontUI
                        font.pixelSize: 10
                        color: Theme.textFaint
                    }
                }
                NumberField {
                    Layout.preferredWidth: 128
                    from: 0; to: 3840; step: 20; unit: "px"
                    value: root.maxWidth
                    onEdited: function(v) { root.maxWidthEdited(v) }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    FieldLabel { text: qsTr("帧率") }
                    Text {
                        text: qsTr("0 = 保持原速")
                        font.family: Theme.fontUI
                        font.pixelSize: 10
                        color: Theme.textFaint
                    }
                }
                NumberField {
                    Layout.preferredWidth: 128
                    from: 0; to: 60; step: 1; unit: "fps"
                    value: root.targetFps
                    onEdited: function(v) { root.targetFpsEdited(v) }
                }
            }

            FieldLabel { text: qsTr("画质 · 颜色数") }
            Select {
                Layout.fillWidth: true
                items: [
                    { label: qsTr("原画质"), detail: "256 色" },
                    { label: qsTr("均衡"),   detail: "128 色" },
                    { label: qsTr("更小"),   detail: "64 色" },
                    { label: qsTr("最小"),   detail: "32 色" }
                ]
                currentIndex: root.qualityLevel
                onActivated: function(i) { root.qualityLevelEdited(i) }
            }

            FieldLabel { text: qsTr("抖动方式") }
            Select {
                Layout.fillWidth: true
                items: [
                    { label: qsTr("拜耳"),   detail: "bayer · 体积最小" },
                    { label: qsTr("不抖动"), detail: "none · 最锐利" },
                    { label: qsTr("Sierra"), detail: "sierra · 最平滑" }
                ]
                currentIndex: root.ditherMode
                onActivated: function(i) { root.ditherModeEdited(i) }
            }

            SwitchRow {
                Layout.fillWidth: true
                text: qsTr("深度压缩")
                caption: qsTr("导出后再用 gifsicle 压一遍，体积约小 30–40%")
                checked: root.deepOptimize
                onToggled: function(v) { root.deepOptimizeToggled(v) }
            }
        }
    }
}
