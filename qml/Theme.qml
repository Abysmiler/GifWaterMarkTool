pragma Singleton
import QtQuick

// 设计令牌单例：「印 · 拷贝台」——背光毛玻璃拷贝台 + 朱砂封印。
// 浅色系；玻璃面板用真实背景模糊（见 GlassPanel.qml）。
QtObject {
    id: t

    // ---- 背光地面（冷调发光白，非暖奶油）----
    readonly property color ink:        "#E8EEF4"   // 窗口兜底
    readonly property color groundTop:  "#F5F9FC"
    readonly property color groundMid:  "#E9F0F6"
    readonly property color groundBot:  "#DCE5EE"

    // ---- 实心浅面（控件填充）----
    readonly property color panel:      "#FFFFFF"
    readonly property color panelHi:    "#EDF2F7"
    readonly property color panelHover: "#E1EAF2"
    readonly property color line:       "#CDD8E2"
    readonly property color lineSoft:   "#E3EAF1"

    // ---- 拷贝台面（极淡棋盘格）----
    readonly property color stageBg:    "#EFF4F9"
    readonly property color stageA:     "#FAFCFE"
    readonly property color stageB:     "#E9EFF5"

    // ---- 文字（深板岩，非纯黑）----
    readonly property color text:       "#1E2A33"
    readonly property color textDim:    "#586974"
    readonly property color textFaint:  "#93A2AD"

    // ---- 朱砂封印（唯一强调色，印泥红 on 宣纸）----
    readonly property color seal:       "#DC4B2E"
    readonly property color sealHi:     "#EC6446"
    readonly property color sealDeep:   "#B8371F"
    readonly property color sealWash:   "#FBEBE6"

    // ---- 玉（画布选框把手）----
    readonly property color jade:       "#1E9B84"

    // ---- 语义 ----
    readonly property color ok:         "#1E9B6B"
    readonly property color okWash:     "#E7F5EE"
    readonly property color warn:       "#DC4B2E"
    readonly property color warnWash:   "#FBEBE6"

    // ---- 玻璃 ----
    readonly property color glassTint:    "#FFFFFF"
    readonly property real  glassTintA:   0.42       // 磨砂白覆盖度
    readonly property color glassBorder:  "#B8FFFFFF" // 高光描边（AARRGGBB）
    readonly property color glassShadow:  "#22314A5E" // 冷灰投影

    // ---- 字族 ----
    readonly property string fontUI:   "Microsoft YaHei UI"
    readonly property string fontMono: "Consolas"

    // ---- 度量 ----
    readonly property int radius:   14
    readonly property int radiusSm: 9
    readonly property int radiusXs: 5
    readonly property int gap:      10
    readonly property int gapLg:    16
    readonly property int pad:      16

    // ---- 动效时长 ----
    readonly property int quick: 110
    readonly property int slide: 240
}
