#include "gifprobe.h"

#include "paths.h"

#include <QFile>
#include <QProcess>
#include <QRegularExpression>
#include <QString>

namespace gifprobe {

// 跑一次 `ffmpeg -i input`（无输出参数），从 stderr 抓 Duration: HH:MM:SS.xx。
// 同步调用：探测本身不耗帧、很快（<1s），UI 线程短暂阻塞可接受。
qint64 durationMs(const QString &gifPath)
{
    QProcess proc;
    proc.setProgram(paths::ffmpegExecutable());
    proc.setArguments({ QStringLiteral("-hide_banner"), QStringLiteral("-i"), gifPath });
    proc.start();
    if (!proc.waitForFinished(5000))
        return -1;

    const QString out = QString::fromLocal8Bit(proc.readAllStandardError())
                      + QString::fromLocal8Bit(proc.readAllStandardOutput());

    static const QRegularExpression re(
        QStringLiteral("Duration:\\s*(\\d+):(\\d+):(\\d+(?:\\.\\d+)?)"));
    const QRegularExpressionMatch m = re.match(out);
    if (!m.hasMatch())
        return -1;

    const qint64 h   = m.captured(1).toLongLong();
    const qint64 min = m.captured(2).toLongLong();
    const double s   = m.captured(3).toDouble();
    return qint64((h * 3600 + min * 60 + s) * 1000.0);
}

// GIF 头 6~9 字节是逻辑屏幕描述符：宽/高各占 2 字节，小端序。
QSize imageSize(const QString &gifPath)
{
    QFile f(gifPath);
    if (!f.open(QIODevice::ReadOnly))
        return QSize(0, 0);
    const QByteArray head = f.read(10);
    if (head.size() < 10 || !head.startsWith("GIF"))
        return QSize(0, 0);
    const int w = quint8(head[6]) | quint8(head[7]) << 8;
    const int h = quint8(head[8]) | quint8(head[9]) << 8;
    return QSize(w, h);
}

} // namespace gifprobe
