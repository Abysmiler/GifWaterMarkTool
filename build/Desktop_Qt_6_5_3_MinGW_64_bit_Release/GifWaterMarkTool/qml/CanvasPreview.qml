import QtQuick
import QtQuick.Controls.Fusion

// 预览画布：固定大小的预览框（初始化即占位），GIF 在框内缩放适配。
// ffmpeg 同步抽第一帧 PNG → Image.sourceSize 获取尺寸。
// 水印坐标基于预览框内 GIF 显示位置映射到原始像素。
Item {
    id: root

    // ---- 输入 ----
    property string gifSource: ""       // 原始 GIF URL → AnimatedImage
    property string previewSource: ""   // ffmpeg 抽帧 PNG URL → 尺寸来源
    property string waterSource: ""
    property real wmScale: 1.0
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property bool useTextWater: false
    property string textContent: ""
    property int textFontSize: 24
    property string textColor: "#ffffff"

    signal wmScaleAdjusted(real newScale)
    signal previewReady()  // GIF 加载 + 布局完成后通知 Main

    // ---- GIF 原始尺寸 ----
    property real gifOrigW: 0
    property real gifOrigH: 0

    // ---- 预览框（固定尺寸，始终不变）----
    readonly property real _boxW: Math.min(root.width * 0.65, root.height * 0.65 * 4 / 3)
    readonly property real _boxH: _boxW * 3 / 4
    readonly property real _boxX: (root.width - _boxW) / 2
    readonly property real _boxY: (root.height - _boxH) / 2

    // ---- GIF 在框内的显示布局 ----
    property real _fitScale: 1.0
    property real _gifDispW: 0
    property real _gifDispH: 0
    readonly property real _gifDispX: (_boxW - _gifDispW) / 2   // 框内 letterbox 偏移
    readonly property real _gifDispY: (_boxH - _gifDispH) / 2

    // ---- 水印中心（相对预览框左上角的像素坐标）----
    property real wmCx: _boxW / 2
    property real wmCy: _boxH / 2

    // ---- GIF 像素坐标（供导出用）----
    property real gifCenterX: 0
    property real gifCenterY: 0

    function updateCenterCoords() {
        if (gifOrigW > 0 && _gifDispW > 0) {
            gifCenterX = (wmCx - _gifDispX) / _fitScale
            gifCenterY = (wmCy - _gifDispY) / _fitScale
        }
    }

    onWmCxChanged: updateCenterCoords()
    onWmCyChanged: updateCenterCoords()

    // 窗口大小变化时，保持水印相对 GIF 的位置不变
    onWidthChanged: {
        if (gifOrigW > 0 && _gifDispW > 0) {
            wmCx = gifCenterX * _fitScale + _gifDispX
            updateCenterCoords()
        }
    }
    onHeightChanged: {
        if (gifOrigH > 0 && _gifDispH > 0) {
            wmCy = gifCenterY * _fitScale + _gifDispY
            updateCenterCoords()
        }
    }

    function relayout() {
        if (gifOrigW <= 0 || gifOrigH <= 0 || _boxW <= 0 || _boxH <= 0) return
        _fitScale = Math.min(_boxW / gifOrigW, _boxH / gifOrigH)
        _gifDispW = gifOrigW * _fitScale
        _gifDispH = gifOrigH * _fitScale
        // 初始水印放在 GIF 显示区中心
        wmCx = _gifDispX + _gifDispW / 2
        wmCy = _gifDispY + _gifDispH / 2
        updateCenterCoords()
        previewReady()
    }

    // Main 调用：手动设置水印在 GIF 上的像素位置
    function setGifPosition(gx, gy) {
        if (gifOrigW <= 0 || gifOrigH <= 0) return
        wmCx = _gifDispX + (gx / gifOrigW) * _gifDispW
        wmCy = _gifDispY + (gy / gifOrigH) * _gifDispH
        updateCenterCoords()
    }

    // Main 调用来恢复上次记忆的水印位置（xRatio, yRatio 为 0~1 的 GIF 像素比例）
    function restorePosition(xRatio, yRatio) {
        if (gifOrigW <= 0 || gifOrigH <= 0) return
        wmCx = _gifDispX + xRatio * _gifDispW
        wmCy = _gifDispY + yRatio * _gifDispH
        updateCenterCoords()
    }

    onPreviewSourceChanged: {
        gifOrigW = 0; gifOrigH = 0
        _gifDispW = 0; _gifDispH = 0
        _fitScale = 1.0
        gifCenterX = 0; gifCenterY = 0
    }

    // ---- 背景 ----
    Rectangle { anchors.fill: parent; radius: 8; color: "#1e1e24" }
    Text {
        anchors.top: parent.top; anchors.left: parent.left
        anchors.margins: 10; z: 10
        text: qsTr("预览"); color: "#7a7a82"; font.pixelSize: 12
    }

    // ---- 固定预览框 ----
    Rectangle {
        id: previewBox
        x: root._boxX; y: root._boxY
        width: root._boxW; height: root._boxH
        color: "#15151a"; radius: 6
        border.width: root.previewSource !== "" ? 0 : 2
        border.color: root.previewSource !== "" ? "transparent" : "#50505a"
        clip: true

        // 第一帧底图（坐标系来源）
        Image {
            id: gifImg
            source: root.previewSource
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready && !gifAnim.visible
            onStatusChanged: {
                if (status === Image.Ready && sourceSize.width > 0 && root.gifOrigW === 0) {
                    root.gifOrigW = sourceSize.width
                    root.gifOrigH = sourceSize.height
                    root.relayout()
                }
            }
        }

        // GIF 动画层（纯视觉）
        AnimatedImage {
            id: gifAnim
            source: root.gifSource
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            playing: true
            visible: status === AnimatedImage.Ready && sourceSize.width > 0
        }

        // 占位提示
        Text {
            anchors.centerIn: parent
            visible: !gifImg.visible && !gifAnim.visible
            text: root.previewSource === "" ? qsTr("选择 GIF 后在此预览")
                                            : qsTr("加载中...")
            color: "#5a5a62"; font.pixelSize: 14
        }
    }

    // ---- 水印 PNG ----
    Image {
        id: wm
        source: root.waterSource
        width: sourceSize.width * root._fitScale * root.wmScale
        height: sourceSize.height * root._fitScale * root.wmScale
        x: root._boxX + root.wmCx - width / 2
        y: root._boxY + root.wmCy - height / 2
        opacity: root.wmOpacity; rotation: root.wmRotate
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready && root.waterSource !== "" && !root.useTextWater
    }

    // ---- 文字水印 ----
    Label {
        id: textWm
        text: root.textContent
        font.pixelSize: root.textFontSize * root._fitScale
        color: root.textColor
        opacity: root.wmOpacity
        rotation: root.wmRotate
        x: root._boxX + root.wmCx - width / 2
        y: root._boxY + root.wmCy - height / 2
        visible: root.useTextWater && root.textContent !== ""
    }

    // ---- 拖拽 + 滚轮缩放 ----
    MouseArea {
        anchors.fill: parent; hoverEnabled: true
        property bool dragging: false
        property real lastX; property real lastY
        function hitWm(mx, my) {
            if (wm.visible && mx >= wm.x && mx <= wm.x + wm.width &&
                my >= wm.y && my <= wm.y + wm.height) return true
            if (textWm.visible && mx >= textWm.x && mx <= textWm.x + textWm.width &&
                my >= textWm.y && my <= textWm.y + textWm.height) return true
            return false
        }

        onPressed: function(mouse) {
            if (hitWm(mouse.x, mouse.y)) { dragging = true; lastX = mouse.x; lastY = mouse.y }
        }
        onPositionChanged: function(mouse) {
            if (dragging) {
                root.wmCx += (mouse.x - lastX)
                root.wmCy += (mouse.y - lastY)
                lastX = mouse.x; lastY = mouse.y
            }
        }
        onReleased: dragging = false
        onWheel: function(wheel) {
            if (hitWm(wheel.x, wheel.y)) {
                const d = wheel.angleDelta.y / 120 * 0.1
                root.wmScaleAdjusted(Math.max(0.05, Math.min(10, root.wmScale + d)))
            }
        }
    }
}
