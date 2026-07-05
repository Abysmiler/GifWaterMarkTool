import QtQuick
import QtQuick.Controls.Basic

// 卡片容器：圆角 + 主题背景 + 边框层次。
// 自包含主题（不引用外部 window id）：用 Application.styleHints 判断亮暗。
// 用 Pane：自动跟随内容尺寸（Rectangle 不会被子项撑开，Pane 会）。
Pane {
    id: root
    readonly property bool lightMode: Application.styleHints.colorScheme === Qt.Light
    padding: 0
    background: Rectangle {
        color: root.lightMode ? "#ffffff" : "#2a2a2c"
        radius: 12
        border.color: root.lightMode ? "#e5e5e8" : "#3a3a3c"
        border.width: 1
    }
}
