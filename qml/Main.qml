import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtCore
import GifWaterMarkTool

ApplicationWindow {
    id: window
    width: 1240; height: 800
    minimumWidth: 1040; minimumHeight: 640
    visible: true
    title: "GifWaterMarkTool"
    color: Theme.ink

    // ---- 布局尺度 ----
    readonly property int m: 16
    readonly property int stripH: 60
    readonly property int inspW: 344
    readonly property int statusH: 36

    // ---- 共享水印参数 ----
    property real wmScale: 0.1
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property int  qualityLevel: 1
    property int  maxWidth: 0
    property int  targetFps: 0
    property int  ditherMode: 0
    property bool deepOptimize: true
    property bool useTextWater: false
    property string textContent: ""
    property int  textFontSize: 24
    property string textColor: "#ffffff"

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

    // 默认水印位置：由旧版 500×500 GIF 的绝对坐标 (370,485) 换算成比例 → 右下
    readonly property real defPosXRatio: 370.0 / 500.0   // 0.74
    readonly property real defPosYRatio: 485.0 / 500.0   // 0.97

    // ---- Settings ----
    Settings {
        id: wmSettings
        category: "watermark"
        property real posXRatio: 0.74
        property real posYRatio: 0.97
        property real scale: 1.0
        property real opacity: 1.0
        property real rotate: 0.0
        property bool memoryEnabled: true
        // 记住上次水印时一并持久化的水印本体
        property string waterPath: ""
        property bool useTextWater: false
        property string textContent: ""
        property int textFontSize: 24
        property string textColor: "#ffffff"
        property real lastX: 0          // 上次水印绝对位置（仅用于无 GIF 时位置框显示）
        property real lastY: 0
    }
    Settings {
        id: dlgSettings
        category: "dialogs"
        property string gifFolder: ""
        property string waterFolder: ""
        property string outFolder: ""
    }
    Settings {
        id: prefs
        category: "preferences"
        property bool deepCompress: true      // 默认启用深度压缩
        property bool rememberOutFolder: true // 记住上次导出文件夹
    }
    Settings {
        id: uiSettings
        category: "canvas"
        property string bg: "#5E6A74"     // 预览台底色（默认中性板岩，白/深水印都看得清）
        property bool checker: false      // true=透明棋盘格
    }

    function saveWmMemory() {
        if (_suppressMemorySave) return
        if (preview.gifOrigW > 0 && preview.gifOrigH > 0) {
            wmSettings.posXRatio = preview.gifCenterX / preview.gifOrigW
            wmSettings.posYRatio = preview.gifCenterY / preview.gifOrigH
            wmSettings.scale = window.wmScale
            wmSettings.opacity = window.wmOpacity
            wmSettings.rotate = window.wmRotate
            wmSettings.lastX = preview.gifCenterX
            wmSettings.lastY = preview.gifCenterY
        }
        // 记住上次水印时，连同水印本体一起存
        if (wmSettings.memoryEnabled) {
            wmSettings.waterPath = window.waterPath
            wmSettings.useTextWater = window.useTextWater
            wmSettings.textContent = window.textContent
            wmSettings.textFontSize = window.textFontSize
            wmSettings.textColor = window.textColor
        }
    }

    onGifPathChanged: {
        _previewPath = ""
        _suppressMemorySave = true
        _restorePending = wmSettings.memoryEnabled
        if (window.gifPath !== "") {
            _previewPath = runner.extractPreview(window.gifPath)
            // 导出路径：记住文件夹→用上次目录；否则留空待用户选择
            var dir = ""
            if (prefs.rememberOutFolder && dlgSettings.outFolder !== "") {
                dir = dlgSettings.outFolder
            }
            if (dir !== "") {
                var gifName = window.gifPath.replace(/^.*[\\/]/, "").replace(/\.gif$/i, "")
                var d = new Date()
                var ts = "" + d.getFullYear() + pad(d.getMonth()+1) + pad(d.getDate())
                          + pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds())
                window.outPath = dir + "/" + gifName + "_" + ts + ".gif"
            } else {
                window.outPath = ""
            }
        }
    }

    onWaterPathChanged: {
        if (wmSettings.memoryEnabled && !_suppressMemorySave) wmSettings.waterPath = window.waterPath
        if (window.waterPath !== "" && window.gifPath !== "" && preview.gifOrigW > 0) {
            // 有记忆→回到上次位置；否则落默认位置（右下）
            if (wmSettings.memoryEnabled)
                preview.restorePosition(wmSettings.posXRatio, wmSettings.posYRatio)
            else
                preview.setGifPosition(preview.gifOrigW * window.defPosXRatio,
                                       preview.gifOrigH * window.defPosYRatio)
        }
    }
    onUseTextWaterChanged: saveWmMemory()
    onTextContentChanged: saveWmMemory()
    onTextFontSizeChanged: saveWmMemory()
    onTextColorChanged: saveWmMemory()

    function onPreviewReady() {
        _suppressMemorySave = false
        if (_restorePending && preview.gifOrigW > 0) {
            _restorePending = false
            window.wmScale = wmSettings.scale
            window.wmOpacity = wmSettings.opacity
            window.wmRotate = wmSettings.rotate
            preview.restorePosition(wmSettings.posXRatio, wmSettings.posYRatio)
            saveWmMemory()
        } else if (preview.gifOrigW > 0) {
            // 不记位置时，GIF 加载后水印落到默认位置（右下）
            preview.setGifPosition(preview.gifOrigW * window.defPosXRatio,
                                   preview.gifOrigH * window.defPosYRatio)
        }
    }

    // 启动恢复：深度压缩默认值 + 上次水印（图片/文字，位置随 GIF 加载后再恢复）
    Component.onCompleted: {
        window.deepOptimize = prefs.deepCompress
        if (wmSettings.memoryEnabled) {
            _suppressMemorySave = true
            window.useTextWater = wmSettings.useTextWater
            window.textContent = wmSettings.textContent
            window.textFontSize = wmSettings.textFontSize
            window.textColor = wmSettings.textColor
            window.waterPath = wmSettings.waterPath   // 最后赋值，触发 onWaterPathChanged（此时无 GIF，仅载入）
            // 无 GIF 时也把上次位置填进位置框（台面不显示水印，但位置有内容）
            preview.gifCenterX = wmSettings.lastX
            preview.gifCenterY = wmSettings.lastY
            _suppressMemorySave = false
        }
    }

    // 深度压缩：设置项与检视器共用同一持久值
    function setDeepOptimize(v) {
        window.deepOptimize = v
        prefs.deepCompress = v
    }

    function pad(n) { return n < 10 ? "0" + n : "" + n }
    function urlToPath(u) {
        var s = u.toString()
        if (s.startsWith("file:///")) s = s.substring(8)
        try { return decodeURIComponent(s) } catch (e) { return s }
    }
    function baseName(p) { return p.replace(/^.*[\\/]/, "") }

    readonly property bool canExport: !runner.running && gifPath !== ""
                                      && (waterPath !== "" || (useTextWater && textContent !== ""))
                                      && outPath !== ""
    function exportBlockReason() {
        if (gifPath === "") return qsTr("请先选择 GIF")
        if (waterPath === "" && !(useTextWater && textContent !== "")) return qsTr("请先设置水印")
        if (outPath === "") return qsTr("请先选择导出位置")
        return ""
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
            if (ok) { toast.show(qsTr("导出完成"), true, path); stamp.press() }
            else if (status === FFmpegRunner.ExportCancelled) toast.show(qsTr("已取消"), false, "")
            else toast.show(qsTr("导出失败") + (err ? " · " + err : ""), false, "")
        }
    }

    // ======================= 舞台 + 浮动玻璃 =======================
    Item {
        id: rootArea
        anchors.fill: parent

        // ---- 台面层（被玻璃采样：发光地面 + 预览）----
        Item {
            id: stageLayer
            anchors.fill: parent

            // 发光地面
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.groundTop }
                    GradientStop { position: 0.55; color: Theme.groundMid }
                    GradientStop { position: 1.0; color: Theme.groundBot }
                }
            }

            CanvasPreview {
                id: preview
                anchors.fill: parent
                leftInset: window.m
                topInset: window.m + window.stripH + window.m
                rightInset: window.m + window.inspW + window.m
                bottomInset: window.m + window.statusH + window.m
                canvasColor: uiSettings.bg
                canvasChecker: uiSettings.checker
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
                onWmScaleAdjusted: function(s) { window.wmScale = s }
                onWmRotateAdjusted: function(r) { window.wmRotate = r }
                onTextFontSizeAdjusted: function(sz) { window.textFontSize = sz }
                onPreviewReady: window.onPreviewReady()
            }
        }

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

        // ===== 顶部命令条（玻璃）=====
        GlassPanel {
            id: stripGlass
            stageItem: stageLayer
            x: window.m; y: window.m
            width: parent.width - 2 * window.m
            height: window.stripH

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14; anchors.rightMargin: 14
                spacing: 14

                // 字标：应用图标
                RowLayout {
                    spacing: 10
                    AppMark { size: 32 }
                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: "GifWaterMarkTool"
                            color: Theme.text
                            font.family: Theme.fontUI
                            font.pixelSize: 14; font.bold: true
                        }
                        Text {
                            text: "v1.0.1"
                            color: Theme.textFaint
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 28; color: Theme.line; opacity: 0.7 }

                FileChip {
                    glyph: "GIF"
                    role: qsTr("GIF 文件")
                    accent: Theme.jade
                    value: window.gifPath ? window.baseName(window.gifPath) : ""
                    hint: qsTr("点击选择或拖入")
                    onClicked: gifDialog.open()
                    onCleared: { window.gifPath = ""; window._previewPath = "" }
                }
                FileChip {
                    glyph: "OUT"
                    role: qsTr("导出到")
                    accent: Theme.textDim
                    value: window.outPath ? window.baseName(window.outPath) : ""
                    hint: qsTr("选择保存文件夹")
                    onClicked: outDialog.open()
                    onCleared: window.outPath = ""
                }

                Item { Layout.fillWidth: true }

                AppButton {
                    text: qsTr("设置")
                    kind: "ghost"
                    onClicked: settingsDlg.open()
                }
                AppButton {
                    text: qsTr("取消")
                    kind: "ghost"
                    visible: runner.running
                    onClicked: runner.cancelExport()
                }
                AppButton {
                    id: exportBtn
                    text: runner.running ? qsTr("导出中…") : qsTr("导出 GIF")
                    kind: "primary"
                    implicitHeight: 38
                    leftPadding: 18; rightPadding: 18
                    enabled: window.canExport
                    onClicked: runner.exportGif()
                    ToolTip.visible: hovered && !window.canExport && !runner.running
                    ToolTip.text: window.exportBlockReason()
                    ToolTip.delay: 300
                }
            }
        }

        // ===== 右侧检视器（玻璃）=====
        GlassPanel {
            id: inspectorGlass
            stageItem: stageLayer
            width: window.inspW
            anchors.right: parent.right
            anchors.rightMargin: window.m
            anchors.top: stripGlass.bottom
            anchors.topMargin: window.m
            anchors.bottom: parent.bottom
            anchors.bottomMargin: window.m

            Inspector {
                id: inspector
                anchors.fill: parent
                useTextWater: window.useTextWater
                waterPath: window.waterPath
                textContent: window.textContent
                textFontSize: window.textFontSize
                textColor: window.textColor
                wmScale: window.wmScale
                wmOpacity: window.wmOpacity
                wmRotate: window.wmRotate
                gifCenterX: preview.gifCenterX
                gifCenterY: preview.gifCenterY
                maxWidth: window.maxWidth
                targetFps: window.targetFps
                qualityLevel: window.qualityLevel
                ditherMode: window.ditherMode
                deepOptimize: window.deepOptimize
                memoryEnabled: wmSettings.memoryEnabled
                hasGif: preview.gifOrigW > 0
                canvasBg: uiSettings.bg
                canvasChecker: uiSettings.checker

                onUseTextWaterRequested: function(v) { window.useTextWater = v }
                onWaterPathRequested: waterDialog.open()
                onTextContentEdited: function(v) { window.textContent = v }
                onTextFontSizeEdited: function(v) { window.textFontSize = v }
                onTextColorEdited: function(v) { window.textColor = v }
                onWmScaleRequested: function(v) { window.wmScale = v }
                onWmOpacityRequested: function(v) { window.wmOpacity = v }
                onWmRotateRequested: function(v) { window.wmRotate = v }
                onWmXRequested: function(v) { preview.setGifPosition(v, preview.gifCenterY) }
                onWmYRequested: function(v) { preview.setGifPosition(preview.gifCenterX, v) }
                onCenterRequested: preview.setGifPosition(preview.gifOrigW / 2, preview.gifOrigH / 2)
                onDefaultRequested: preview.setGifPosition(preview.gifOrigW * window.defPosXRatio,
                                                           preview.gifOrigH * window.defPosYRatio)
                onMaxWidthEdited: function(v) { window.maxWidth = v }
                onTargetFpsEdited: function(v) { window.targetFps = v }
                onQualityLevelEdited: function(v) { window.qualityLevel = v }
                onDitherModeEdited: function(v) { window.ditherMode = v }
                onDeepOptimizeToggled: function(v) { window.setDeepOptimize(v) }
                onMemoryToggled: function(v) { wmSettings.memoryEnabled = v }
                onCanvasCheckerRequested: uiSettings.checker = true
                onCanvasColorRequested: function(hex) { uiSettings.checker = false; uiSettings.bg = hex }
            }
        }

        // ===== 底部仪表胶囊（玻璃）=====
        GlassPanel {
            id: statusGlass
            stageItem: stageLayer
            radius: Theme.radiusSm
            x: window.m
            height: window.statusH
            width: statusRow.implicitWidth + 28
            anchors.bottom: parent.bottom
            anchors.bottomMargin: window.m

            RowLayout {
                id: statusRow
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: preview.gifOrigW > 0
                          ? Math.round(preview.gifOrigW) + "×" + Math.round(preview.gifOrigH)
                          : "—×—"
                    color: preview.gifOrigW > 0 ? Theme.textDim : Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 12; color: Theme.line }
                Text {
                    text: window.useTextWater ? qsTr("文字水印") : qsTr("图片水印")
                    color: Theme.textDim
                    font.family: Theme.fontUI
                    font.pixelSize: 11
                }
                Text {
                    visible: preview.gifOrigW > 0
                    text: "@ " + Math.round(preview.gifCenterX) + ", " + Math.round(preview.gifCenterY)
                    color: Theme.textFaint
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
                Rectangle {
                    Layout.preferredWidth: 1; Layout.preferredHeight: 12; color: Theme.line
                    visible: runner.running
                }
                Text {
                    visible: runner.running
                    text: qsTr("导出中 ") + runner.progress + "%"
                    color: Theme.seal
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                }
            }
        }

        // ===== 盖章动画 =====
        Item {
            id: stamp
            width: 150; height: 150
            opacity: 0
            z: 40
            x: window.m + (rootArea.width - window.m - (window.m + window.inspW + window.m)) / 2 - width / 2
            y: (window.m + window.stripH + window.m)
               + (rootArea.height - (window.m + window.stripH + window.m) - (window.m + window.statusH + window.m)) / 2
               - height / 2
            function press() { stampAnim.restart() }
            AppMark {
                anchors.centerIn: parent
                size: 132
            }
            SequentialAnimation {
                id: stampAnim
                PropertyAction { target: stamp; property: "scale"; value: 1.8 }
                PropertyAction { target: stamp; property: "opacity"; value: 0 }
                ParallelAnimation {
                    NumberAnimation { target: stamp; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                    NumberAnimation { target: stamp; property: "opacity"; to: 0.95; duration: 120 }
                }
                PauseAnimation { duration: 440 }
                NumberAnimation { target: stamp; property: "opacity"; to: 0; duration: 320 }
            }
        }

        // ===== 底部细进度线 =====
        Rectangle {
            visible: runner.running
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 3
            width: parent.width * (runner.progress / 100)
            color: Theme.seal
            Behavior on width { NumberAnimation { duration: 120 } }
        }

        // ===== 设置弹窗（毛玻璃，浮于应用之上）=====
        SettingsDialog {
            id: settingsDlg
            appVersion: "v1.0.1"
            rememberWatermark: wmSettings.memoryEnabled
            deepCompress: prefs.deepCompress
            rememberOutFolder: prefs.rememberOutFolder
            onRememberWatermarkToggled: function(v) { wmSettings.memoryEnabled = v }
            onDeepCompressToggled: function(v) { window.setDeepOptimize(v) }
            onRememberOutFolderToggled: function(v) { prefs.rememberOutFolder = v }
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
