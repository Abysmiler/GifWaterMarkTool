#pragma once

#include <QSize>
#include <QString>

// GIF 元信息探测（用于进度百分比计算）。
namespace gifprobe {

// 探测 GIF 总时长（毫秒）。失败/无法解析时返回 -1（调用方应降级为帧数进度）。
qint64 durationMs(const QString &gifPath);

// 直接读 GIF 文件头（逻辑屏幕描述符）拿画布宽高，无子进程开销。
// 用于批量导出时把水印位置按比例换算到各张 GIF 的尺寸。解析失败返回 0×0。
QSize imageSize(const QString &gifPath);

} // namespace gifprobe
