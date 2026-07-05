#pragma once

#include <QString>

// ffmpeg.exe 定位与路径工具（无需暴露给 QML，故用 namespace 而非 QObject）。
namespace paths {

// 返回 ffmpeg.exe 绝对路径。
// 解析顺序：1) 发布形态 exe 同级 tools/  2) 开发形态源码 tools/（CMake 注入 SOURCE_TOOLS_DIR）
// 都找不到时返回默认候选路径，交由调用方报错。
QString ffmpegExecutable();

// 返回 gifsicle.exe 绝对路径（GIF 后处理优化工具：帧间差异 + 有损压缩）。
// 解析顺序同 ffmpegExecutable；找不到时返回默认候选，交由调用方判断存在性。
QString gifsicleExecutable();

} // namespace paths
