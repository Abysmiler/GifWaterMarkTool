# GIF 水印工具 UI 重构 实现计划

> **For agentic workers:** 使用 superpowers:subagent-driven-development 或 superpowers:executing-plans 按任务逐个实现。步骤使用 `- [ ]` checkbox 跟踪。

**目标:** 将 GifWaterMarkTool 从窄侧栏滚动布局重构为现代化工作台式布局（顶部操作栏 + 预览主体 + 底部状态栏 + 右侧滑出抽屉）

**架构:** 纯 QML 层重构，C++ 后端不变。Main.qml 从 RowLayout 改为 ColumnLayout 结构；ParameterPanel.qml 从独立 GroupBox 内容改为抽屉面板内容；CanvasPreview.qml 和 Toast.qml 小幅调整。

**技术栈:** Qt 6.5 QML, QtQuick.Controls.Fusion, Qt.labs.settings

## 全局约束

- Qt 6.5+ Quick + Qml，无额外 UI 库依赖
- 保持 Fusion 风格 + 手动亮暗主题
- 所有现有 C++ 接口、Settings 持久化、信号连接不变
- 窗口默认 1200×780，最小 960×600
- 圆角卡片 12px，按钮 8px，模块间距 16px，控件间距 8-12px
- 强调色 `#3b82f6`

---

### 任务 1: 重写 Main.qml — 新布局结构

**文件:**
- 修改: `qml/Main.qml`（完整重写）

**产出:** 新的主窗口布局：顶部操作栏 + 预览区 + 底部状态栏 + 抽屉骨架

- [ ] **Step 1: 读取当前 Main.qml 确认所有属性和信号**

运行: 已在上下文中，确认关键元素：ApplicationWindow 属性（wmScale/wmOpacity/wmRotate/qualityLevel/compressPreset/maxWidth/targetFps/ditherMode/deepOptimize/useTextWater/textContent/textFontSize/textColor）、Settings（wmSettings/dlgSettings）、FFmpegRunner（runner）、FileDialog/FolderDialog（gifDialog/waterDialog/outDialog）、Toast（toast）、辅助函数（saveWmMemory/onPreviewReady/pad/urlToPath）

- [ ] **Step 2: 重写 Main.qml 为新的 ColumnLayout 结构**

写入 `qml/Main.qml`：

```qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import QtQuick.Dialogs
import Qt.labs.settings
import GifWaterMarkTool

ApplicationWindow {
    id: window
    width: 1200; height: 780
    minimumWidth: 960; minimumHeight: 600
    visible: true
    title: qsTr("GIF 水印工具")

    // ---- 主题 ----
    property bool lightMode: Application.styleHints.colorScheme === Qt.Light
    readonly property color bg: lightMode ? "#f5f5f7" : "#1c1c1e"
    readonly property color cardBg: lightMode ? "#ffffff" : "#2c2c2e"
    readonly property color text: lightMode ? "#1f1f1f" : "#e8e8ea"
    readonly property color subText: lightMode ? "#86868b" : "#98989d"
    readonly property color accent: "#3b82f6"
    readonly property color divider: lightMode ? "#e5e5ea" : "#3a3a3c"

    color: bg

    // ---- 共享水印参数 ----
    property real wmScale: 1.0
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property int  qualityLevel: 0
    property int  compressPreset: 0
    property int  maxWidth: 0
    property int  targetFps: 0
    property int  ditherMode: 0
    property bool deepOptimize: false
    property bool useTextWater: false
    property string textContent: ""
    property int  textFontSize: 24
    property string textColor: "#ffffff"
    property bool drawerOpen: false

    onWmScaleChanged: saveWmMemory()
    onWmOpacityChanged: saveWmMemory()
    onWmRotateChanged: saveWmMemory()

    Connections {
        target: preview
        function onGifCenterXChanged() { saveWmMemory() }
        function onGifCenterYChanged() { saveWmMemory() }
    }

    // ---- 文件路径 ----
    property string gifPath: ""
    property string waterPath: ""
    property string outPath: ""
    readonly property string gifUrl: gifPath !== "" ? "file:///" + gifPath : ""
    readonly property string waterUrl: waterPath !== "" ? "file:///" + waterPath : ""
    property string _previewPath: ""
    property bool _restorePending: false
    property bool _suppressMemorySave: false

    // ---- Settings ----
    Settings {
        id: wmSettings
        category: "watermark"
        property real posXRatio: 0.5
        property real posYRatio: 0.5
        property real scale: 1.0
        property real opacity: 1.0
        property real rotate: 0.0
        property bool memoryEnabled: false
    }
    Settings {
        id: dlgSettings
        category: "dialogs"
        property string gifFolder: ""
        property string waterFolder: ""
        property string outFolder: ""
    }

    function saveWmMemory() {
        if (_suppressMemorySave) return
        if (preview.gifOrigW > 0 && preview.gifOrigH > 0) {
            wmSettings.posXRatio = preview.gifCenterX / preview.gifOrigW
            wmSettings.posYRatio = preview.gifCenterY / preview.gifOrigH
            wmSettings.scale = window.wmScale
            wmSettings.opacity = window.wmOpacity
            wmSettings.rotate = window.wmRotate
        }
    }

    onGifPathChanged: {
        _previewPath = ""
        _suppressMemorySave = true
        _restorePending = wmSettings.memoryEnabled
        if (window.gifPath !== "") {
            _previewPath = runner.extractPreview(window.gifPath)
            var oldDir = window.outPath.replace(/[\\/][^\\/]+$/, "")
            if (oldDir !== "" && oldDir !== window.outPath) {
                var gifName = window.gifPath.replace(/^.*[\\/]/, "").replace(/\.gif$/i, "")
                var d = new Date()
                var ts = "" + d.getFullYear() + pad(d.getMonth()+1) + pad(d.getDate())
                          + pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds())
                window.outPath = oldDir + "/" + gifName + "_" + ts + ".gif"
            }
        }
    }

    function onPreviewReady() {
        _suppressMemorySave = false
        if (_restorePending && preview.gifOrigW > 0) {
            _restorePending = false
            window.wmScale = wmSettings.scale
            window.wmOpacity = wmSettings.opacity
            window.wmRotate = wmSettings.rotate
            preview.restorePosition(wmSettings.posXRatio, wmSettings.posYRatio)
            saveWmMemory()
        }
    }

    function pad(n) { return n < 10 ? "0" + n : "" + n }
    function urlToPath(u) {
        var s = u.toString()
        if (s.startsWith("file:///")) s = s.substring(8)
        try { return decodeURIComponent(s) } catch (e) { return s }
    }

    // ---- FFmpegRunner ----
    FFmpegRunner {
        id: runner
        gifPath: window.gifPath
        waterPath: window.waterPath
        outPath: window.outPath
        wmX: preview.gifCenterX
        wmY: preview.gifCenterY
        wmScale: window.wmScale
        wmOpacity: window.wmOpacity
        wmRotate: window.wmRotate
        qualityLevel: window.qualityLevel
        maxWidth: window.maxWidth
        targetFps: window.targetFps
        ditherMode: window.ditherMode
        deepOptimize: window.deepOptimize
        useTextWater: window.useTextWater
        textContent: window.textContent
        textFontSize: window.textFontSize
        textColor: window.textColor
        onFinished: function(ok, status, path, err) {
            if (ok) toast.show(qsTr("导出成功"), true, path)
            else if (status === FFmpegRunner.ExportCancelled) toast.show(qsTr("已取消导出"), false, "")
            else toast.show(qsTr("导出失败"), false, "")
        }
    }

    // ---- 主布局 ----
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // === 顶部操作栏 ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: window.lightMode ? "#f0f0f3" : "#252528"
            radius: 0

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 16
                spacing: 12

                // 选择 GIF 按钮
                Button {
                    id: selectGifBtn
                    text: window.gifPath !== ""
                          ? window.gifPath.replace(/^.*[\\/]/, "")
                          : qsTr("📁 选择 GIF")
                    font.pixelSize: 14
                    font.bold: true
                    Layout.preferredWidth: 180
                    highlighted: window.gifPath === ""
                    onClicked: gifDialog.open()
                }

                // 导出按钮
                Button {
                    id: exportBtn
                    text: runner.running ? qsTr("导出中...") : qsTr("🚀 导出")
                    font.pixelSize: 14
                    font.bold: true
                    highlighted: true
                    enabled: !runner.running && window.gifPath !== ""
                             && (window.waterPath !== "" || window.useTextWater)
                             && window.outPath !== ""
                    onClicked: runner.exportGif()
                }

                // 取消按钮（导出中显示）
                Button {
                    text: qsTr("取消")
                    visible: runner.running
                    onClicked: runner.cancelExport()
                }

                Item { Layout.fillWidth: true }

                // 水印设置按钮
                Button {
                    id: settingsBtn
                    text: qsTr("⚙️ 水印设置")
                    font.pixelSize: 13
                    flat: true
                    highlighted: window.drawerOpen
                    onClicked: window.drawerOpen = !window.drawerOpen
                }
            }
        }

        // 分隔线
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: window.divider
        }

        // === 预览区 ===
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 主预览画布
            CanvasPreview {
                id: preview
                anchors.fill: parent
                anchors.margins: 0
                gifSource: window.gifUrl
                previewSource: window._previewPath
                waterSource: window.waterUrl
                wmScale: window.wmScale
                wmOpacity: window.wmOpacity
                wmRotate: window.wmRotate
                useTextWater: window.useTextWater
                textContent: window.textContent
                textFontSize: window.textFontSize
                textColor: window.textColor
                onWmScaleAdjusted: window.wmScale = newScale
                onPreviewReady: window.onPreviewReady()
            }

            // 拖拽文件到预览区
            DropArea {
                anchors.fill: parent
                onEntered: function(drag) { drag.accepted = drag.hasUrls }
                onDropped: function(drop) {
                    var path = urlToPath(drop.urls[0])
                    var lower = path.toLowerCase()
                    if (lower.endsWith(".gif")) window.gifPath = path
                    else if (lower.endsWith(".png")) window.waterPath = path
                }
            }

            // 进度条（导出时覆盖在底部）
            ProgressBar {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                visible: runner.running
                value: runner.progress / 100
                z: 10
            }

            // 抽屉遮罩（点击关闭）
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: window.drawerOpen ? 0.3 : 0.0
                visible: opacity > 0
                z: 5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                MouseArea {
                    anchors.fill: parent
                    onClicked: window.drawerOpen = false
                }
            }
        }

        // === 底部状态栏 ===
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: window.lightMode ? "#f0f0f3" : "#252528"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 16
                spacing: 16

                // GIF 信息
                Label {
                    text: window.gifPath !== ""
                          ? "🎞 " + window.gifPath.replace(/^.*[\\/]/, "")
                          : qsTr("未选择 GIF")
                    color: window.gifPath !== "" ? window.text : window.subText
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 300
                }

                Rectangle {
                    Layout.preferredWidth: 1; Layout.preferredHeight: 16
                    color: window.divider; visible: window.gifPath !== ""
                }

                // 水印信息
                Label {
                    text: window.waterPath !== ""
                          ? "💧 " + window.waterPath.replace(/^.*[\\/]/, "")
                          : (window.useTextWater ? "📝 文字水印" : qsTr("未选择水印"))
                    color: (window.waterPath !== "" || window.useTextWater) ? window.text : window.subText
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 250
                }

                Item { Layout.fillWidth: true }

                // 导出路径
                Label {
                    text: window.outPath !== ""
                          ? "📂 " + window.outPath.replace(/^.*[\\/]/, "")
                          : qsTr("未设置导出路径")
                    color: window.outPath !== "" ? window.text : window.subText
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 350
                }
            }
        }
    }

    // === 水印设置抽屉（右侧滑出） ===
    Rectangle {
        id: drawer
        width: 300
        height: parent.height
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: window.drawerOpen ? parent.width - width : parent.width
        z: 10
        color: window.cardBg

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        // 左侧阴影
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#10000000" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0

            // 抽屉标题栏
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Label {
                    text: qsTr("水印设置")
                    font.pixelSize: 16; font.bold: true
                    color: window.text
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "✕"
                    flat: true
                    font.pixelSize: 16
                    onClicked: window.drawerOpen = false
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 1
                color: window.divider
            }

            // 可滚动内容
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ParameterPanel {
                    width: parent.width
                    wmScale: window.wmScale; wmOpacity: window.wmOpacity; wmRotate: window.wmRotate
                    gifCenterX: preview.gifCenterX; gifCenterY: preview.gifCenterY
                    memoryEnabled: wmSettings.memoryEnabled
                    useTextWater: window.useTextWater
                    textContent: window.textContent
                    textFontSize: window.textFontSize
                    textColor: window.textColor
                    waterPath: window.waterPath
                    compressPreset: window.compressPreset
                    maxWidth: window.maxWidth
                    targetFps: window.targetFps
                    qualityLevel: window.qualityLevel
                    ditherMode: window.ditherMode
                    deepOptimize: window.deepOptimize
                    outPath: window.outPath
                    onWmScaleRequested: window.wmScale = v
                    onWmOpacityRequested: window.wmOpacity = v
                    onWmRotateRequested: window.wmRotate = v
                    onWmXRequested: preview.setGifPosition(x, preview.gifCenterY)
                    onWmYRequested: preview.setGifPosition(preview.gifCenterX, y)
                    onMemoryToggled: wmSettings.memoryEnabled = enabled
                    onUseTextWaterToggled: window.useTextWater = v
                    onTextContentChanged: window.textContent = v
                    onTextFontSizeChanged: window.textFontSize = v
                    onTextColorChanged: window.textColor = v
                    onCompressPresetChanged: window.compressPreset = v
                    onMaxWidthChanged: window.maxWidth = v
                    onTargetFpsChanged: window.targetFps = v
                    onQualityLevelChanged: window.qualityLevel = v
                    onDitherModeChanged: window.ditherMode = v
                    onDeepOptimizeToggled: window.deepOptimize = v
                    onWaterPathRequested: waterDialog.open()
                    onOutPathRequested: outDialog.open()
                }
            }
        }
    }

    // ---- 文件对话框 ----
    FileDialog {
        id: gifDialog
        title: qsTr("选择 GIF")
        nameFilters: ["GIF (*.gif)"]
        currentFolder: dlgSettings.gifFolder !== "" ? "file:///" + dlgSettings.gifFolder : ""
        onAccepted: {
            window.gifPath = urlToPath(selectedFile)
            dlgSettings.gifFolder = urlToPath(currentFolder)
        }
    }
    FileDialog {
        id: waterDialog
        title: qsTr("选择水印 PNG")
        nameFilters: ["PNG (*.png)"]
        currentFolder: dlgSettings.waterFolder !== "" ? "file:///" + dlgSettings.waterFolder : ""
        onAccepted: {
            window.waterPath = urlToPath(selectedFile)
            dlgSettings.waterFolder = urlToPath(currentFolder)
        }
    }
    FolderDialog {
        id: outDialog
        title: qsTr("选择导出文件夹")
        currentFolder: dlgSettings.outFolder !== "" ? "file:///" + dlgSettings.outFolder : ""
        onAccepted: {
            var dir = urlToPath(selectedFolder)
            dlgSettings.outFolder = dir
            var gifName = window.gifPath.replace(/^.*[\\/]/, "").replace(/\.gif$/i, "")
            var d = new Date()
            var ts = "" + d.getFullYear() + pad(d.getMonth()+1) + pad(d.getDate())
                      + pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds())
            window.outPath = dir + "/" + gifName + "_" + ts + ".gif"
        }
    }

    // ---- Toast ----
    Toast {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        onOpenFolderRequested: function(p) { runner.openContainingFolder(p) }
    }
}
```

- [ ] **Step 3: 构建验证编译通过**

运行: `cmake --build build/Desktop_Qt_6_5_3_MinGW_64_bit_Debug --target GifWaterMarkTool`

预期: 编译错误（ParameterPanel.qml 尚未更新，缺少新增 signal 和 property）

---

### 任务 2: 重写 ParameterPanel.qml — 抽屉内容

**文件:**
- 修改: `qml/ParameterPanel.qml`（完整重写）

**接口:**
- 消费: Main.qml 传入的 watermark 参数、导出参数、callback signals
- 产出: 抽屉内完整参数面板，包含水印参数区、文字水印区、导出参数区

- [ ] **Step 1: 写入新的 ParameterPanel.qml**

写入 `qml/ParameterPanel.qml`：

```qml
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
        font.pixelSize: 12; font.bold: true
        color: root.subColor
        topPadding: 12; bottomPadding: 4
    }

    // === 辅助：分隔线 ===
    component Divider : Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 1
        color: root.divider
    }

    // === 水印图片 ===
    SectionLabel { Layout.fillWidth: true; text: qsTr("水印图片") }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
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
            font.pixelSize: 12; elide: Text.ElideRight
        }
    }

    Divider {}

    // === 缩放 ===
    SectionLabel { Layout.fillWidth: true; text: qsTr("缩放") }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Slider {
            id: scaleSlider
            Layout.fillWidth: true; from: 0.05; to: 5.0; stepSize: 0.05
            value: root.wmScale; onMoved: root.wmScaleRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 64; from: 5; to: 500
            value: Math.round(root.wmScale * 100); editable: true
            onValueModified: root.wmScaleRequested(value / 100)
            up.indicator: Item { }; down.indicator: Item { }
        }
        Label { text: "%"; color: root.subColor; font.pixelSize: 12 }
    }

    // === 透明度 ===
    SectionLabel { Layout.fillWidth: true; text: qsTr("透明度") }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Slider {
            id: opacitySlider
            Layout.fillWidth: true; from: 0.0; to: 1.0; stepSize: 0.05
            value: root.wmOpacity; onMoved: root.wmOpacityRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 64; from: 0; to: 100
            value: Math.round(root.wmOpacity * 100); editable: true
            onValueModified: root.wmOpacityRequested(value / 100)
            up.indicator: Item { }; down.indicator: Item { }
        }
        Label { text: "%"; color: root.subColor; font.pixelSize: 12 }
    }

    // === 旋转 ===
    SectionLabel { Layout.fillWidth: true; text: qsTr("旋转") }
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Slider {
            id: rotateSlider
            Layout.fillWidth: true; from: -180; to: 180; stepSize: 1
            value: root.wmRotate; onMoved: root.wmRotateRequested(value)
        }
        SpinBox {
            Layout.preferredWidth: 64; from: -180; to: 180
            value: Math.round(root.wmRotate); editable: true
            onValueModified: root.wmRotateRequested(value)
            up.indicator: Item { }; down.indicator: Item { }
        }
        Label { text: "°"; color: root.subColor; font.pixelSize: 12 }
    }

    Divider {}

    // === 位置 ===
    SectionLabel { Layout.fillWidth: true; text: qsTr("位置") }
    RowLayout {
        Layout.fillWidth: true; spacing: 6
        Label { text: "X"; color: root.txtColor; font.pixelSize: 12 }
        SpinBox {
            Layout.fillWidth: true; from: -9999; to: 9999
            value: Math.round(root.gifCenterX); editable: true
            onValueModified: root.wmXRequested(value)
            up.indicator: Item { }; down.indicator: Item { }
        }
        Label { text: "Y"; color: root.txtColor; font.pixelSize: 12 }
        SpinBox {
            Layout.fillWidth: true; from: -9999; to: 9999
            value: Math.round(root.gifCenterY); editable: true
            onValueModified: root.wmYRequested(value)
            up.indicator: Item { }; down.indicator: Item { }
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
    SectionLabel { Layout.fillWidth: true; text: qsTr("文字水印") }
    CheckBox {
        id: textWmCheck
        text: qsTr("启用文字水印")
        font.pixelSize: 12
        checked: root.useTextWater; onToggled: root.useTextWaterToggled(checked)
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
            Layout.fillWidth: true; spacing: 8
            Label { text: qsTr("字号"); color: root.txtColor; font.pixelSize: 12 }
            SpinBox {
                Layout.fillWidth: true; from: 8; to: 200
                value: root.textFontSize; editable: true
                onValueModified: root.textFontSizeChanged(value)
                up.indicator: Item { }; down.indicator: Item { }
            }
        }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Label { text: qsTr("颜色"); color: root.txtColor; font.pixelSize: 12 }
            Rectangle {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                radius: 4; color: root.textColor
                border.color: root.divider; border.width: 1
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
    SectionLabel { Layout.fillWidth: true; text: qsTr("导出参数") }

    ComboBox {
        id: compressCombo
        Layout.fillWidth: true
        model: [ qsTr("原图高质量"), qsTr("平衡 (推荐)"), qsTr("极限小体积") ]
        currentIndex: root.compressPreset
        onActivated: function(index) {
            root.compressPresetChanged(index)
            // 预设：自动填充详细参数
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
        Layout.fillWidth: true; spacing: 8
        Label { text: qsTr("最大宽"); color: root.txtColor; font.pixelSize: 12 }
        SpinBox {
            Layout.fillWidth: true; from: 0; to: 1920
            value: root.maxWidth; editable: true
            onValueModified: root.maxWidthChanged(value)
            up.indicator: Item { }; down.indicator: Item { }
        }
    }
    Label { Layout.fillWidth: true; font.pixelSize: 10; color: root.subColor
        text: qsTr("0=不限；按宽等比缩，只缩不放") }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Label { text: qsTr("帧率"); color: root.txtColor; font.pixelSize: 12 }
        SpinBox {
            Layout.fillWidth: true; from: 0; to: 60
            value: root.targetFps; editable: true
            onValueModified: root.targetFpsChanged(value)
            up.indicator: Item { }; down.indicator: Item { }
        }
    }
    Label { Layout.fillWidth: true; font.pixelSize: 10; color: root.subColor
        text: qsTr("0=保持原帧率") }

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
        checked: root.deepOptimize; onToggled: root.deepOptimizeToggled(checked)
    }

    // 导出路径
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Button {
            text: qsTr("导出路径")
            font.pixelSize: 12
            onClicked: root.outPathRequested()
        }
        Label {
            Layout.fillWidth: true
            text: root.outPath ? root.outPath.replace(/^.*[\\/]/, "") : qsTr("未设置")
            color: root.outPath ? root.txtColor : root.subColor
            font.pixelSize: 11; elide: Text.ElideRight
        }
    }

    Divider {}

    // === 记忆 ===
    CheckBox {
        id: memCheck
        text: qsTr("记住水印参数（换 GIF 时保留）")
        font.pixelSize: 12
        checked: root.memoryEnabled; onToggled: root.memoryToggled(checked)
    }
}
```

- [ ] **Step 2: 构建验证编译通过**

运行: `cmake --build build/Desktop_Qt_6_5_3_MinGW_64_bit_Debug --target GifWaterMarkTool`

预期: 编译成功

---

### 任务 3: 调整 CanvasPreview.qml — 适配新布局

**文件:**
- 修改: `qml/CanvasPreview.qml`

**变更:** 移除内部的 `"预览"` 标签文字（顶部栏已有选择按钮），调整预览框尺寸计算适配新的窗口比例（窗口 1200×780，预览区不再被 250px 侧栏压缩）

- [ ] **Step 1: 修改 CanvasPreview.qml**

修改预览框背景色和尺寸计算，移除顶部"预览"标签：

在 `qml/CanvasPreview.qml` 中做以下修改：

**修改 1: 移除顶部"预览"标签文字（第 111-115 行）**

```qml
// 删除以下代码：
// Text {
//     anchors.top: parent.top; anchors.left: parent.left
//     anchors.margins: 10; z: 10
//     text: qsTr("预览"); color: "#7a7a82"; font.pixelSize: 12
// }
```

**修改 2: 调整背景色和预览框比例**

将第 110 行的背景 Rectangle 颜色改为匹配新主题：

```qml
// 旧: Rectangle { anchors.fill: parent; radius: 8; color: "#1e1e24" }
// 新:
Rectangle { anchors.fill: parent; color: "#1a1a1e" }
```

**修改 3: 调整预览框尺寸比例（第 30 行）**

```qml
// 旧: readonly property real _boxW: Math.min(root.width * 0.65, root.height * 0.65 * 4 / 3)
// 新: readonly property real _boxW: Math.min(root.width * 0.75, root.height * 0.75 * 4 / 3)
```

- [ ] **Step 2: 构建验证**

运行: `cmake --build build/Desktop_Qt_6_5_3_MinGW_64_bit_Debug --target GifWaterMarkTool`

预期: 编译成功

---

### 任务 4: 微调 Toast.qml — 匹配新风格

**文件:**
- 修改: `qml/Toast.qml`

**变更:** 调整 Toast 圆角和颜色以匹配新的现代扁平风格

- [ ] **Step 1: 修改 Toast.qml 样式**

在 `qml/Toast.qml` 中修改：

```qml
// 修改第 10 行: radius 从 20 改为 10
// 旧: height: 40; radius: 20
// 新: height: 40; radius: 10

// 修改颜色以匹配新主题（第 17 行）
// 旧: color: success ? "#ecfdf5" : "#fef2f2"
// 旧: border.color: success ? "#10b981" : "#ef4444"
// 保持不变（这些颜色与主题无关，是语义色）
```

实际上 Toast 的当前样式已经不错，只需将 `radius: 20` 改为 `radius: 10` 以匹配新设计语言。其余保持不变。

- [ ] **Step 2: 构建验证**

运行: `cmake --build build/Desktop_Qt_6_5_3_MinGW_64_bit_Debug --target GifWaterMarkTool`

预期: 编译成功

---

### 任务 5: 全量构建 + 运行验证

**文件:**
- 验证所有已修改文件: `qml/Main.qml`, `qml/ParameterPanel.qml`, `qml/CanvasPreview.qml`, `qml/Toast.qml`

- [ ] **Step 1: 清理构建**

运行:
```powershell
cmake --build build/Desktop_Qt_6_5_3_MinGW_64_bit_Debug --target clean
```

- [ ] **Step 2: 全量构建**

运行:
```powershell
cmake --build build/Desktop_Qt_6_5_3_MinGW_64_bit_Debug --target GifWaterMarkTool
```

预期: 编译成功，无错误无警告

- [ ] **Step 3: 启动应用手动验证**

运行:
```powershell
.\build\Desktop_Qt_6_5_3_MinGW_64_bit_Debug\GifWaterMarkTool.exe
```

验证清单:
- [ ] 窗口 1200×780，最小 960×600
- [ ] 顶部栏显示选择 GIF 按钮 + 导出按钮 + 水印设置按钮
- [ ] 点击选择 GIF 能打开文件对话框，选择后预览区显示 GIF
- [ ] 预览区支持拖拽水印移动、滚轮缩放
- [ ] 点击水印设置按钮，抽屉从右侧滑出
- [ ] 抽屉内所有参数可调，预览即时反映
- [ ] 点击导出按钮能正常导出
- [ ] 导出成功 Toast 显示，可点击打开文件夹
- [ ] 底部状态栏显示 GIF 文件名、水印文件名、导出路径
- [ ] 亮色/暗色主题切换正常
- [ ] 水印参数记忆功能正常（换 GIF 后恢复位置）

- [ ] **Step 4: 修复发现的问题**

如有任何验证失败，修复对应 QML 文件并重新构建验证。
