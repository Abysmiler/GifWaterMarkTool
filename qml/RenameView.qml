import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import GifWaterMarkTool

// 重命名工作台 —— 「校对单」：顶部大等宽读数（将改名/已符合），
// 朱砂批注线贯通预览清单，清单只列「旧名 → 新名」的变换本身；
// 右侧无框规则栏靠发丝线分隔。内部开放表面，不套内盒。
Item {
    id: view
    anchors.fill: parent

    property var sources: []        // 混合来源：[{kind: "folder"|"file", path}]
    property var items: []          // preview 结果 [{path, dir, oldName, newName, changed, error}]
    property string statusText: ""
    property var customPatterns: [] // 自定义「匹配即删除」正则
    property var replaceRules: []   // 文字替换：[{find, replace}] 字面匹配

    readonly property var changedItems: items.filter(function(it) { return it.changed })
    readonly property int failCount: items.filter(function(it) { return it.error }).length

    function repreview() {
        statusText = ""
        if (sources.length === 0) { items = []; return }
        items = renamer.preview(sources)
    }

    function savePatterns() {
        rnSettings.customPatternsJson = JSON.stringify(customPatterns)
    }

    function doApply() {
        var fails = renamer.apply(items)
        repreview()
        // 失败项按 path 匹配标注原因（失败文件保持原名，重预览后仍显示为"待改名"）
        for (var i = 0; i < fails.length; i++) {
            for (var j = 0; j < items.length; j++) {
                if (items[j].path === fails[i].path) {
                    items[j].error = fails[i].error
                    break
                }
            }
        }
        items = items.slice()   // 触发列表刷新
        statusText = fails.length > 0
            ? qsTr("成功 %1 · 失败 %2（失败文件已保持原名）").arg(changedItems.length - fails.length).arg(fails.length)
            : qsTr("已重命名 %1 个文件").arg(changedItems.length)
    }

    function removeSource(i) {
        sources.splice(i, 1)
        sources = sources.slice()
        repreview()
    }

    function addSource(kind, path) {
        // 去重：同一来源（同类型同路径）不重复添加
        for (var i = 0; i < sources.length; i++)
            if (sources[i].kind === kind && sources[i].path === path) return
        sources.push({ kind: kind, path: path })
        sources = sources.slice()
        repreview()
    }

    Renamer {
        id: renamer
        stripTimestamp: rnSettings.stripTimestamp
        stripBrackets: rnSettings.stripBrackets
        stripCopySuffix: rnSettings.stripCopySuffix
        gifOnly: rnSettings.gifOnly
        recursive: rnSettings.recursive
        customPatterns: view.customPatterns
        replaceRules: view.replaceRules
    }

    Settings {
        id: rnSettings
        category: "renamer"
        property int version: 1
        property bool stripTimestamp: true
        property bool stripBrackets: true
        property bool stripCopySuffix: true
        property bool gifOnly: true
        property bool recursive: false
        property string customPatternsJson: "[]"
        property string replaceRulesJson: "[]"
        property string lastFolder: ""
    }
    Component.onCompleted: {
        try { customPatterns = JSON.parse(rnSettings.customPatternsJson) } catch (e) { customPatterns = [] }
        try { replaceRules = JSON.parse(rnSettings.replaceRulesJson) } catch (e) { replaceRules = [] }
    }
    function saveReplaceRules() {
        rnSettings.replaceRulesJson = JSON.stringify(replaceRules)
    }

    FolderDialog {
        id: addFolderDialog
        title: qsTr("添加要重命名的文件夹")
        currentFolder: rnSettings.lastFolder !== "" ? "file:///" + rnSettings.lastFolder : ""
        onAccepted: {
            rnSettings.lastFolder = urlToPath(currentFolder)
            var p = urlToPath(selectedFolder)
            addSource("folder", p)
        }
    }
    FileDialog {
        id: addFilesDialog
        title: qsTr("选择文件（可按住 Ctrl 多选）")
        nameFilters: ["GIF (*.gif)", qsTr("全部文件 (*)")]
        fileMode: FileDialog.OpenFiles
        onAccepted: {
            for (var i = 0; i < selectedFiles.length; i++)
                addSource("file", urlToPath(selectedFiles[i]))
        }
    }
    function urlToPath(u) {
        var s = u.toString()
        if (s.startsWith("file:///")) s = s.substring(8)
        try { return decodeURIComponent(s) } catch (e) { return s }
    }

    // 台面底（独立背景层供玻璃采样）
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

    GlassPanel {
        id: panel
        stageItem: bgLayer
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ===== 标题栏 =====
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 8
                    spacing: 10
                    AppMark { size: 22 }
                    Text {
                        text: qsTr("批量重命名")
                        color: Theme.text
                        font.family: Theme.fontUI
                        font.pixelSize: 15; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: view.sources.length > 0
                        text: view.sources.length + qsTr(" 个来源")
                        color: Theme.textFaint
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.lineSoft }
            }

            // ===== 文件夹行（流式，muted——它们是上下文不是主角）=====
            Item {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.pad
                Layout.rightMargin: Theme.pad
                Layout.topMargin: 8
                implicitHeight: folderFlow.implicitHeight

                Flow {
                    id: folderFlow
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: view.sources
                        Rectangle {
                            id: folderChip
                            required property string modelData
                            required property int index
                            width: chipText.implicitWidth + 40
                            height: 26
                            radius: Theme.radiusXs
                            color: "transparent"
                            border.width: 1; border.color: Theme.line

                            MouseArea {
                                id: chipHover
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                            Text {
                                id: kindTag
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: folderChip.modelData.kind === "file" ? "F" : "D"
                                color: folderChip.modelData.kind === "file" ? Theme.jade : Theme.textFaint
                                font.family: Theme.fontMono
                                font.pixelSize: 9; font.bold: true
                            }
                            Text {
                                id: chipText
                                anchors.left: kindTag.right
                                anchors.leftMargin: 4
                                anchors.right: rmBtn.left
                                anchors.rightMargin: 3
                                anchors.verticalCenter: parent.verticalCenter
                                text: folderChip.modelData.replace(/^.*[\\/]/, "")
                                color: chipHover.containsMouse ? Theme.text : Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                            }
                            Rectangle {
                                id: rmBtn
                                width: 18; height: 18; radius: 9
                                anchors.right: parent.right
                                anchors.rightMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                color: rmMa.containsMouse ? Theme.panelHover : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "×"; font.pixelSize: 11
                                    color: Theme.textFaint
                                }
                                MouseArea {
                                    id: rmMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: view.removeSource(folderChip.index)
                                }
                            }
                            ToolTip.visible: chipHover.containsMouse
                            ToolTip.delay: 400
                            ToolTip.text: folderChip.modelData
                        }
                    }

                    // 添加按钮跟在 chip 行尾：文件夹 / 文件两种来源
                    AppButton {
                        text: qsTr("+ 文件夹")
                        kind: "ghost"
                        implicitHeight: 26
                        onClicked: addFolderDialog.open()
                    }
                    AppButton {
                        text: qsTr("+ 文件")
                        kind: "ghost"
                        implicitHeight: 26
                        onClicked: addFilesDialog.open()
                    }
                }
            }

            // ===== 主区：校对单（左）+ 规则栏（右）—— anchors 显式几何，不依赖 Layout 隐式分配 =====
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Theme.pad
                Layout.rightMargin: Theme.pad
                Layout.topMargin: 4

                // —— 校对单 ——
                Item {
                    id: proofArea
                    anchors.left: parent.left
                    anchors.right: rulesCol.left
                    anchors.rightMargin: Theme.pad
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    // 朱砂批注线：通高贴左缘（签名元素，呼应 Section 眉标与印章身份）
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 1.5
                        color: Theme.seal
                    }

                    ColumnLayout {
                        id: proofSheet
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        spacing: 8

                        // —— 大等宽读数（hero）——
                        RowLayout {
                            id: statRow
                            Layout.fillWidth: true
                            spacing: 18

                            RowLayout {
                                spacing: 7
                                Text {
                                    text: view.changedItems.length
                                    color: view.changedItems.length > 0 ? Theme.jade : Theme.textFaint
                                    font.family: Theme.fontMono
                                    font.pixelSize: 26; font.bold: true
                                }
                                Text {
                                    text: qsTr("将改名")
                                    color: Theme.textDim
                                    font.family: Theme.fontUI
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignBaseline
                                }
                            }
                            RowLayout {
                                spacing: 7
                                visible: view.items.length > view.changedItems.length
                                Text {
                                    text: view.items.length - view.changedItems.length
                                    color: Theme.textFaint
                                    font.family: Theme.fontMono
                                    font.pixelSize: 26; font.bold: true
                                }
                                Text {
                                    text: qsTr("已符合")
                                    color: Theme.textFaint
                                    font.family: Theme.fontUI
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignBaseline
                                }
                            }
                            RowLayout {
                                spacing: 7
                                visible: view.failCount > 0
                                Text {
                                    text: view.failCount
                                    color: Theme.seal
                                    font.family: Theme.fontMono
                                    font.pixelSize: 26; font.bold: true
                                }
                                Text {
                                    text: qsTr("失败")
                                    color: Theme.seal
                                    font.family: Theme.fontUI
                                    font.pixelSize: 11
                                    Layout.alignment: Qt.AlignBaseline
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }

                        // —— 变换清单（只列将改名的；已符合的收在读数里）——
                        Flickable {
                            id: sheet
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: proofCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            ColumnLayout {
                                id: proofCol
                                width: sheet.width
                                // 内容少时也撑满视口，让空态能垂直居中；内容多时按实际高度滚动
                                height: Math.max(sheet.height, proofCol.implicitHeight)
                                spacing: 0

                                // 空态 A：没有文件夹 —— 邀请行动（Item+anchors.centerIn，水平垂直都居中）
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    visible: view.sources.length === 0

                                    Column {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: -54
                                        spacing: 10
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: qsTr("把要整理的文件夹加进来")
                                            color: Theme.textDim
                                            font.family: Theme.fontUI
                                            font.pixelSize: 13
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: qsTr("按规则清掉文件名里的时间戳、括号和副本后缀")
                                            color: Theme.textFaint
                                            font.family: Theme.fontUI
                                            font.pixelSize: 11
                                        }
                                        AppButton {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: qsTr("+ 添加文件夹")
                                            kind: "primary"
                                            implicitHeight: 36
                                            leftPadding: 24; rightPadding: 24
                                            onClicked: addFolderDialog.open()
                                        }
                                    }
                                }

                                // 空态 B：有文件夹但全部已符合 —— 收工状态
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    visible: view.sources.length > 0 && view.items.length === view.changedItems.length

                                    Text {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: -54
                                        text: qsTr("✓ 所有文件的名字都已是整理后的样子")
                                        color: Theme.jade
                                        font.family: Theme.fontUI
                                        font.pixelSize: 13
                                    }
                                }

                                // 空态 C：有文件夹但没有符合条件（如仅 GIF 开着但全是 png）
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    visible: view.sources.length > 0 && view.items.length === 0

                                    Text {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: -54
                                        width: parent.width - 32
                                        text: qsTr("没有符合条件的文件（看看右侧「仅 GIF」是否该关掉）")
                                        color: Theme.textFaint
                                        font.family: Theme.fontUI
                                        font.pixelSize: 11
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                // 变换行：旧名（暗） → 新名（玉绿）
                                Repeater {
                                    model: view.changedItems

                                    ColumnLayout {
                                        id: proofRow
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: 0

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 5
                                            Layout.bottomMargin: 5
                                            spacing: 8
                                            Text {
                                                Layout.fillWidth: true
                                                text: proofRow.modelData.oldName
                                                color: Theme.textFaint
                                                font.family: Theme.fontMono
                                                font.pixelSize: 11
                                                elide: Text.ElideMiddle
                                            }
                                            Text {
                                                text: "→"
                                                color: Theme.textFaint
                                                font.family: Theme.fontMono
                                                font.pixelSize: 11
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: proofRow.modelData.newName
                                                color: proofRow.modelData.error ? Theme.seal : Theme.jade
                                                font.family: Theme.fontMono
                                                font.pixelSize: 11; font.bold: true
                                                elide: Text.ElideMiddle
                                            }
                                        }
                                        // 失败原因（执行后才有）
                                        Text {
                                            visible: proofRow.modelData.error !== undefined && proofRow.modelData.error
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 8
                                            text: proofRow.modelData.error || ""
                                            color: Theme.seal
                                            font.family: Theme.fontUI
                                            font.pixelSize: 10
                                            wrapMode: Text.WordWrap
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 5
                                            height: 1
                                            color: Theme.lineSoft
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // —— 发丝分隔线 ——
                Rectangle {
                    anchors.right: rulesCol.left
                    anchors.rightMargin: Theme.pad
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.lineSoft
                }

                // —— 规则栏（无框，安静的一列）——
                ColumnLayout {
                    id: rulesCol
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 224
                    spacing: 4

                    Flickable {
                        id: ruleList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: ruleCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: ruleCol
                            width: ruleList.width
                            spacing: 2

                            Text {
                                text: qsTr("清理规则")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 10; font.bold: true
                                Layout.bottomMargin: 4
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("时间戳")
                                caption: qsTr("2026-06-26-20-07-33 与 14 位数字")
                                checked: rnSettings.stripTimestamp
                                onToggled: function(v) { rnSettings.stripTimestamp = v; view.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("括号")
                                caption: qsTr("只删括号，保留内容")
                                checked: rnSettings.stripBrackets
                                onToggled: function(v) { rnSettings.stripBrackets = v; view.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("副本后缀")
                                caption: qsTr("段尾「空格+数字」，如「哭 1」")
                                checked: rnSettings.stripCopySuffix
                                onToggled: function(v) { rnSettings.stripCopySuffix = v; view.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("仅 GIF")
                                checked: rnSettings.gifOnly
                                onToggled: function(v) { rnSettings.gifOnly = v; view.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("含子文件夹")
                                checked: rnSettings.recursive
                                onToggled: function(v) { rnSettings.recursive = v; view.repreview() }
                            }

                            Text {
                                text: qsTr("自定义去除")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 10; font.bold: true
                                Layout.topMargin: 12
                                Layout.bottomMargin: 4
                            }
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("正则，匹配即删，预览实时可见：")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: 2
                                spacing: 6
                                Repeater {
                                    // 快捷示例：点击追加为一条自定义规则（hover 有用途说明）
                                    model: [
                                        { re: "-高清版$", tip: qsTr("删除名字结尾的「-高清版」这类标记") },
                                        { re: "\\(.*?\\)", tip: qsTr("连内容一起删除（半角）括号") },
                                        { re: "^\\d+_", tip: qsTr("删除开头「数字_」前缀") },
                                    ]
                                    Rectangle {
                                        id: exChip
                                        required property var modelData
                                        radius: Theme.radiusXs
                                        height: 22
                                        width: exText.implicitWidth + 14
                                        color: exMa.containsMouse ? Theme.panelHover : Theme.panelHi
                                        border.width: 1; border.color: Theme.line
                                        Text {
                                            id: exText
                                            anchors.centerIn: parent
                                            text: exChip.modelData.re
                                            color: Theme.textDim
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                        }
                                        MouseArea {
                                            id: exMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                view.customPatterns.push(exChip.modelData.re)
                                                view.customPatterns = view.customPatterns.slice()
                                                view.savePatterns()
                                                view.repreview()
                                            }
                                        }
                                        ToolTip.visible: exMa.containsMouse
                                        ToolTip.delay: 300
                                        ToolTip.text: exChip.modelData.tip
                                    }
                                }
                            }

                            Repeater {
                                model: view.customPatterns
                                RowLayout {
                                    id: ptnRow
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.topMargin: 6
                                    spacing: 4
                                    TextField {
                                        id: ptnField
                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        text: ptnRow.modelData
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        color: renamer.isPatternValid(ptnField.text) ? Theme.text : Theme.seal
                                        background: Rectangle {
                                            radius: Theme.radiusSm
                                            color: Theme.panelHi
                                            border.width: 1
                                            border.color: renamer.isPatternValid(ptnField.text) ? Theme.line : Theme.seal
                                        }
                                        onTextEdited: {
                                            view.customPatterns[ptnRow.index] = text
                                            view.savePatterns()
                                            view.repreview()
                                        }
                                    }
                                    Rectangle {
                                        width: 24; height: 24; radius: 12
                                        color: ptnMa.containsMouse ? Theme.panelHover : "transparent"
                                        Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 12; color: Theme.textFaint }
                                        MouseArea {
                                            id: ptnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                view.customPatterns.splice(ptnRow.index, 1)
                                                view.customPatterns = view.customPatterns.slice()
                                                view.savePatterns()
                                                view.repreview()
                                            }
                                        }
                                    }
                                }
                            }
                            AppButton {
                                Layout.topMargin: 6
                                text: qsTr("+ 添加规则")
                                kind: "ghost"
                                implicitHeight: 28
                                leftPadding: 14; rightPadding: 14
                                onClicked: {
                                    view.customPatterns.push("")
                                    view.customPatterns = view.customPatterns.slice()
                                }
                            }

                            // —— 文字替换 ——
                            Text {
                                text: qsTr("文字替换")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 10; font.bold: true
                                Layout.topMargin: 14
                                Layout.bottomMargin: 4
                            }
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("字面匹配：文件名里所有出现的「查找」都会被换成「替换为」（留空替换为即删除）。")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                            Repeater {
                                model: view.replaceRules
                                ColumnLayout {
                                    id: rrRow
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    Layout.topMargin: 6
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Text {
                                            text: qsTr("查找")
                                            color: Theme.textFaint
                                            font.family: Theme.fontUI
                                            font.pixelSize: 10
                                        }
                                        TextField {
                                            id: findField
                                            Layout.fillWidth: true
                                            implicitHeight: 28
                                            text: rrRow.modelData.find
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            color: findField.text !== "" ? Theme.text : Theme.seal
                                            background: Rectangle {
                                                radius: Theme.radiusSm
                                                color: Theme.panelHi
                                                border.width: 1
                                                border.color: findField.text !== "" ? Theme.line : Theme.seal
                                            }
                                            onTextEdited: {
                                                view.replaceRules[rrRow.index].find = findField.text
                                                view.saveReplaceRules()
                                                view.repreview()
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Text {
                                            text: qsTr("替换为")
                                            color: Theme.textFaint
                                            font.family: Theme.fontUI
                                            font.pixelSize: 10
                                        }
                                        TextField {
                                            Layout.fillWidth: true
                                            implicitHeight: 28
                                            text: rrRow.modelData.replace
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            color: Theme.text
                                            background: Rectangle {
                                                radius: Theme.radiusSm
                                                color: Theme.panelHi
                                                border.width: 1
                                                border.color: Theme.line
                                            }
                                            onTextEdited: {
                                                view.replaceRules[rrRow.index].replace = text
                                                view.saveReplaceRules()
                                                view.repreview()
                                            }
                                        }
                                        Rectangle {
                                            width: 24; height: 24; radius: 12
                                            color: rrMa.containsMouse ? Theme.panelHover : "transparent"
                                            Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 12; color: Theme.textFaint }
                                            MouseArea {
                                                id: rrMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    view.replaceRules.splice(rrRow.index, 1)
                                                    view.replaceRules = view.replaceRules.slice()
                                                    view.saveReplaceRules()
                                                    view.repreview()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            AppButton {
                                Layout.topMargin: 6
                                text: qsTr("+ 添加替换")
                                kind: "ghost"
                                implicitHeight: 28
                                leftPadding: 14; rightPadding: 14
                                onClicked: {
                                    view.replaceRules.push({ find: "", replace: "" })
                                    view.replaceRules = view.replaceRules.slice()
                                }
                            }
                            Item { Layout.fillHeight: true; Layout.minimumHeight: 8 }
                        }
                    }
                }
            }

            // ===== 底栏 =====
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.lineSoft }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 14
                    spacing: 10
                    Text {
                        text: view.statusText
                        visible: view.statusText !== ""
                        color: view.failCount > 0 ? Theme.seal : Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillWidth: true; visible: view.statusText === "" }
                    AppButton {
                        text: view.changedItems.length > 0
                              ? qsTr("执行重命名 %1").arg(view.changedItems.length)
                              : qsTr("执行重命名")
                        kind: "primary"
                        implicitHeight: 34
                        leftPadding: 18; rightPadding: 18
                        enabled: view.changedItems.length > 0
                        onClicked: view.doApply()
                    }
                }
            }
        }
    }
}
