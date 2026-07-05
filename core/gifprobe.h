#pragma once

#include <QString>

// GIF 元信息探测（用于进度百分比计算）。
namespace gifprobe {

// 探测 GIF 总时长（毫秒）。失败/无法解析时返回 -1（调用方应降级为帧数进度）。
qint64 durationMs(const QString &gifPath);

} // namespace gifprobe
