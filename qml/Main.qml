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
    property int  qualityLevel: 1
    property int  compressPreset: 0
    property int  maxWidth: 0
    property int  targetFps: 0
    property int  ditherMode: 0
    property bool deepOptimize: true
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

                Button {
                    text: qsTr("取消")
                    visible: runner.running
                    onClicked: runner.cancelExport()
                }

                Item { Layout.fillWidth: true }

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: window.divider
        }

        // === 预览区 ===
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

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

            ProgressBar {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 20
                visible: runner.running
                value: runner.progress / 100
                z: 10
            }

            // 抽屉遮罩
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
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: window.drawerOpen ? parent.width - width : parent.width
        z: 10
        color: window.cardBg

        Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

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

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ParameterPanel {
                    id: paramPanel
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
                    onTextContentChanged: window.textContent = paramPanel.textContent
                    onTextFontSizeChanged: window.textFontSize = paramPanel.textFontSize
                    onTextColorChanged: window.textColor = paramPanel.textColor
                    onCompressPresetChanged: window.compressPreset = paramPanel.compressPreset
                    onMaxWidthChanged: window.maxWidth = paramPanel.maxWidth
                    onTargetFpsChanged: window.targetFps = paramPanel.targetFps
                    onQualityLevelChanged: window.qualityLevel = paramPanel.qualityLevel
                    onDitherModeChanged: window.ditherMode = paramPanel.ditherMode
                    onDeepOptimizeChanged: window.deepOptimize = paramPanel.deepOptimize
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
