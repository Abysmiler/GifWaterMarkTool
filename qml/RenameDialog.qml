import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Effects
import QtCore
import GifWaterMarkTool

// 批量重命名弹窗 —— 「校对单」：顶部大等宽读数（将改名/已符合），
// 朱砂批注线贯通预览清单，清单只列「旧名 → 新名」的变换本身；
// 右侧无框规则栏靠发丝线分隔。内部开放表面，不套内盒。
Item {
    id: dlg
    anchors.fill: parent
    visible: false
    z: 100

    property var folders: []        // 累加选择的文件夹
    property var items: []          // preview 结果 [{path, dir, oldName, newName, changed, error}]
    property string statusText: ""
    property var customPatterns: [] // 自定义「匹配即删除」正则

    readonly property var changedItems: items.filter(function(it) { return it.changed })
    readonly property int failCount: items.filter(function(it) { return it.error }).length

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

    // 遮罩只拦截点击、不点外关闭：重命名是持续性工作，
    // 关闭走 × / 关闭按钮 / Esc（与导出结果面板同设计）
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
        statusText = fails.length > 0
            ? qsTr("成功 %1 · 失败 %2（失败文件已保持原名）").arg(changedItems.length - fails.length).arg(fails.length)
            : qsTr("已重命名 %1 个文件").arg(changedItems.length)
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
                Layout.preferredHeight: 52
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
                    AppMark { size: 22 }
                    Text {
                        text: qsTr("批量重命名")
                        color: Theme.text
                        font.family: Theme.fontUI
                        font.pixelSize: 15; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: dlg.folders.length > 0
                        text: dlg.folders.length + qsTr(" 个文件夹")
                        color: Theme.textFaint
                        font.family: Theme.fontMono
                        font.pixelSize: 11
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
                        model: dlg.folders
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
                                id: chipText
                                anchors.left: parent.left
                                anchors.leftMargin: 9
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
                                    onClicked: dlg.removeFolder(folderChip.index)
                                }
                            }
                            ToolTip.visible: chipHover.containsMouse
                            ToolTip.delay: 400
                            ToolTip.text: folderChip.modelData
                        }
                    }

                    // 添加按钮跟在 chip 行尾
                    AppButton {
                        text: qsTr("+ 添加文件夹")
                        kind: "ghost"
                        implicitHeight: 26
                        onClicked: addFolderDialog.open()
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
                                    text: dlg.changedItems.length
                                    color: dlg.changedItems.length > 0 ? Theme.jade : Theme.textFaint
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
                                visible: dlg.items.length > dlg.changedItems.length
                                Text {
                                    text: dlg.items.length - dlg.changedItems.length
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
                                visible: dlg.failCount > 0
                                Text {
                                    text: dlg.failCount
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
                                spacing: 0

                                // 空态 A：没有文件夹 —— 邀请行动
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: dlg.folders.length === 0
                                    spacing: 10
                                    Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: qsTr("把要整理的文件夹加进来")
                                        color: Theme.textDim
                                        font.family: Theme.fontUI
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: qsTr("按规则清掉文件名里的时间戳、括号和副本后缀")
                                        color: Theme.textFaint
                                        font.family: Theme.fontUI
                                        font.pixelSize: 11
                                    }
                                    AppButton {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.topMargin: 6
                                        text: qsTr("+ 添加文件夹")
                                        kind: "primary"
                                        implicitHeight: 36
                                        leftPadding: 24; rightPadding: 24
                                        onClicked: addFolderDialog.open()
                                    }
                                    Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
                                }

                                // 空态 B：有文件夹但全部已符合 —— 收工状态
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: dlg.folders.length > 0 && dlg.items.length === dlg.changedItems.length
                                    spacing: 6
                                    Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: qsTr("✓ 所有文件的名字都已是整理后的样子")
                                        color: Theme.jade
                                        font.family: Theme.fontUI
                                        font.pixelSize: 13
                                    }
                                    Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
                                }

                                // 空态 C：有文件夹但没有符合条件（如仅 GIF 开着但全是 png）
                                Text {
                                    visible: dlg.folders.length > 0 && dlg.items.length === 0
                                    Layout.fillWidth: true
                                    text: qsTr("没有符合条件的文件（看看右侧「仅 GIF」是否该关掉）")
                                    color: Theme.textFaint
                                    font.family: Theme.fontUI
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    topPadding: 24
                                }

                                // 变换行：旧名（暗） → 新名（玉绿）
                                Repeater {
                                    model: dlg.changedItems

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
                                onToggled: function(v) { rnSettings.stripTimestamp = v; dlg.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("括号")
                                caption: qsTr("只删括号，保留内容")
                                checked: rnSettings.stripBrackets
                                onToggled: function(v) { rnSettings.stripBrackets = v; dlg.repreview() }
                            }
                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("副本后缀")
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
                                            dlg.customPatterns[ptnRow.index] = text
                                            dlg.savePatterns()
                                            dlg.repreview()
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
                                Layout.topMargin: 6
                                text: qsTr("+ 添加规则")
                                kind: "ghost"
                                implicitHeight: 28
                                leftPadding: 14; rightPadding: 14
                                onClicked: {
                                    dlg.customPatterns.push("")
                                    dlg.customPatterns = dlg.customPatterns.slice()
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
                        text: dlg.statusText
                        visible: dlg.statusText !== ""
                        color: dlg.failCount > 0 ? Theme.seal : Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillWidth: true; visible: dlg.statusText === "" }
                    AppButton {
                        text: dlg.changedItems.length > 0
                              ? qsTr("执行重命名 %1").arg(dlg.changedItems.length)
                              : qsTr("执行重命名")
                        kind: "primary"
                        implicitHeight: 34
                        leftPadding: 18; rightPadding: 18
                        enabled: dlg.changedItems.length > 0
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
