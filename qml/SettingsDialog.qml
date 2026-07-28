import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Effects
import GifWaterMarkTool

// 设置弹窗：浮于应用之上的纯色面板，可按标题栏拖动；不压暗主界面。
// 三项真实偏好（记忆上次水印 / 默认深度压缩 / 记忆导出文件夹）+ 关于。
Item {
    id: dlg
    anchors.fill: parent
    visible: false
    z: 100

    property string appVersion: "v1.0.1"
    property bool rememberWatermark: false
    property bool deepCompress: true
    property bool rememberOutFolder: true

    signal closed()
    signal rememberWatermarkToggled(bool v)
    signal deepCompressToggled(bool v)
    signal rememberOutFolderToggled(bool v)

    function open() {
        panel.x = (dlg.width - panel.width) / 2
        panel.y = (dlg.height - panel.height) / 2
        dlg.visible = true
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

    // 透明遮罩：不压暗主界面，仅拦截背后点击 + 点外关闭
    Item {
        anchors.fill: parent
        MouseArea { anchors.fill: parent; onClicked: dlg.close() }
    }

    // 纯色面板（可拖动；位置由 open() / 拖拽设置；不再用毛玻璃）
    Item {
        id: panel
        width: Math.min(520, parent.width - 48)
        height: Math.min(470, parent.height - 64)
        opacity: dlg.visible ? 1.0 : 0.0
        scale: dlg.visible ? 1.0 : 0.97
        Behavior on opacity { NumberAnimation { duration: Theme.slide } }
        Behavior on scale { NumberAnimation { duration: Theme.slide; easing.type: Easing.OutCubic } }

        // 投影
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
        // 纯色底
        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.panel
            border.width: 1; border.color: Theme.line
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ===== 标题栏（可拖动整窗）=====
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                MouseArea {
                    id: headerDrag
                    anchors.fill: parent
                    drag.target: panel
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.maximumX: Math.max(0, dlg.width - panel.width)
                    drag.minimumY: 0
                    drag.maximumY: Math.max(0, dlg.height - panel.height)
                    // 用默认箭头光标；按住拖动即可移动窗口
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 8
                    spacing: 10
                    AppMark { size: 24 }
                    Text {
                        text: qsTr("设置")
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

            // ===== 正文（Flickable，参照 Inspector：显式 contentHeight/width，避免 ScrollView 把内容压成 0）=====
            Flickable {
                id: bodyFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: bodyCol.implicitHeight + 2 * Theme.pad
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: bodyCol
                    y: Theme.pad
                    width: bodyFlick.width
                    spacing: Theme.gap

                    // ---------- 水印 ----------
                    Section {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.pad
                        Layout.rightMargin: Theme.pad
                        Layout.topMargin: 4
                        title: qsTr("水印")
                        subtitle: "WATERMARK"

                        SwitchRow {
                            Layout.fillWidth: true
                            text: qsTr("记住上次的水印")
                            caption: qsTr("下次启动自动载入上次的水印图片与位置")
                            checked: dlg.rememberWatermark
                            onToggled: function(v) { dlg.rememberWatermarkToggled(v) }
                        }
                    }

                    // ---------- 导出 ----------
                    Section {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.pad
                        Layout.rightMargin: Theme.pad
                        title: qsTr("导出")
                        subtitle: "EXPORT"

                        SwitchRow {
                            Layout.fillWidth: true
                            text: qsTr("默认启用深度压缩")
                            caption: qsTr("导出时默认开启 gifsicle 深度优化")
                            checked: dlg.deepCompress
                            onToggled: function(v) { dlg.deepCompressToggled(v) }
                        }
                        SwitchRow {
                            Layout.fillWidth: true
                            text: qsTr("记住上次导出文件夹")
                            caption: qsTr("下次导出默认存到上次用的文件夹")
                            checked: dlg.rememberOutFolder
                            onToggled: function(v) { dlg.rememberOutFolderToggled(v) }
                        }
                    }

                    // ---------- 关于 ----------
                    Section {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.pad
                        Layout.rightMargin: Theme.pad
                        Layout.bottomMargin: Theme.pad
                        collapsible: false
                        title: qsTr("关于")
                        subtitle: "ABOUT"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                text: qsTr("版本")
                                color: Theme.textDim
                                font.family: Theme.fontUI
                                font.pixelSize: 12
                            }
                            Text {
                                text: dlg.appVersion
                                color: Theme.text
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                            }
                            Item { Layout.fillWidth: true }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                text: qsTr("项目主页")
                                color: Theme.textDim
                                font.family: Theme.fontUI
                                font.pixelSize: 12
                            }
                            Text {
                                text: "github.com/Abysmiler/GifWaterMarkTool"
                                color: Theme.seal
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                            }
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
                    anchors.rightMargin: 14
                    Item { Layout.fillWidth: true }
                    AppButton {
                        text: qsTr("完成")
                        kind: "primary"
                        implicitHeight: 34
                        leftPadding: 22; rightPadding: 22
                        onClicked: dlg.close()
                    }
                }
            }
        }
    }
}
