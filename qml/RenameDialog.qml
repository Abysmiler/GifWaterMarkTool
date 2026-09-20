import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import GifWaterMarkTool

// 批量重命名弹窗：多文件夹累加选择 + 规则开关（去时间戳/括号/副本后缀）+ 自定义正则，
// 实时预览「原名 → 新名」，执行时单文件原子改名（失败自动保持原名并提示）。
// 布局：顶部文件夹横排（全宽换行）——右侧规则侧栏——左侧预览主区。
Item {
    id: dlg
    anchors.fill: parent
    visible: false
    z: 100

    property var folders: []        // 累加选择的文件夹
    property var items: []          // preview 结果 [{path, dir, oldName, newName, changed, error}]
    property string statusText: ""
    property var customPatterns: [] // 自定义「匹配即删除」正则

    signal closed()

    function open() {
        panel.x = (dlg.width - panel.width) / 2
        panel.y = (dlg.height - panel.height) / 2
        dlg.visible = true
        repreview()
    }
    function close() { dlg.visible = false; dlg.closed() }
    function _clamp() {
        if (!dlg.visible) return
        panel.x = Math.max(0, Math.min(panel.x, dlg.width - panel.width))
        panel.y = Math.max(0, Math.min(panel.y, dlg.height - panel.height))
    }
    onWidthChanged: _clamp()
    onHeightChanged: _clamp()

    Shortcut { sequences: ["Esc"]; onActivated: dlg.close() }

    // 遮罩只拦截点击、不点外关闭：重命名是持续性工作（调规则/看预览），
    // 误触外部不该丢面板；关闭走 × / 关闭按钮 / Esc（与导出结果面板同设计）
    Item {
        anchors.fill: parent
        MouseArea { anchors.fill: parent }
    }

    function repreview() {
        statusText = ""
        if (folders.length === 0) { items = []; return }
        items = renamer.preview(folders)
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
        var changedCount = items.filter(function(it) { return it.changed }).length
        statusText = fails.length > 0
            ? qsTr("成功 %1 · 失败 %2（失败文件已保持原名）").arg(changedCount - fails.length).arg(fails.length)
            : qsTr("已重命名 %1 个文件").arg(changedCount)
    }

    function removeFolder(i) {
        folders.splice(i, 1)
        folders = folders.slice()
        repreview()
    }

    Renamer {
        id: renamer
        stripTimestamp: rnSettings.stripTimestamp
        stripBrackets: rnSettings.stripBrackets
        stripCopySuffix: rnSettings.stripCopySuffix
        gifOnly: rnSettings.gifOnly
        recursive: rnSettings.recursive
        customPatterns: dlg.customPatterns
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
        property string lastFolder: ""
    }
    Component.onCompleted: {
        try { customPatterns = JSON.parse(rnSettings.customPatternsJson) } catch (e) { customPatterns = [] }
    }

    FolderDialog {
        id: addFolderDialog
        title: qsTr("添加要重命名的文件夹")
        currentFolder: rnSettings.lastFolder !== "" ? "file:///" + rnSettings.lastFolder : ""
        onAccepted: {
            rnSettings.lastFolder = urlToPath(currentFolder)
            var p = urlToPath(selectedFolder)
            if (folders.indexOf(p) === -1) {
                folders.push(p)
                folders = folders.slice()
                repreview()
            }
        }
    }
    function urlToPath(u) {
        var s = u.toString()
        if (s.startsWith("file:///")) s = s.substring(8)
        try { return decodeURIComponent(s) } catch (e) { return s }
    }

    Item {
        id: panel
        width: Math.min(780, parent.width - 48)
        height: Math.min(560, parent.height - 64)
        opacity: dlg.visible ? 1.0 : 0.0
        scale: dlg.visible ? 1.0 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.slide } }
        Behavior on scale { NumberAnimation { duration: Theme.slide; easing.type: Easing.OutCubic } }

        Rectangle {
            id: panelShadow
            anchors.fill: parent
            radius: 16; color: "#000000"
            visible: false; layer.enabled: true
        }
        MultiEffect {
            anchors.fill: parent
            source: panelShadow
            blurEnabled: true; blur: 1.0; blurMax: 32
            opacity: 0.18
            transform: Translate { y: 7 }
        }
        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.panel
            border.width: 1; border.color: Theme.line
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ===== 标题栏（可拖动）=====
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                MouseArea {
                    anchors.fill: parent
                    drag.target: panel
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.maximumX: Math.max(0, dlg.width - panel.width)
                    drag.minimumY: 0
                    drag.maximumY: Math.max(0, dlg.height - panel.height)
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 8
                    spacing: 10
                    AppMark { size: 24 }
                    Text {
                        text: qsTr("批量重命名")
                        color: Theme.text
                        font.family: Theme.fontUI
                        font.pixelSize: 15; font.bold: true
                        Layout.fillWidth: true
                    }
                    AppButton {
                        text: "×"
                        kind: "ghost"
                        implicitHeight: 32
                        onClicked: dlg.close()
                    }
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.lineSoft }
            }

            // ===== 文件夹横排（全宽，自动换行）=====
            Item {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.pad
                Layout.rightMargin: Theme.pad
                Layout.topMargin: 10
                implicitHeight: folderFlow.implicitHeight + addFolderBtn.height + 14

                ColumnLayout {
                    id: folderArea
                    anchors.fill: parent
                    spacing: 8

                    Flow {
                        id: folderFlow
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: dlg.folders
                            Rectangle {
                                id: folderChip
                                required property string modelData
                                required property int index
                                width: chipText.implicitWidth + 44
                                height: 30
                                radius: Theme.radiusSm
                                color: Theme.panelHi
                                border.width: 1; border.color: Theme.line

                                Text {
                                    id: chipText
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.right: rmBtn.left
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: folderChip.modelData.replace(/^.*[\\/]/, "")
                                    color: Theme.text
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                }
                                MouseArea {
                                    id: chipHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                                Rectangle {
                                    id: rmBtn
                                    width: 20; height: 20; radius: 10
                                    anchors.right: parent.right
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: rmMa.containsMouse ? Theme.line : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"; font.pixelSize: 12
                                        color: Theme.textDim
                                    }
                                    MouseArea {
                                        id: rmMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: dlg.removeFolder(folderChip.index)
                                    }
                                }
                                ToolTip.visible: chipHover.containsMouse
                                ToolTip.delay: 400
                                ToolTip.text: folderChip.modelData
                            }
                        }

                        // 添加按钮跟在最后一个 chip 后面
                        AppButton {
                            id: addFolderBtn
                            text: qsTr("+ 添加文件夹")
                            kind: "ghost"
                            implicitHeight: 30
                            onClicked: addFolderDialog.open()
                        }
                    }

                    Text {
                        visible: dlg.folders.length === 0
                        Layout.fillWidth: true
                        text: qsTr("还没有选择文件夹，点击「+ 添加文件夹」开始（可添加多个）")
                        color: Theme.textFaint
                        font.family: Theme.fontUI
                        font.pixelSize: 11
                    }
                }
            }

            // ===== 主区：预览（左大）+ 规则侧栏（右窄）=====
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Theme.pad
                Layout.rightMargin: Theme.pad
                Layout.topMargin: 4
                spacing: Theme.gap

                // —— 预览主区 ——
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSm
                    color: Theme.panelHi
                    border.width: 1; border.color: Theme.lineSoft

                    Flickable {
                        id: previewList
                        anchors.fill: parent
                        anchors.margins: 6
                        contentWidth: width
                        contentHeight: previewCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: previewCol
                            width: previewList.width
                            spacing: 2

                            Text {
                                visible: dlg.folders.length > 0 && dlg.items.length === 0
                                Layout.fillWidth: true
                                text: qsTr("没有符合条件的文件")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                topPadding: 24
                            }

                            Repeater {
                                model: dlg.items

                                ColumnLayout {
                                    id: previewRow
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Text {
                                            Layout.fillWidth: true
                                            text: previewRow.modelData.oldName
                                            color: previewRow.modelData.changed ? Theme.textDim : Theme.textFaint
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            elide: Text.ElideMiddle
                                        }
                                        Text {
                                            text: "→"
                                            visible: previewRow.modelData.changed
                                            color: Theme.textFaint
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            visible: previewRow.modelData.changed
                                            text: previewRow.modelData.newName
                                            color: previewRow.modelData.error ? Theme.seal : Theme.jade
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                    Text {
                                        visible: previewRow.modelData.error !== undefined && previewRow.modelData.error
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 8
                                        text: previewRow.modelData.error || ""
                                        color: Theme.seal
                                        font.family: Theme.fontUI
                                        font.pixelSize: 10
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                }

                // —— 规则侧栏（窄列，可滚动）——
                Rectangle {
                    Layout.preferredWidth: 236
                    Layout.fillHeight: true
                    radius: Theme.radiusSm
                    color: Theme.panelHi
                    border.width: 1; border.color: Theme.lineSoft

                    Flickable {
                        id: ruleList
                        anchors.fill: parent
                        anchors.margins: 8
                        contentWidth: width
                        contentHeight: ruleCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: ruleCol
                            width: ruleList.width
                            spacing: 6

                            Text {
                                text: qsTr("规则")
                                color: Theme.text
                                font.family: Theme.fontUI
                                font.pixelSize: 12; font.bold: true
                            }

                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("去时间戳段")
                                caption: qsTr("2026-06-26-20-07-33 与 14 位纯数字")
                                checked: rnSettings.stripTimestamp
                                onToggled: function(v) { rnSettings.stripTimestamp = v; dlg.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("去括号")
                                caption: qsTr("只删括号本身，保留内容")
                                checked: rnSettings.stripBrackets
                                onToggled: function(v) { rnSettings.stripBrackets = v; dlg.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("去副本后缀")
                                caption: qsTr("段尾「空格+数字」，如「哭 1」")
                                checked: rnSettings.stripCopySuffix
                                onToggled: function(v) { rnSettings.stripCopySuffix = v; dlg.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("仅 GIF")
                                checked: rnSettings.gifOnly
                                onToggled: function(v) { rnSettings.gifOnly = v; dlg.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("含子文件夹")
                                checked: rnSettings.recursive
                                onToggled: function(v) { rnSettings.recursive = v; dlg.repreview() }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.lineSoft }

                            Text {
                                text: qsTr("自定义去除规则")
                                color: Theme.text
                                font.family: Theme.fontUI
                                font.pixelSize: 12; font.bold: true
                            }
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("正则表达式，文件名（不含扩展名）中匹配到的部分会被删除，预览实时可见。点击示例填入：")
                                color: Theme.textFaint
                                font.family: Theme.fontUI
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                            }
                            Flow {
                                Layout.fillWidth: true
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
                                        height: 24
                                        width: exText.implicitWidth + 16
                                        color: exMa.containsMouse ? Theme.panelHover : Theme.panel
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
                                                dlg.customPatterns.push(exChip.modelData.re)
                                                dlg.customPatterns = dlg.customPatterns.slice()
                                                dlg.savePatterns()
                                                dlg.repreview()
                                            }
                                        }
                                        ToolTip.visible: exMa.containsMouse
                                        ToolTip.delay: 300
                                        ToolTip.text: exChip.modelData.tip
                                    }
                                }
                            }

                            Repeater {
                                model: dlg.customPatterns
                                RowLayout {
                                    id: ptnRow
                                    required property string modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: 6
                                    TextField {
                                        id: ptnField
                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        text: ptnRow.modelData
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        color: renamer.isPatternValid(text) ? Theme.text : Theme.seal
                                        background: Rectangle {
                                            radius: Theme.radiusSm
                                            color: Theme.panel
                                            border.width: 1
                                            border.color: renamer.isPatternValid(ptnField.text) ? Theme.line : Theme.seal
                                        }
                                        onTextEdited: {
                                            dlg.customPatterns[ptnRow.index] = text
                                            dlg.savePatterns()
                                            dlg.repreview()
                                        }
                                    }
                                    Rectangle {
                                        width: 26; height: 26; radius: 13
                                        color: ptnMa.containsMouse ? Theme.line : "transparent"
                                        Text { anchors.centerIn: parent; text: "×"; font.pixelSize: 13; color: Theme.textDim }
                                        MouseArea {
                                            id: ptnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                dlg.customPatterns.splice(ptnRow.index, 1)
                                                dlg.customPatterns = dlg.customPatterns.slice()
                                                dlg.savePatterns()
                                                dlg.repreview()
                                            }
                                        }
                                    }
                                }
                            }
                            AppButton {
                                text: qsTr("+ 添加规则")
                                kind: "ghost"
                                implicitHeight: 28
                                leftPadding: 14; rightPadding: 14
                                onClicked: {
                                    dlg.customPatterns.push("")
                                    dlg.customPatterns = dlg.customPatterns.slice()
                                }
                            }
                            Item { Layout.fillHeight: true; Layout.minimumHeight: 4 }
                        }
                    }
                }
            }

            // ===== 底栏 =====
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.lineSoft }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 14
                    spacing: 10
                    Text {
                        text: dlg.statusText !== ""
                              ? dlg.statusText
                              : qsTr("%1 个文件 · 将改名 %2 个")
                                .arg(dlg.items.length)
                                .arg(dlg.items.filter(function(it) { return it.changed }).length)
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    AppButton {
                        text: qsTr("执行重命名")
                        kind: "primary"
                        implicitHeight: 34
                        leftPadding: 18; rightPadding: 18
                        enabled: dlg.items.some(function(it) { return it.changed })
                        onClicked: dlg.doApply()
                    }
                    AppButton {
                        text: qsTr("关闭")
                        kind: "ghost"
                        implicitHeight: 34
                        leftPadding: 18; rightPadding: 18
                        onClicked: dlg.close()
                    }
                }
            }
        }
    }
}
