#include "paths.h"

#include <QCoreApplication>
#include <QFileInfo>

// CMake 注入源码 tools 目录（开发期 fallback）；未定义时为空串。
#ifndef SOURCE_TOOLS_DIR
#define SOURCE_TOOLS_DIR ""
#endif

namespace paths {

QString ffmpegExecutable()
{
    // 1) 发布形态：exe 同级 tools/ffmpeg.exe（windeployqt 后随程序分发）
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString releaseCand = appDir + QStringLiteral("/tools/ffmpeg.exe");
    if (QFileInfo::exists(releaseCand))
        return releaseCand;

    // 2) 开发形态：源码 tools/ffmpeg.exe（运行时 exe 在 build 目录，找不到同级 tools）
    const QString devCand = QString::fromUtf8(SOURCE_TOOLS_DIR) + QStringLiteral("/ffmpeg.exe");
    if (QFileInfo::exists(devCand))
        return devCand;

    // 兜底：返回发布路径，由调用方检查存在性并报错
    return releaseCand;
}

QString gifsicleExecutable()
{
    // 解析顺序同 ffmpegExecutable
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString releaseCand = appDir + QStringLiteral("/tools/gifsicle.exe");
    if (QFileInfo::exists(releaseCand))
        return releaseCand;

    const QString devCand = QString::fromUtf8(SOURCE_TOOLS_DIR) + QStringLiteral("/gifsicle.exe");
    if (QFileInfo::exists(devCand))
        return devCand;

    return releaseCand;
}

} // namespace paths
