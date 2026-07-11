import QtQuick
import QtQuick.Effects
import GifWaterMarkTool

// 毛玻璃面板：采样 stageItem 中本面板下方的区域做实时模糊（真·背景虚化），
// 叠磨砂白 + 顶部高光 + 发丝描边 + 冷灰投影。
// 用法：与 stageItem 同一父级、stageItem 铺满该父级；面板内容写进默认槽。
Item {
    id: gp
    property Item stageItem: null
    property real radius: Theme.radius
    property bool shadow: true
    default property alias content: holder.data

    // 投影（模糊黑角矩形，下移）
    Rectangle {
        id: shadowShape
        anchors.fill: parent
        radius: gp.radius
        color: "#000000"
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        visible: gp.shadow
        anchors.fill: parent
        source: shadowShape
        blurEnabled: true
        blur: 1.0
        blurMax: 32
        opacity: 0.18
        z: -1
        transform: Translate { y: 7 }
    }

    // 圆角遮罩（供模糊层裁剪）
    Rectangle {
        id: rMask
        anchors.fill: parent
        radius: gp.radius
        visible: false
        layer.enabled: true
    }

    // 抓取本面板下方的台面区域
    ShaderEffectSource {
        id: grab
        anchors.fill: parent
        visible: false
        live: true
        recursive: false
        sourceItem: gp.stageItem
        sourceRect: gp.stageItem ? Qt.rect(gp.x, gp.y, gp.width, gp.height) : Qt.rect(0, 0, 1, 1)
        textureSize: Qt.size(Math.max(1, gp.width / 2), Math.max(1, gp.height / 2))
    }

    // 模糊 + 圆角裁剪 + 轻微提亮去饱和 → 磨砂
    MultiEffect {
        anchors.fill: parent
        source: grab
        blurEnabled: true
        blur: 1.0
        blurMax: 40
        blurMultiplier: 1.0
        brightness: 0.07
        saturation: -0.15
        maskEnabled: true
        maskSource: rMask
    }

    // 磨砂白
    Rectangle {
        anchors.fill: parent
        radius: gp.radius
        color: Theme.glassTint
        opacity: Theme.glassTintA
    }
    // 顶部高光斜面
    Rectangle {
        anchors.fill: parent
        radius: gp.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#55FFFFFF" }
            GradientStop { position: 0.4; color: "#00FFFFFF" }
        }
    }
    // 发丝描边
    Rectangle {
        anchors.fill: parent
        radius: gp.radius
        color: "transparent"
        border.width: 1
        border.color: Theme.glassBorder
    }

    Item { id: holder; anchors.fill: parent }
}
