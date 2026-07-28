import QtQuick
import GifWaterMarkTool

// 应用图标（矢量版）：朱砂圆角底 + 两枚半透明白色方块对角叠加，重叠处更亮。
// 与 resources/appicon.png 一致，供界面内各处复用（字标、空态、盖章、Toast）。
Item {
    id: mark
    property real size: 32
    property real radiusRatio: 0.22
    width: size
    height: size

    // 朱砂圆角底
    Rectangle {
        anchors.fill: parent
        radius: mark.size * mark.radiusRatio
        color: Theme.seal
    }

    // 两枚半透明白块，对角错位；重叠区域经 alpha 叠加自然更亮
    Repeater {
        model: [0.18, 0.40]
        delegate: Rectangle {
            required property real modelData
            width: mark.size * 0.42
            height: width
            radius: width * 0.26
            x: mark.size * modelData
            y: mark.size * modelData
            color: "#ffffff"
            opacity: 0.5
        }
    }
}
