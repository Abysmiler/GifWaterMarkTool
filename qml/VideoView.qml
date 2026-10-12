import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import GifWaterMarkTool

// 转视频工作台（自包含视图：自带台面底、玻璃面板、任务清单、输出设置与导出栏）。
// 只依赖 core/VideoExporter（同样自包含），未来可整体抽出做独立软件。
// 布局：左侧任务清单（每行：文件 + 源时长 × 循环 = 成片时长），右侧输出设置栏，底部导出栏。
Item {
    id: view
    anchors.fill: parent

    // ---- 任务模型：{path, name, durationMs, loops, status: wait|run|ok|fail, err, outPath} ----
    property var tasks: []
    readonly property int  doneCount: tasks.filter(function(t){ return t.status === "ok" }).length
    readonly property int  failCount: tasks.filter(function(t){ return t.status === "fail" }).length
    readonly property int  pendingCount: tasks.filter(function(t){ return t.status === "wait" }).length
    // 全部任务成片总时长（秒，未知源时长不计）
    readonly property real totalOutSec: tasks.reduce(function(acc, t) {
        return acc + (t.durationMs > 0 ? t.durationMs * t.loops / 1000 : 0)
    }, 0)

    // ---- 输出预设 ----
    readonly property var resPresets: [
        { label: "720p",  w: 1280,  h: 720  },
        { label: "1080p", w: 1920,  h: 1080 },
        { label: "1440p", w: 2560,  h: 1440 },
        { label: "4K",    w: 3840,  h: 2160 },
        { label: qsTr("原始"), w: 0, h: 0 },   // 不缩放，仅取偶
    ]
    readonly property var fpsOptions: [24, 30, 60]
    readonly property var crfOptions: [18, 20, 23]   // 最高 / 均衡 / 较小

    Settings {
        id: vsSettings
        category: "videostudio"
        property int resIndex: 1        // 默认 1080p
        property int fpsIndex: 2        // 默认 60
        property int qualityIndex: 1    // 默认 均衡
        property string outFolder: ""
    }

    VideoExporter {
        id: exporter
        // 回调内一律 view. 前缀访问视图状态：裸名会解析到 exporter 自身属性（如只读 running）
        onProgressChanged: if (view.current >= 0 && view.current < view.tasks.length) {
            var tp = view.tasks[view.current]; tp.progress = exporter.progress; view.tasks = view.tasks.slice()
        }
        onFinished: function(ok, status, path, err) {
            if (view.current < 0 || view.current >= view.tasks.length) { view.running = false; return }
            var t = view.tasks[view.current]
            if (status === VideoExporter.ExportCancelled) {
                t.status = "wait"; t.progress = 0
                view.tasks = view.tasks.slice()
                view.running = false
                toast.show(qsTr("已取消"), false, "")
                return
            }
            t.status = ok ? "ok" : "fail"
            t.err = ok ? "" : String(err || "导出失败").replace(/\s+/g, " ").slice(0, 160)
            view.tasks = view.tasks.slice()
            view.current++
            if (view.current < view.tasks.length) Qt.callLater(view.exportCurrent)
            else {
                view.running = false
                var okN = view.doneCount, failN = view.failCount
                if (failN > 0) toast.show(qsTr("完成：%1 成功 · %2 失败（行内有原因）").arg(okN).arg(failN), false, "")
                else { toast.show(qsTr("视频导出完成 · 共 %1 段").arg(okN), true, t.outPath); stampAnim.restart() }
            }
        }
    }

    // ---- 队列调度 ----
    property int current: -1        // 正在导出的任务下标；-1 空闲
    property bool running: false

    function fmtSec(ms) {
        if (!(ms > 0)) return "—"
        var s = ms / 1000
        return (s >= 10 ? s.toFixed(1) : s.toFixed(2)) + "s"
    }

    function addTask(path) {
        for (var i = 0; i < tasks.length; i++)
            if (tasks[i].path === path && tasks[i].status === "wait") { toast.show(qsTr("该 GIF 已在清单里"), false, ""); return }
        var info = exporter.probeGif(path)
        tasks.push({
            path: path,
            name: path.replace(/^.*[\\/]/, ""),
            durationMs: info.durationMs,
            // 默认补足 ≈10 秒；源时长未知则 ×1
            loops: info.durationMs > 0 ? Math.max(1, Math.round(10000 / info.durationMs)) : 1,
            status: "wait", err: "", outPath: "", progress: 0
        })
        tasks = tasks.slice()
    }

    function removeTask(i) { tasks.splice(i, 1); tasks = tasks.slice() }

    function outPathFor(t) {
        var dir = vsSettings.outFolder
        if (dir === "") return ""
        var base = t.name.replace(/\.gif$/i, "")
        return dir + "/" + base + "_" + resPresets[vsSettings.resIndex].label
               + fpsOptions[vsSettings.fpsIndex] + ".mp4"
    }

    function startExport() {
        if (running || tasks.length === 0) return
        if (vsSettings.outFolder === "") { toast.show(qsTr("请先选择输出文件夹"), false, ""); return }
        for (var i = 0; i < tasks.length; i++) {
            if (tasks[i].status === "fail") { tasks[i].status = "wait"; tasks[i].err = "" }
            tasks[i].outPath = outPathFor(tasks[i])
        }
        tasks = tasks.slice()
        current = 0
        running = true
        exportCurrent()
    }

    function exportCurrent() {
        if (current < 0 || current >= tasks.length) { running = false; return }
        var t = tasks[current]
        if (t.status === "ok") {   // 跳过已成功
            current++; if (current < tasks.length) Qt.callLater(exportCurrent); else { running = false }
            return
        }
        t.status = "run"; tasks = tasks.slice()
        var res = resPresets[vsSettings.resIndex]
        exporter.exportOne(t.path, t.loops, res.w, res.h,
                           fpsOptions[vsSettings.fpsIndex], crfOptions[vsSettings.qualityIndex],
                           t.outPath)
    }

    // ---- 台面底（独立背景层：玻璃面板采样它，避免面板自采样发灰）----
    Item {
        id: bgLayer
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.groundTop }
                GradientStop { position: 0.55; color: Theme.groundMid }
                GradientStop { position: 1.0; color: Theme.groundBot }
            }
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: function(drag) { drag.accepted = drag.hasUrls }
        onDropped: function(drop) {
            for (var i = 0; i < drop.urls.length; i++) {
                var p = urlToPath(drop.urls[i])
                if (p.toLowerCase().endsWith(".gif")) addTask(p)
            }
        }
    }

    function urlToPath(u) {
        var s = u.toString()
        if (s.startsWith("file:///")) s = s.substring(8)
        try { return decodeURIComponent(s) } catch (e) { return s }
    }

    // ===== 任务清单玻璃面板（左主区）=====
    GlassPanel {
        id: listGlass
        stageItem: bgLayer
        x: window.m; y: window.m
        width: parent.width - 2 * window.m - 316 - window.m
        height: parent.height - 2 * window.m - 64 - window.m

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 面板头：标题 + 朱砂眉标 + 加号
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 10
                    spacing: 10
                    Rectangle { width: 3; height: 12; radius: 1.5; color: Theme.seal }
                    Text {
                        text: qsTr("转换清单")
                        color: Theme.text
                        font.family: Theme.fontUI
                        font.pixelSize: 13; font.bold: true
                    }
                    Text {
                        text: qsTr("同一 GIF 可加多行、设不同循环次数")
                        color: Theme.textFaint
                        font.family: Theme.fontUI
                        font.pixelSize: 10
                        Layout.fillWidth: true
                    }
                    AppButton {
                        text: qsTr("+ 添加 GIF")
                        kind: "primary"
                        implicitHeight: 30
                        onClicked: addDialog.open()
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.lineSoft }
            }

            // 清单体
            Flickable {
                id: taskFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: taskCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: taskCol
                    width: taskFlick.width
                    // 撑满视口让空态垂直居中；内容多时按实际高度滚动
                    height: Math.max(taskFlick.height, taskCol.implicitHeight)
                    spacing: 0

                    // 空态：邀请（Item+anchors.centerIn 双居中，骨架已验证的做法）
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: view.tasks.length === 0

                        Column {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -12
                            spacing: 10
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("把 GIF 拖进来，或点右上角添加")
                                color: Theme.textDim
                                font.family: Theme.fontUI
                                font.pixelSize: 13
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("每行一个任务，右侧设循环次数，短 GIF 叠成足长视频")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                            }
                        }
                    }

                    Repeater {
                        model: view.tasks

                        ColumnLayout {
                            id: taskRow
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 16; Layout.rightMargin: 12
                                Layout.topMargin: 8; Layout.bottomMargin: 8
                                spacing: 10

                                // 状态点
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: taskRow.modelData.status === "ok" ? Theme.ok
                                         : taskRow.modelData.status === "fail" ? Theme.seal
                                         : taskRow.modelData.status === "run" ? Theme.sealHi
                                         : Theme.line
                                }

                                // 文件名 + 失败原因
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        text: taskRow.modelData.name
                                        color: taskRow.modelData.status === "fail" ? Theme.seal : Theme.text
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                    }
                                    Text {
                                        visible: taskRow.modelData.err !== ""
                                        Layout.fillWidth: true
                                        text: taskRow.modelData.err
                                        color: Theme.seal
                                        font.family: Theme.fontUI
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                // 循环步进：源时长 × N
                                RowLayout {
                                    spacing: 7
                                    Text {
                                        text: view.fmtSec(taskRow.modelData.durationMs)
                                        color: Theme.textFaint
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                    }
                                    Text { text: "×"; color: Theme.textFaint; font.pixelSize: 11 }
                                    NumberField {
                                        implicitWidth: 86
                                        from: 1; to: 999
                                        value: taskRow.modelData.loops
                                        enabled: !view.running && taskRow.modelData.status !== "ok"
                                        onEdited: function(v) {
                                            view.tasks[taskRow.index].loops = Math.round(v)
                                            view.tasks = view.tasks.slice()
                                        }
                                    }
                                    Text {
                                        text: "="
                                        color: Theme.textFaint
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                    }
                                    Text {
                                        text: view.fmtSec(taskRow.modelData.durationMs > 0
                                                          ? taskRow.modelData.durationMs * taskRow.modelData.loops : -1)
                                        color: Theme.jade
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12; font.bold: true
                                    }
                                }

                                // 移除
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: rmMa.containsMouse ? Theme.panelHover : "transparent"
                                    Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 13; color: Theme.textFaint }
                                    MouseArea {
                                        id: rmMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !view.running
                                        onClicked: view.removeTask(taskRow.index)
                                    }
                                }
                            }

                            // 行内进度细线（导出中）
                            Rectangle {
                                Layout.fillWidth: true
                                height: 2
                                visible: taskRow.modelData.status === "run"
                                Rectangle {
                                    width: parent.width * (taskRow.modelData.progress || 0) / 100
                                    height: parent.height; color: Theme.seal
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 1; color: Theme.lineSoft
                            }
                        }
                    }
                }
            }

            // 面板底：成片读数（签名：大等宽数字）
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.lineSoft }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 16
                    spacing: 8
                    Text {
                        text: view.tasks.length
                        color: Theme.text
                        font.family: Theme.fontMono
                        font.pixelSize: 18; font.bold: true
                    }
                    Text { text: qsTr("段任务"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11 }
                    Rectangle { width: 1; height: 14; color: Theme.line; Layout.leftMargin: 4; Layout.rightMargin: 4 }
                    Text {
                        text: "≈ " + view.totalOutSec.toFixed(1) + "s"
                        color: Theme.jade
                        font.family: Theme.fontMono
                        font.pixelSize: 18; font.bold: true
                    }
                    Text { text: qsTr("成片总时长"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: view.failCount > 0
                        text: view.failCount + qsTr(" 段失败")
                        color: Theme.seal
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    // ===== 输出设置玻璃面板（右栏）=====
    GlassPanel {
        id: setGlass
        stageItem: bgLayer
        anchors.right: parent.right
        anchors.rightMargin: window.m
        anchors.top: parent.top
        anchors.topMargin: window.m
        width: 316
        height: parent.height - 2 * window.m - 64 - window.m

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    spacing: 10
                    Rectangle { width: 3; height: 12; radius: 1.5; color: Theme.seal }
                    Text {
                        text: qsTr("输出设置")
                        color: Theme.text
                        font.family: Theme.fontUI
                        font.pixelSize: 13; font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.lineSoft }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 16
                spacing: 10

                Text { text: qsTr("分辨率"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true }
                Segmented {
                    Layout.fillWidth: true
                    model: view.resPresets.map(function(r) { return r.label })
                    currentIndex: vsSettings.resIndex
                    onActivated: function(i) { vsSettings.resIndex = i }
                }

                Text { text: qsTr("帧率"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true; Layout.topMargin: 6 }
                Segmented {
                    Layout.fillWidth: true
                    model: view.fpsOptions.map(function(f) { return f + " fps" })
                    currentIndex: vsSettings.fpsIndex
                    onActivated: function(i) { vsSettings.fpsIndex = i }
                }

                Text { text: qsTr("画质"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true; Layout.topMargin: 6 }
                Segmented {
                    Layout.fillWidth: true
                    model: [qsTr("最高"), qsTr("均衡"), qsTr("较小")]
                    currentIndex: vsSettings.qualityIndex
                    onActivated: function(i) { vsSettings.qualityIndex = i }
                }

                Text { text: qsTr("输出到"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true; Layout.topMargin: 6 }
                FileChip {
                    Layout.fillWidth: true
                    glyph: "DIR"
                    role: qsTr("输出文件夹")
                    accent: Theme.jade
                    value: vsSettings.outFolder ? vsSettings.outFolder.replace(/^.*[\\/]/, "") : ""
                    hint: qsTr("选择保存文件夹")
                    maxWidth: 280
                    onClicked: outDialog.open()
                    onCleared: vsSettings.outFolder = ""
                    onOpenFolderRequested: {
                        if (!exporter.openContainingFolder(vsSettings.outFolder))
                            toast.show(qsTr("无法打开文件夹"), false, "")
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: qsTr("H.264 · yuv420p · faststart，微信 / QQ / 浏览器直接可播；GIF 无声，成片亦无声。")
                    color: Theme.textFaint
                    font.family: Theme.fontUI
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    // ===== 底部导出栏胶囊 =====
    GlassPanel {
        id: exportGlass
        stageItem: bgLayer
        radius: Theme.radiusSm
        anchors.left: parent.left
        anchors.leftMargin: window.m
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.m
        width: Math.min(parent.width - 2 * window.m, exportRow.implicitWidth + 28)
        height: 64

        RowLayout {
            id: exportRow
            anchors.fill: parent
            anchors.leftMargin: 16; anchors.rightMargin: 14
            spacing: 12

            // 盖章位（成功动画）
            Item {
                Layout.preferredWidth: view.running ? 0 : 36
                Layout.preferredHeight: 36
                clip: true
                visible: !view.running
                AppMark { id: stampMark; anchors.centerIn: parent; size: 30; opacity: 0 }
                SequentialAnimation {
                    id: stampAnim
                    PropertyAction { target: stampMark; property: "scale"; value: 1.6 }
                    PropertyAction { target: stampMark; property: "opacity"; value: 0 }
                    ParallelAnimation {
                        NumberAnimation { target: stampMark; property: "scale"; to: 1.0; duration: 180; easing.type: Easing.OutBack }
                        NumberAnimation { target: stampMark; property: "opacity"; to: 0.95; duration: 120 }
                    }
                    PauseAnimation { duration: 400 }
                    NumberAnimation { target: stampMark; property: "opacity"; to: 0; duration: 300 }
                }
            }

            Text {
                visible: view.running
                text: qsTr("导出中 %1 · %2%").arg(current + 1).arg(exporter.progress)
                color: Theme.seal
                font.family: Theme.fontMono
                font.pixelSize: 12
            }
            Text {
                visible: !view.running && view.doneCount > 0
                text: qsTr("已完成 %1").arg(view.doneCount)
                color: Theme.ok
                font.family: Theme.fontMono
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }

            AppButton {
                text: qsTr("取消")
                kind: "ghost"
                implicitHeight: 36
                visible: view.running
                onClicked: exporter.cancelExport()
            }
            AppButton {
                text: view.running ? qsTr("导出中…")
                     : qsTr("导出视频") + (view.pendingCount > 0 ? " " + view.pendingCount : "")
                kind: "primary"
                implicitHeight: 38
                leftPadding: 20; rightPadding: 20
                enabled: !view.running && view.pendingCount > 0 && vsSettings.outFolder !== ""
                onClicked: view.startExport()
                ToolTip.visible: hovered && !view.running && vsSettings.outFolder === "" && view.pendingCount > 0
                ToolTip.text: qsTr("请先选择输出文件夹")
                ToolTip.delay: 300
            }
        }
    }

    FolderDialog {
        id: outDialog
        title: qsTr("选择视频输出文件夹")
        currentFolder: vsSettings.outFolder !== "" ? "file:///" + vsSettings.outFolder : ""
        onAccepted: vsSettings.outFolder = urlToPath(selectedFolder)
    }
    FileDialog {
        id: addDialog
        title: qsTr("选择 GIF（可按住 Ctrl 多选）")
        nameFilters: ["GIF (*.gif)"]
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            for (var i = 0; i < selectedFiles.length; i++) addTask(urlToPath(selectedFiles[i]))
        }
    }

    Toast {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 84
        onOpenFolderRequested: function(p) { exporter.openContainingFolder(p) }
    }
}
