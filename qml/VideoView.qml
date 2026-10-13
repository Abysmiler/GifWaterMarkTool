import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import GifWaterMarkTool

// 转视频工作台 —— 「剪辑台」左右布局：左竖向胶片清单（媒体池）、右看片台、底部参数条。
// 自包含视图：自带背景层供玻璃采样；只依赖 core/VideoExporter，可整体抽出做独立软件。
Item {
    id: view
    anchors.fill: parent

    // ---- 任务模型：{path, name, durationMs, width, height, previewUrl, loops, status, err, outPath, progress} ----
    property var tasks: []
    readonly property int  doneCount: tasks.filter(function(t){ return t.status === "ok" }).length
    readonly property int  failCount: tasks.filter(function(t){ return t.status === "fail" }).length
    readonly property int  pendingCount: tasks.filter(function(t){ return t.status === "wait" }).length
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
    readonly property var qualityLabels: [qsTr("最高"), qsTr("均衡"), qsTr("较小")]
    readonly property var crfOptions: [18, 20, 23]

    Settings {
        id: vsSettings
        category: "videostudio"
        property int resIndex: 1        // 默认 1080p
        property int fpsIndex: 2        // 默认 60
        property int qualityIndex: 1    // 默认 均衡
        property string outFolder: ""
    }

    // ---- 队列调度 ----
    property int current: -1        // 正在导出的任务下标；-1 空闲
    property bool running: false
    property int selectedIndex: -1

    readonly property var activeTask: {
        if (tasks.length === 0) return null
        var i = selectedIndex >= 0 && selectedIndex < tasks.length ? selectedIndex : tasks.length - 1
        return tasks[i]
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

    function fmtSec(ms) {
        if (!(ms > 0)) return "—"
        var s = ms / 1000
        return (s >= 10 ? s.toFixed(1) : s.toFixed(2)) + "s"
    }

    function addTask(path) {
        for (var i = 0; i < tasks.length; i++)
            if (tasks[i].path === path && tasks[i].status === "wait") { toast.show(qsTr("该 GIF 已在清单里"), false, ""); return }
        var info = exporter.probeGif(path)
        var task = {
            path: path,
            name: path.replace(/^.*[\\/]/, ""),
            durationMs: info.durationMs,
            width: info.width,
            height: info.height,
            previewUrl: "",
            // 默认循环：选使成片最接近 2s 的循环数（round(2s/源时长)，≥1；
            // 如 1s→×2、0.64s→×3≈1.92s、1.8s→×1 不硬凑）；源时长未知则 ×1
            loops: info.durationMs > 0 ? Math.max(1, Math.round(2000 / info.durationMs)) : 1,
            status: "wait", err: "", outPath: "", progress: 0
        }
        tasks.push(task)
        tasks = tasks.slice()
        selectedIndex = tasks.length - 1
        task.previewUrl = exporter.extractPreview(path)
        tasks = tasks.slice()
    }

    function removeTask(i) {
        tasks.splice(i, 1)
        tasks = tasks.slice()
        if (selectedIndex >= tasks.length)
            selectedIndex = tasks.length - 1
    }

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: window.m
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // ============ 左：看片台 ============
            GlassPanel {
                id: stageGlass
                stageItem: bgLayer
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 头：眉标 + 选中段名 + 读数（尺寸 · 源时长 → 成片时长）
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16; anchors.rightMargin: 16
                            spacing: 10
                            Rectangle { width: 3; height: 12; radius: 1.5; color: Theme.seal }
                            Text {
                                text: qsTr("画面")
                                color: Theme.text
                                font.family: Theme.fontUI
                                font.pixelSize: 13; font.bold: true
                            }
                            Text {
                                id: fileNameText
                                Layout.fillWidth: true
                                text: view.activeTask ? view.activeTask.name : ""
                                visible: view.activeTask !== null
                                color: Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                            // 读数胶囊（Layout 按 implicitWidth 分配宽度，勿用 width 绑定——会被 Layout 覆盖）
                            Rectangle {
                                id: capsuleRect
                                visible: view.activeTask !== null
                                implicitWidth: Math.min(metaRow.implicitWidth + 20, 300)
                                implicitHeight: 28
                                radius: Theme.radiusSm
                                color: Theme.panel
                                border.width: 1; border.color: Theme.line
                                RowLayout {
                                    id: metaRow
                                    anchors.centerIn: parent
                                    width: Math.min(implicitWidth, capsuleRect.width - 12)
                                    spacing: 8
                                    Text {
                                        text: view.activeTask && view.activeTask.width > 0
                                              ? view.activeTask.width + "×" + view.activeTask.height : "—"
                                        color: Theme.textDim
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                    }
                                    Rectangle { width: 1; height: 10; color: Theme.line }
                                    Text {
                                        Layout.maximumWidth: 70
                                        text: view.activeTask ? view.fmtSec(view.activeTask.durationMs) : ""
                                        color: Theme.textDim
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                    }
                                    Text { text: "→"; color: Theme.textFaint; font.family: Theme.fontMono; font.pixelSize: 11 }
                                    Text {
                                        Layout.maximumWidth: 70
                                        text: view.activeTask
                                              ? view.fmtSec(view.activeTask.durationMs > 0 ? view.activeTask.durationMs * view.activeTask.loops : -1)
                                              : ""
                                        color: Theme.jade
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11; font.bold: true
                                    }
                                }
                            }
                            Text {
                                visible: view.tasks.length > 1
                                text: qsTr("第 %1 / %2 段")
                                      .arg(view.selectedIndex >= 0 ? view.selectedIndex + 1 : view.tasks.length)
                                      .arg(view.tasks.length)
                                color: Theme.textFaint
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.lineSoft }
                    }

                    // 看片区：整片台面铺满（空白处是材质不是死白），相框卡悬浮其上
                    Item {
                        id: cardArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // 台面（发光渐变，水印同语言）
                        Rectangle {
                            id: stagePad
                            anchors.fill: parent
                            anchors.margins: 12
                            radius: Theme.radiusSm
                            color: Theme.stageBg
                            border.width: 1; border.color: Theme.lineSoft
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(1,1,1,0.35) }
                                    GradientStop { position: 0.55; color: Qt.rgba(1,1,1,0.08) }
                                    GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.0) }
                                }
                            }
                        }

                        property real srcW: view.activeTask && view.activeTask.width > 0 ? view.activeTask.width : 16
                        property real srcH: view.activeTask && view.activeTask.height > 0 ? view.activeTask.height : 9
                        property real maxW: stagePad.width - 56
                        property real maxH: stagePad.height - 64
                        property real fit: Math.min(maxW / srcW, maxH / srcH)

                        // 柔投影
                        Rectangle {
                            anchors.horizontalCenter: stagePad.horizontalCenter
                            anchors.verticalCenter: stagePad.verticalCenter
                            anchors.verticalCenterOffset: 8
                            width: frameCard.width; height: frameCard.height
                            radius: frameCard.radius + 2
                            color: Qt.rgba(0.19, 0.31, 0.37, 0.20)
                            visible: frameCard.visible
                        }

                        // 相框卡
                        Rectangle {
                            id: frameCard
                            anchors.horizontalCenter: stagePad.horizontalCenter
                            anchors.verticalCenter: stagePad.verticalCenter
                            width: Math.max(140, cardArea.srcW * cardArea.fit)
                            height: Math.max(88, cardArea.srcH * cardArea.fit)
                            radius: 6
                            color: "#ffffff"
                            border.width: 1; border.color: Theme.line
                            clip: true
                            visible: view.activeTask !== null

                            Image {
                                anchors.fill: parent
                                anchors.margins: 8
                                source: view.activeTask ? view.activeTask.previewUrl : ""
                                fillMode: Image.PreserveAspectFit
                                mipmap: true; cache: false; asynchronous: true
                            }
                        }

                        // 空态：邀请
                        Column {
                            anchors.centerIn: stagePad
                            anchors.verticalCenterOffset: -12
                            visible: view.tasks.length === 0
                            spacing: 10
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("把 GIF 拖进来，或点右侧添加")
                                color: Theme.textDim
                                font.family: Theme.fontUI
                                font.pixelSize: 13
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("同一 GIF 可叠多格、设不同循环，短 GIF 叠成足长视频")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                            }
                            AppButton {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: qsTr("+ 添加 GIF")
                                kind: "primary"
                                implicitHeight: 36
                                leftPadding: 24; rightPadding: 24
                                onClicked: addDialog.open()
                            }
                        }
                    }
                }
            }

            // ============ 右：转换清单（媒体池）===========
            GlassPanel {
                id: listGlass
                stageItem: bgLayer
                Layout.preferredWidth: 300
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 头部
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14; anchors.rightMargin: 10
                            spacing: 10
                            Rectangle { width: 3; height: 12; radius: 1.5; color: Theme.seal }
                            Text {
                                text: qsTr("转换清单")
                                color: Theme.text
                                font.family: Theme.fontUI
                                font.pixelSize: 13; font.bold: true
                                Layout.fillWidth: true
                            }
                            AppButton {
                                text: qsTr("+ 添加")
                                kind: "primary"
                                implicitHeight: 30
                                onClicked: addDialog.open()
                            }
                        }
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.lineSoft }
                    }

                    // 竖向帧格列
                    Flickable {
                        id: filmFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: Math.max(filmCol.implicitHeight, height)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: filmCol
                            width: filmFlick.width
                            spacing: 10

                            // 空态
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: view.tasks.length === 0
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: qsTr("清单空着")
                                        color: Theme.textDim
                                        font.family: Theme.fontUI
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: qsTr("点上方添加或直接拖入 GIF")
                                        color: Theme.textFaint
                                        font.family: Theme.fontUI
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Repeater {
                                model: view.tasks

                                Rectangle {
                                    id: frame
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 10
                                    Layout.rightMargin: 10
                                    implicitHeight: 208
                                    height: implicitHeight
                                    radius: Theme.radiusSm
                                    color: view.selectedIndex === index ? Theme.panel : Theme.stageBg
                                    border.width: 1
                                    border.color: view.selectedIndex === index ? Theme.seal : Theme.line
                                    Behavior on border.color { ColorAnimation { duration: Theme.quick } }
                                    Behavior on color { ColorAnimation { duration: Theme.quick } }

                                    // 选中左竖条
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 3
                                        color: view.selectedIndex === frame.index ? Theme.seal : "transparent"
                                    }

                                    // 整格点击选中 + 悬停（必须先于可交互子项声明，
                                    // 后声明者在上层会拦截 ±/输入框/删除的鼠标事件）
                                    MouseArea {
                                        id: failMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: view.selectedIndex = frame.index
                                    }

                                    // 缩略（Fit 完整显示）
                                    Rectangle {
                                        id: thumbClip
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 8
                                        height: 132
                                        radius: Theme.radiusXs
                                        color: Theme.panel
                                        clip: true
                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            source: frame.modelData.previewUrl
                                            fillMode: Image.PreserveAspectFit
                                            mipmap: true
                                            cache: false
                                            asynchronous: true
                                            opacity: frame.modelData.status === "fail" ? 0.4 : 1.0
                                        }
                                        // 导出中进度线
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.bottom: parent.bottom
                                            height: 3
                                            width: parent.width * (frame.modelData.progress || 0) / 100
                                            color: Theme.seal
                                            visible: frame.modelData.status === "run"
                                        }
                                        // 状态角标
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.margins: 5
                                            width: 9; height: 9; radius: 4.5
                                            color: frame.modelData.status === "ok" ? Theme.ok
                                                 : frame.modelData.status === "fail" ? Theme.seal
                                                 : frame.modelData.status === "run" ? Theme.sealHi
                                                 : Theme.line
                                        }
                                    }

                                    // 文件名
                                    Text {
                                        id: nameText
                                        anchors.top: thumbClip.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        anchors.topMargin: 5
                                        text: frame.modelData.name
                                        color: frame.modelData.status === "fail" ? Theme.seal : Theme.text
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        elide: Text.ElideMiddle
                                    }

                                    // 失败原因
                                    Text {
                                        visible: frame.modelData.err !== ""
                                        anchors.top: nameText.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        anchors.topMargin: 2
                                        text: frame.modelData.err
                                        color: Theme.seal
                                        font.family: Theme.fontUI
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }

                                    // ×N 步进 + 成片
                                    RowLayout {
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        anchors.bottomMargin: 7
                                        spacing: 5
                                        NumberField {
                                            implicitWidth: 82
                                            implicitHeight: 26
                                            from: 1; to: 999
                                            value: frame.modelData.loops
                                            enabled: !view.running && frame.modelData.status !== "ok"
                                            onEdited: function(v) {
                                                view.tasks[frame.index].loops = Math.round(v)
                                                view.tasks = view.tasks.slice()
                                            }
                                        }
                                        Text {
                                            text: "="
                                            color: Theme.textFaint
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: view.fmtSec(frame.modelData.durationMs > 0
                                                              ? frame.modelData.durationMs * frame.modelData.loops : -1)
                                            color: Theme.jade
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11; font.bold: true
                                        }
                                    }

                                    // 失败原因（悬停提示）
                                    ToolTip.visible: failMa.containsMouse && frame.modelData.err !== ""
                                    ToolTip.delay: 200
                                    ToolTip.text: frame.modelData.err || ""

                                    // 删除（悬停右上角）
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 4
                                        width: 20; height: 20; radius: 10
                                        color: rmMa.containsMouse ? Theme.panelHover : Theme.panel
                                        opacity: failMa.containsMouse || rmMa.containsMouse ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: Theme.quick } }
                                        Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 12; color: Theme.textDim }
                                        MouseArea {
                                            id: rmMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !view.running
                                            onClicked: view.removeTask(frame.index)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 底部读数
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.lineSoft }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            spacing: 8
                            Text {
                                text: view.tasks.length
                                color: Theme.text
                                font.family: Theme.fontMono
                                font.pixelSize: 15; font.bold: true
                            }
                            Text { text: qsTr("段"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11 }
                            Rectangle { width: 1; height: 12; color: Theme.line; Layout.leftMargin: 2; Layout.rightMargin: 2 }
                            Text {
                                text: "≈ " + view.totalOutSec.toFixed(1) + "s"
                                color: Theme.jade
                                font.family: Theme.fontMono
                                font.pixelSize: 15; font.bold: true
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                visible: view.failCount > 0
                                text: view.failCount + qsTr(" 败")
                                color: Theme.seal
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

    }

    // ---- 参数弹层（三份同构：主题面板底 + 单行 Segmented，选中即收起；定位于参数条上方）----
    Popup {
        id: resPopup
        x: 16
        y: view.height - implicitHeight - 92
        width: 300
        padding: 16
        modal: false
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.quick }
            NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: Theme.quick; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 100 }
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: Theme.radius; color: Theme.panel; border.width: 1; border.color: Theme.line }
        contentItem: ColumnLayout {
            spacing: 10
            Text { text: qsTr("分辨率"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true }
            Segmented {
                Layout.fillWidth: true
                model: view.resPresets.map(function(r) { return r.label })
                currentIndex: vsSettings.resIndex
                onActivated: function(i) { vsSettings.resIndex = i; resPopup.close() }
            }
        }
        }
        // ============ 参数条 + 导出（玻璃；全部控件统一 36px 高）============
        GlassPanel {
            id: specGlass
            stageItem: bgLayer
            Layout.fillWidth: true
            Layout.preferredHeight: 60

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 14
                spacing: 10

                // REC 式参数读数（点击弹层调参）
                Rectangle {
                    radius: Theme.radiusSm
                    color: segMa1.containsMouse ? Theme.panelHover : Theme.panelHi
                    border.width: 1; border.color: Theme.line
                    implicitWidth: resRead.implicitWidth + 20
                    implicitHeight: 36
                    RowLayout {
                        id: resRead
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: qsTr("分辨率"); color: Theme.textFaint; font.family: Theme.fontUI; font.pixelSize: 10 }
                        Text { text: view.resPresets[vsSettings.resIndex].label; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 12; font.bold: true }
                    }
                    MouseArea {
                        id: segMa1
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: resPopup.open()
                    }
                }
                Rectangle {
                    radius: Theme.radiusSm
                    color: segMa2.containsMouse ? Theme.panelHover : Theme.panelHi
                    border.width: 1; border.color: Theme.line
                    implicitWidth: fpsRead.implicitWidth + 20
                    implicitHeight: 36
                    RowLayout {
                        id: fpsRead
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: qsTr("帧率"); color: Theme.textFaint; font.family: Theme.fontUI; font.pixelSize: 10 }
                        Text { text: view.fpsOptions[vsSettings.fpsIndex] + "fps"; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 12; font.bold: true }
                    }
                    MouseArea {
                        id: segMa2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: fpsPopup.open()
                    }
                }
                Rectangle {
                    radius: Theme.radiusSm
                    color: segMa3.containsMouse ? Theme.panelHover : Theme.panelHi
                    border.width: 1; border.color: Theme.line
                    implicitWidth: qRead.implicitWidth + 20
                    implicitHeight: 36
                    RowLayout {
                        id: qRead
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: qsTr("画质"); color: Theme.textFaint; font.family: Theme.fontUI; font.pixelSize: 10 }
                        Text { text: view.qualityLabels[vsSettings.qualityIndex]; color: Theme.text; font.family: Theme.fontMono; font.pixelSize: 12; font.bold: true }
                    }
                    MouseArea {
                        id: segMa3
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: qualityPopup.open()
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Theme.line }

                // 输出文件夹
                FileChip {
                    implicitHeight: 36
                    glyph: "DIR"
                    role: qsTr("输出到")
                    accent: Theme.jade
                    value: vsSettings.outFolder ? vsSettings.outFolder.replace(/^.*[\\/]/, "") : ""
                    hint: qsTr("选择文件夹")
                    maxWidth: 220
                    onClicked: outDialog.open()
                    onCleared: vsSettings.outFolder = ""
                    onOpenFolderRequested: {
                        if (!exporter.openContainingFolder(vsSettings.outFolder))
                            toast.show(qsTr("无法打开文件夹"), false, "")
                    }
                }

                Item { Layout.fillWidth: true }

                // 总时长读数 + 成功勾
                Text {
                    text: "✓"
                    visible: stampAnim.running
                    color: Theme.ok
                    font.pixelSize: 16; font.bold: true
                    Layout.rightMargin: 2
                }
                Text {
                    text: "≈ " + view.totalOutSec.toFixed(1) + "s"
                    color: Theme.jade
                    font.family: Theme.fontMono
                    font.pixelSize: 16; font.bold: true
                }
                Text { text: qsTr("成片"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11 }

                // 导出状态/按钮
                Text {
                    visible: view.running
                    text: qsTr("%1/%2 · %3%").arg(view.current + 1).arg(view.tasks.length).arg(exporter.progress)
                    color: Theme.seal
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
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
                    implicitHeight: 36
                    leftPadding: 20; rightPadding: 20
                    enabled: !view.running && view.pendingCount > 0 && vsSettings.outFolder !== ""
                    onClicked: view.startExport()
                    ToolTip.visible: hovered && !view.running && vsSettings.outFolder === "" && view.pendingCount > 0
                    ToolTip.text: qsTr("请先选择输出文件夹")
                    ToolTip.delay: 300
                }
            }

            // 成功勾闪现动画
            SequentialAnimation {
                id: stampAnim
                PauseAnimation { duration: 300 }
                NumberAnimation { target: checkMark; property: "scale"; from: 1.8; to: 1.0; duration: 160; easing.type: Easing.OutBack }
                PauseAnimation { duration: 500 }
                NumberAnimation { target: checkMark; property: "opacity"; to: 0; duration: 300 }
            }
            Text {
                id: checkMark
                text: "✓"
                visible: stampAnim.running || opacity > 0
                color: Theme.ok
                font.pixelSize: 18; font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 12
                opacity: 0
                scale: 1.0
            }
        }
    }
    Popup {
        id: fpsPopup
        x: 16
        y: view.height - implicitHeight - 92
        width: 300
        padding: 16
        modal: false
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.quick }
            NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: Theme.quick; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 100 }
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: Theme.radius; color: Theme.panel; border.width: 1; border.color: Theme.line }
        contentItem: ColumnLayout {
            spacing: 10
            Text { text: qsTr("帧率"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true }
            Segmented {
                Layout.fillWidth: true
                model: view.fpsOptions.map(function(f) { return f + " fps" })
                currentIndex: vsSettings.fpsIndex
                onActivated: function(i) { vsSettings.fpsIndex = i; fpsPopup.close() }
            }
        }
    }
    Popup {
        id: qualityPopup
        x: 16
        y: view.height - implicitHeight - 92
        width: 300
        padding: 16
        modal: false
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.quick }
            NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: Theme.quick; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 100 }
        }
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: Theme.radius; color: Theme.panel; border.width: 1; border.color: Theme.line }
        contentItem: ColumnLayout {
            spacing: 10
            Text { text: qsTr("画质"); color: Theme.textDim; font.family: Theme.fontUI; font.pixelSize: 11; font.bold: true }
            Segmented {
                Layout.fillWidth: true
                model: view.qualityLabels
                currentIndex: vsSettings.qualityIndex
                onActivated: function(i) { vsSettings.qualityIndex = i; qualityPopup.close() }
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
