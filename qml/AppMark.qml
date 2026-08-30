import QtQuick
import GifWaterMarkTool

// 应用图标（矢量版）：朱砂圆角底 + 白描边「帧」+ 右下一枚实心小章，
// 点题「给 GIF 帧盖水印」。与 resources/appicon.png 同构，供界面内各处复用。
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

    // 帧：白描边圆角框
    Rectangle {
        x: mark.size * 0.266
        y: mark.size * 0.266
        width: mark.size * 0.469
        height: width
        radius: width * 0.233
        color: "transparent"
        border.width: Math.max(1, mark.size * 0.039)
        border.color: "#ffffff"
    }

    // 印：右下实心小章（水印意象）
    Rectangle {
        x: mark.size * 0.594
        y: mark.size * 0.594
        width: mark.size * 0.1875
        height: width
        radius: width * 0.25
        color: "#ffffff"
    }
}
