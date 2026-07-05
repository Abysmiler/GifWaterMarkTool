import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import QtQuick.Dialogs
import Qt.labs.settings
import GifWaterMarkTool

// 主界面：卡片式布局，跟随系统亮暗主题。
// 持有共享水印参数（wmScale/wmOpacity/wmRotate/qualityMode）作为唯一 source。
// 预览：GIF 变化时用 ffmpeg 抽第一帧 PNG（Qt AnimatedImage 读不了部分 GIF）。
ApplicationWindow {
    id: window
    width: 1000; height: 640
    minimumWidth: 840; minimumHeight: 520
    visible: true
    title: qsTr("GIF 水印工具 V1.0.0.2")


    // ---- 主题（跟随系统亮暗）----
    property bool lightMode: Application.styleHints.colorScheme === Qt.Light
    readonly property color bg: lightMode ? "#f3f3f5" : "#1c1c1e"
    readonly property color cardBg: lightMode ? "#ffffff" : "#2a2a2c"
    readonly property color text: lightMode ? "#1f1f1f" : "#e8e8ea"
    readonly property color subText: lightMode ? "#6b6b70" : "#9a9aa0"
    readonly property color accent: "#3b82f6"

    color: bg

    // ---- 共享水印参数（唯一 source）----
    property real wmScale: 1.0
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property int  qualityLevel: 0
    // ---- 压缩参数（默认 0 = 不压缩/保持原画质）----
    property int  compressPreset: 0   // 0=原图高质量, 1=平衡, 2=极限小体积
    property int  maxWidth: 0         // 0=不限；>0 按宽等比缩（只缩不放）
    property int  targetFps: 0        // 0=保持原帧率；>0 降帧率
    property int  ditherMode: 0       // 0=bayer, 1=none, 2=sierra2_4a
    property bool deepOptimize: false // 导出后跑 gifsicle 深度优化
    property bool useTextWater: false
    property string textContent: ""
    property int  textFontSize: 24
    property string textColor: "#ffffff"

    onWmScaleChanged: saveWmMemory()
    onWmOpacityChanged: saveWmMemory()
    onWmRotateChanged: saveWmMemory()

    // 水印拖拽时也保存位置
    Connections {
        target: preview
        function onGifCenterXChanged() { saveWmMemory() }
        function onGifCenterYChanged() { saveWmMemory() }
    }

    // ---- 文件路径（原始格式，供 ffmpeg 命令使用）----
    property string gifPath: ""
    property string waterPath: ""
    property string outPath: ""

    // 供 QML Image 使用的 file:/// URL 格式
    readonly property string gifUrl: gifPath !== "" ? "file:///" + gifPath : ""
    readonly property string waterUrl: waterPath !== "" ? "file:///" + waterPath : ""

    property string _previewPath: ""       // ffmpeg 抽帧 PNG（file:/// URL）
    property bool _restorePending: false    // GIF 加载完成后需恢复记忆位置
    property bool _suppressMemorySave: false // 加载期间禁止 saveWmMemory 写入

    // ---- 水印记忆（Qt.labs.settings 持久化）----
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


    // 保存当前水印参数（导出时 + 参数变化时调用）
    function saveWmMemory() {
        if (_suppressMemorySave) return   // 加载期间禁止写入，防止覆盖有效记忆
        if (preview.gifOrigW > 0 && preview.gifOrigH > 0) {
            wmSettings.posXRatio = preview.gifCenterX / preview.gifOrigW
            wmSettings.posYRatio = preview.gifCenterY / preview.gifOrigH
            wmSettings.scale = window.wmScale
            wmSettings.opacity = window.wmOpacity
            wmSettings.rotate = window.wmRotate
        }
    }

    // GIF 变化 → 同步抽第一帧；如果开启了记忆，标记需要恢复
    onGifPathChanged: {
        _previewPath = ""
        _suppressMemorySave = true
        _restorePending = wmSettings.memoryEnabled
        if (window.gifPath !== "") {
            _previewPath = runner.extractPreview(window.gifPath)
            // 换 GIF 后自动更新导出路径（沿用上次文件夹，新文件名 + 新时间戳）
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

    // CanvasPreview 布局完成后恢复记忆位置
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

    // ---- FFmpegRunner 实例：绑定所有参数 ----
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

    // ---- 布局 ----
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // 左：预览画布（Rectangle 直接作为 Layout 子项，避免 Pane contentItem 尺寸传递问题）
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            radius: 12
            color: window.cardBg
            border.color: window.lightMode ? "#e5e5e8" : "#3a3a3c"
            border.width: 1
            CanvasPreview {
                id: preview
                anchors.fill: parent
                anchors.margins: 12
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
                anchors.fill: parent; anchors.margins: 12
                onEntered: function(drag) { drag.accepted = drag.hasUrls }
                onDropped: function(drop) {
                    var path = urlToPath(drop.urls[0])
                    var lower = path.toLowerCase()
                    if (lower.endsWith(".gif")) window.gifPath = path
                    else if (lower.endsWith(".png")) window.waterPath = path
                }
            }
        }

        // 右：控制面板
        Rectangle {
            Layout.preferredWidth: 250
            Layout.fillHeight: true
            radius: 10
            color: window.cardBg
            border.color: window.lightMode ? "#e5e5e8" : "#3a3a3c"
            border.width: 1

            ScrollView {
                id: sideScroll
                anchors.fill: parent
                anchors.margins: 10
                clip: true

            ColumnLayout {
                width: sideScroll.availableWidth
                spacing: 4

                GroupBox {
                    title: qsTr("文件")
                    Layout.fillWidth: true
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        Button { Layout.fillWidth: true; text: qsTr("选择 GIF"); onClicked: gifDialog.open() }
                        Label { Layout.fillWidth: true; elide: Text.ElideRight
                            text: window.gifPath ? window.gifPath.replace(/^.*[\\/]/, "") : qsTr("未选择")
                            color: window.gifPath ? window.text : window.subText }
                        Button { Layout.fillWidth: true; text: qsTr("选择水印"); onClicked: waterDialog.open() }
                        Label { Layout.fillWidth: true; elide: Text.ElideRight
                            text: window.waterPath ? window.waterPath.replace(/^.*[\\/]/, "") : qsTr("未选择")
                            color: window.waterPath ? window.text : window.subText }
                    }
                }

                GroupBox {
                    title: qsTr("导出")
                    Layout.fillWidth: true
                    ColumnLayout {
                        anchors.fill: parent; spacing: 4
                        Button { Layout.fillWidth: true; text: qsTr("选择导出文件夹"); onClicked: outDialog.open() }

                        // 压缩预设：一键填充下方四个手动参数（选后仍可手动覆盖）
                        ComboBox {
                            id: compressCombo; Layout.fillWidth: true
                            model: [ qsTr("压缩: 原图高质量"), qsTr("压缩: 平衡 (推荐)"), qsTr("压缩: 极限小体积") ]
                            currentIndex: window.compressPreset
                            onActivated: function(index) {
                                window.compressPreset = index
                                window.targetFps = 0  // 所有预设均保持原帧率（用户偏好）
                                if (index === 0) {        // 原图高质量：不缩放、不深度优化
                                    window.maxWidth = 0; window.qualityLevel = 0; window.ditherMode = 0; window.deepOptimize = false
                                } else if (index === 1) {  // 平衡：缩到 360 宽 + 128 色 + bayer + gifsicle
                                    window.maxWidth = 360; window.qualityLevel = 1; window.ditherMode = 0; window.deepOptimize = true
                                } else {                   // 极限小体积：缩到 280 宽 + 64 色 + none + gifsicle
                                    window.maxWidth = 280; window.qualityLevel = 2; window.ditherMode = 1; window.deepOptimize = true
                                }
                            }
                        }

                        // ---- 手动精调（覆盖预设值）----
                        RowLayout {
                            Layout.fillWidth: true; spacing: 6
                            Label { text: qsTr("最大宽"); color: window.text; Layout.preferredWidth: 44 }
                            SpinBox {
                                Layout.fillWidth: true; from: 0; to: 1920; value: window.maxWidth
                                editable: true; onValueModified: window.maxWidth = value
                                up.indicator: Item { }
                                down.indicator: Item { }
                            }
                        }
                        Label { Layout.fillWidth: true; font.pixelSize: 10; color: window.subText
                            text: qsTr("0=不限；按宽等比缩，只缩不放") }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 6
                            Label { text: qsTr("帧率"); color: window.text; Layout.preferredWidth: 44 }
                            SpinBox {
                                Layout.fillWidth: true; from: 0; to: 60; value: window.targetFps
                                editable: true; onValueModified: window.targetFps = value
                                up.indicator: Item { }
                                down.indicator: Item { }
                            }
                        }
                        Label { Layout.fillWidth: true; font.pixelSize: 10; color: window.subText
                            text: qsTr("0=保持原帧率（推荐）") }

                        ComboBox {
                            id: qualityCombo; Layout.fillWidth: true
                            model: [ qsTr("原画 256色"), qsTr("中等 128色"), qsTr("压缩 64色"), qsTr("高压缩 32色") ]
                            currentIndex: window.qualityLevel
                            onActivated: function(index) { window.qualityLevel = index }
                        }

                        ComboBox {
                            Layout.fillWidth: true
                            model: [ qsTr("抖动: 平衡 bayer"), qsTr("抖动: 最小 none"), qsTr("抖动: 平滑 sierra") ]
                            currentIndex: window.ditherMode
                            onActivated: function(index) { window.ditherMode = index }
                        }

                        CheckBox {
                            Layout.fillWidth: true
                            text: qsTr("深度优化 (gifsicle，再瘦 30%)")
                            checked: window.deepOptimize; onToggled: window.deepOptimize = checked
                        }

                        Label { Layout.fillWidth: true; elide: Text.ElideRight
                            text: window.outPath ? window.outPath.replace(/^.*[\\/]/, "") : qsTr("未选择")
                            color: window.outPath ? window.text : window.subText }
                        ProgressBar { Layout.fillWidth: true; visible: runner.running; value: runner.progress / 100 }
                        Button { Layout.fillWidth: true; text: qsTr("开始导出"); highlighted: true
                            enabled: !runner.running && window.gifPath !== "" && (window.waterPath !== "" || window.useTextWater) && window.outPath !== ""
                            onClicked: runner.exportGif() }
                        Button { Layout.fillWidth: true; text: qsTr("取消")
                            visible: runner.running; onClicked: runner.cancelExport() }
                    }
                }

                GroupBox {
                    title: qsTr("水印参数")
                    Layout.fillWidth: true
                    ParameterPanel {
                        anchors.fill: parent
                        wmScale: window.wmScale; wmOpacity: window.wmOpacity; wmRotate: window.wmRotate
                        gifCenterX: preview.gifCenterX; gifCenterY: preview.gifCenterY
                        memoryEnabled: wmSettings.memoryEnabled
                        onWmScaleRequested: window.wmScale = v
                        onWmOpacityRequested: window.wmOpacity = v
                        onWmRotateRequested: window.wmRotate = v
                        onWmXRequested: preview.setGifPosition(x, preview.gifCenterY)
                        onWmYRequested: preview.setGifPosition(preview.gifCenterX, y)
                        onMemoryToggled: wmSettings.memoryEnabled = enabled
                    }
                }

                GroupBox {
                    title: qsTr("文字水印")
                    Layout.fillWidth: true
                    ColumnLayout {
                        anchors.fill: parent; spacing: 4
                        CheckBox {
                            id: textWmCheck
                            text: qsTr("启用文字水印")
                            checked: window.useTextWater; onToggled: window.useTextWater = checked
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 6
                            visible: window.useTextWater
                            TextField {
                                Layout.fillWidth: true; placeholderText: qsTr("水印文字")
                                text: window.textContent; onTextChanged: window.textContent = text
                            }
                            SpinBox {
                                id: fontSizeSpin; Layout.preferredWidth: 56
                                from: 8; to: 200; value: window.textFontSize
                                editable: true; onValueModified: window.textFontSize = value
                                up.indicator: Item { }
                                down.indicator: Item { }
                            }
                        }
                    }
                }
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

    // ---- Toast 通知 ----
    Toast {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        onOpenFolderRequested: function(p) { runner.openContainingFolder(p) }
    }
}
