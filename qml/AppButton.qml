import QtQuick
import QtQuick.Controls.Basic
import GifWaterMarkTool

// 通用按钮。kind: "primary"(朱砂实心) | "ghost"(描边) | "soft"(浅底)
Button {
    id: ctl
    property string kind: "soft"
    property color accent: Theme.seal
    property string glyph: ""          // 可选前置符号

    font.family: Theme.fontUI
    font.pixelSize: 13
    font.bold: kind === "primary"
    implicitHeight: 34
    leftPadding: 15; rightPadding: 15
    hoverEnabled: true

    contentItem: Row {
        spacing: 7
        Text {
            visible: ctl.glyph !== ""
            text: ctl.glyph
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
            color: ctl.kind === "primary" ? (ctl.enabled ? "#ffffff" : Theme.textFaint)
                 : (ctl.enabled ? Theme.text : Theme.textFaint)
        }
        Text {
            text: ctl.text
            font: ctl.font
            anchors.verticalCenter: parent.verticalCenter
            color: ctl.kind === "primary" ? (ctl.enabled ? "#ffffff" : Theme.textFaint)
                 : (ctl.enabled ? Theme.text : Theme.textFaint)
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        radius: Theme.radiusSm
        border.width: ctl.kind === "ghost" ? 1 : 0
        border.color: ctl.down ? Theme.line : Theme.line
        color: {
            if (ctl.kind === "primary")
                return !ctl.enabled ? Theme.panelHi
                     : ctl.down     ? Theme.sealDeep
                     : ctl.hovered  ? Theme.sealHi
                                    : ctl.accent
            if (ctl.kind === "ghost")
                return ctl.down    ? Theme.panelHi
                     : ctl.hovered ? Theme.panelHover
                                   : Qt.rgba(Theme.panelHover.r, Theme.panelHover.g, Theme.panelHover.b, 0)
            // soft
            return ctl.down    ? Theme.panel
                 : ctl.hovered ? Theme.panelHover
                               : Theme.panelHi
        }
        Behavior on color { ColorAnimation { duration: Theme.quick } }
    }
}
