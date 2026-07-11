import QtQuick
import QtQuick.Effects
import GifWaterMarkTool

// 合成台：棋盘格台面 + GIF 居中适配 + 水印直接操作（拖动/缩放把手/旋转把手）。
// 坐标契约保持不变：gifCenterX/Y 为原图像素，供导出用。
// WYSIWYG 修正：文字水印在预览中不套用 wmScale/wmRotate（与 drawtext 导出一致）。
Item {
    id: root

    // ---- 输入 ----
    property string gifSource: ""
    property string previewSource: ""
    property string waterSource: ""
    property real wmScale: 1.0
    property real wmOpacity: 1.0
    property real wmRotate: 0.0
    property bool useTextWater: false
    property string textContent: ""
    property int textFontSize: 24
    property string textColor: "#ffffff"

    // ---- 预览台底色 ----
    property color canvasColor: "#5E6A74"   // 有 GIF 时的纯色底
    property bool canvasChecker: false      // true=透明棋盘格

    signal wmScaleAdjusted(real newScale)
    signal wmRotateAdjusted(real newRotate)
    signal textFontSizeAdjusted(int newSize)
    signal previewReady()

    // ---- GIF 原始尺寸 ----
    property real gifOrigW: 0
    property real gifOrigH: 0

    // ---- 可用区内边距（避开浮动玻璃面板）----
    property real leftInset: 0
    property real topInset: 0
    property real rightInset: 0
    property real bottomInset: 0

    // ---- 预览框（固定 4:3，居中于可用区）----
    readonly property real _availX: leftInset
    readonly property real _availY: topInset
    readonly property real _availW: Math.max(1, root.width - leftInset - rightInset)
    readonly property real _availH: Math.max(1, root.height - topInset - bottomInset)
    readonly property real _boxW: Math.min(_availW * 0.84, _availH * 0.84 * 4 / 3)
    readonly property real _boxH: _boxW * 3 / 4
    readonly property real _boxX: _availX + (_availW - _boxW) / 2
    readonly property real _boxY: _availY + (_availH - _boxH) / 2

    // ---- GIF 在框内布局 ----
    property real _fitScale: 1.0
    property real _gifDispW: 0
    property real _gifDispH: 0
    readonly property real _gifDispX: (_boxW - _gifDispW) / 2
    readonly property real _gifDispY: (_boxH - _gifDispH) / 2

    // ---- 水印中心（相对预览框）----
    property real wmCx: _boxW / 2
    property real wmCy: _boxH / 2

    // ---- GIF 像素坐标（导出用）----
    property real gifCenterX: 0
    property real gifCenterY: 0

    // ---- 水印显示态 ----
    readonly property bool hasImg: waterSource !== "" && !useTextWater && wm.status === Image.Ready
    readonly property bool hasText: useTextWater && textContent !== ""
    readonly property bool hasWm: hasImg || hasText
    readonly property real _wmW: hasImg ? wm.width : (hasText ? textWm.width : 0)
    readonly property real _wmH: hasImg ? wm.height : (hasText ? textWm.height : 0)
    readonly property real _selRot: hasImg ? wmRotate : 0
    readonly property real _cx: _boxX + wmCx
    readonly property real _cy: _boxY + wmCy

    function updateCenterCoords() {
        if (gifOrigW > 0 && _gifDispW > 0) {
            gifCenterX = (wmCx - _gifDispX) / _fitScale
            gifCenterY = (wmCy - _gifDispY) / _fitScale
        }
    }
    onWmCxChanged: updateCenterCoords()
    onWmCyChanged: updateCenterCoords()

    onWidthChanged: {
        if (gifOrigW > 0 && _gifDispW > 0) { wmCx = gifCenterX * _fitScale + _gifDispX; updateCenterCoords() }
    }
    onHeightChanged: {
        if (gifOrigH > 0 && _gifDispH > 0) { wmCy = gifCenterY * _fitScale + _gifDispY; updateCenterCoords() }
    }

    function relayout() {
        if (gifOrigW <= 0 || gifOrigH <= 0 || _boxW <= 0 || _boxH <= 0) return
        _fitScale = Math.min(_boxW / gifOrigW, _boxH / gifOrigH)
        _gifDispW = gifOrigW * _fitScale
        _gifDispH = gifOrigH * _fitScale
        wmCx = _gifDispX + _gifDispW / 2
        wmCy = _gifDispY + _gifDispH / 2
        updateCenterCoords()
        previewReady()
    }
    function setGifPosition(gx, gy) {
        if (gifOrigW <= 0 || gifOrigH <= 0) return
        wmCx = _gifDispX + (gx / gifOrigW) * _gifDispW
        wmCy = _gifDispY + (gy / gifOrigH) * _gifDispH
        updateCenterCoords()
    }
    function restorePosition(xRatio, yRatio) {
        if (gifOrigW <= 0 || gifOrigH <= 0) return
        wmCx = _gifDispX + xRatio * _gifDispW
        wmCy = _gifDispY + yRatio * _gifDispH
        updateCenterCoords()
    }
    onPreviewSourceChanged: {
        gifOrigW = 0; gifOrigH = 0; _gifDispW = 0; _gifDispH = 0
        _fitScale = 1.0; gifCenterX = 0; gifCenterY = 0
    }

    // ---- 台面底（透明，露出 Main 的发光地面）----
    Rectangle { anchors.fill: parent; color: "transparent" }

    // ---- 预览框柔和投影（拷贝台悬浮感）----
    Rectangle {
        id: boxShadowShape
        x: previewBox.x; y: previewBox.y
        width: previewBox.width; height: previewBox.height
        radius: previewBox.radius
        color: "#000000"; visible: false; layer.enabled: true
    }
    MultiEffect {
        x: previewBox.x; y: previewBox.y
        width: previewBox.width; height: previewBox.height
        source: boxShadowShape
        blurEnabled: true; blur: 1.0; blurMax: 44
        opacity: 0.13
        transform: Translate { y: 12 }
    }

    // ---- 固定预览框（拷贝台：底色卡片 + 柔和投影）----
    Rectangle {
        id: previewBox
        x: root._boxX; y: root._boxY
        width: root._boxW; height: root._boxH
        // 无 GIF：浅磨砂便于读空态；有 GIF：用户选的纯色底（棋盘时用浅底）
        color: root.previewSource === "" ? Theme.stageA
             : root.canvasChecker ? Theme.stageA
             : root.canvasColor
        radius: Theme.radius
        clip: true
        border.width: 1
        border.color: root.previewSource !== "" ? Theme.line : Qt.rgba(0.55, 0.63, 0.72, 0.5)
        Behavior on color { ColorAnimation { duration: Theme.quick } }

        // 透明棋盘格（仅在选择棋盘模式时显示）
        Canvas {
            id: checker
            anchors.fill: parent
            visible: root.previewSource !== "" && root.canvasChecker
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext('2d')
                var s = 14
                ctx.fillStyle = Theme.stageA
                ctx.fillRect(0, 0, width, height)
                ctx.fillStyle = Theme.stageB
                for (var y = 0; y < height; y += s)
                    for (var x = 0; x < width; x += s)
                        if (((x / s | 0) + (y / s | 0)) % 2 === 0)
                            ctx.fillRect(x, y, s, s)
            }
        }

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

        // 动画层
        AnimatedImage {
            id: gifAnim
            source: root.gifSource
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            playing: true
            visible: status === AnimatedImage.Ready && sourceSize.width > 0
        }
    }

    // ---- 空态：拖入邀请 ----
    Column {
        anchors.centerIn: previewBox
        visible: root.previewSource === ""
        spacing: 14
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "印"
            font.family: Theme.fontUI
            font.pixelSize: 46
            font.bold: true
            color: Theme.textFaint
            opacity: 0.5
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("把 GIF 拖到这里")
            font.family: Theme.fontUI
            font.pixelSize: 15
            color: Theme.textDim
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("也可以点上方的「GIF 文件」选择")
            font.family: Theme.fontUI
            font.pixelSize: 12
            color: Theme.textFaint
        }
    }
    // 加载中
    Text {
        anchors.centerIn: previewBox
        visible: root.previewSource !== "" && !gifImg.visible && !gifAnim.visible
        text: qsTr("正在加载预览…")
        font.family: Theme.fontUI
        color: Theme.textDim; font.pixelSize: 14
    }

    // ---- 图像水印 ----
    Image {
        id: wm
        source: root.waterSource
        width: sourceSize.width * root._fitScale * root.wmScale
        height: sourceSize.height * root._fitScale * root.wmScale
        x: root._cx - width / 2
        y: root._cy - height / 2
        opacity: root.wmOpacity
        rotation: root.wmRotate
        fillMode: Image.PreserveAspectFit
        visible: root.hasImg
    }

    // ---- 文字水印（不套 wmScale/wmRotate，与导出一致）----
    Text {
        id: textWm
        text: root.textContent
        font.pixelSize: Math.max(1, root.textFontSize * root._fitScale)
        font.family: Theme.fontUI
        color: root.textColor
        opacity: root.wmOpacity
        x: root._cx - width / 2
        y: root._cy - height / 2
        visible: root.hasText
    }

    // ---- 拖动本体 + 滚轮缩放 ----
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        property bool dragging: false
        property real lastX; property real lastY
        function hitWm(mx, my) {
            if (!root.hasWm) return false
            // 用未旋转的包围盒近似命中（够用）
            var hw = root._wmW / 2, hh = root._wmH / 2
            return mx >= root._cx - hw && mx <= root._cx + hw &&
                   my >= root._cy - hh && my <= root._cy + hh
        }
        cursorShape: (root.hasWm && hitWm(mouseX, mouseY)) ? Qt.SizeAllCursor : Qt.ArrowCursor
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
                const d = wheel.angleDelta.y / 120
                if (root.hasImg)
                    root.wmScaleAdjusted(Math.max(0.05, Math.min(10, root.wmScale + d * 0.08)))
                else if (root.hasText)
                    root.textFontSizeAdjusted(Math.max(8, Math.min(200, root.textFontSize + d * 2)))
            }
        }
    }

    // ---- 选框 + 把手 ----
    Item {
        id: sel
        visible: root.hasWm
        x: root._cx - root._wmW / 2
        y: root._cy - root._wmH / 2
        width: root._wmW
        height: root._wmH
        transformOrigin: Item.Center
        rotation: root._selRot
        z: 20

        // 玉色虚框
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Theme.jade
            radius: 2
            opacity: 0.9
        }

        // 角把手：缩放（图像）/ 改字号（文字），按比例
        Repeater {
            model: [Qt.point(0,0), Qt.point(1,0), Qt.point(0,1), Qt.point(1,1)]
            delegate: Rectangle {
                required property var modelData
                width: 12; height: 12; radius: 3
                color: "#EDF1F2"
                border.width: 1.5; border.color: Theme.jade
                x: modelData.x * sel.width - width / 2
                y: modelData.y * sel.height - height / 2
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.SizeFDiagCursor
                    property real startDist: 0
                    property real startVal: 0
                    onPressed: function(mouse) {
                        var p = mapToItem(root, mouse.x, mouse.y)
                        startDist = Math.hypot(p.x - root._cx, p.y - root._cy)
                        startVal = root.hasImg ? root.wmScale : root.textFontSize
                    }
                    onPositionChanged: function(mouse) {
                        if (startDist <= 0) return
                        var p = mapToItem(root, mouse.x, mouse.y)
                        var d = Math.hypot(p.x - root._cx, p.y - root._cy)
                        var ratio = d / startDist
                        if (root.hasImg)
                            root.wmScaleAdjusted(Math.max(0.05, Math.min(10, startVal * ratio)))
                        else
                            root.textFontSizeAdjusted(Math.max(8, Math.min(200, Math.round(startVal * ratio))))
                    }
                }
            }
        }

        // 旋转把手（仅图像水印）
        Rectangle {
            visible: root.hasImg
            width: 12; height: 12; radius: 6
            color: Theme.seal
            border.width: 1.5; border.color: "#EDF1F2"
            x: sel.width / 2 - width / 2
            y: -26
            Rectangle {  // 连杆
                width: 1; height: 26 - 6
                color: Theme.jade
                x: parent.width / 2
                y: parent.height
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.CrossCursor
                onPositionChanged: function(mouse) {
                    var p = mapToItem(root, mouse.x, mouse.y)
                    var ang = Math.atan2(p.y - root._cy, p.x - root._cx) * 180 / Math.PI
                    root.wmRotateAdjusted(ang + 90)
                }
            }
        }
    }
}
