#include "videoexporter.h"

#include "gifprobe.h"
#include "paths.h"

#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QUrl>

VideoExporter::VideoExporter(QObject *parent) : QObject(parent) {}

QVariantMap VideoExporter::probeGif(const QString &gifPath) const
{
    QVariantMap m;
    const QSize s = gifprobe::imageSize(gifPath);
    m.insert(QStringLiteral("durationMs"), gifprobe::durationMs(gifPath));
    m.insert(QStringLiteral("width"), s.width());
    m.insert(QStringLiteral("height"), s.height());
    return m;
}

QString VideoExporter::extractPreview(const QString &gifPath)
{
    if (m_previewCache.contains(gifPath))
        return m_previewCache.value(gifPath);
    if (gifPath.isEmpty() || !QFileInfo::exists(gifPath))
        return QString();
    const QString ff = paths::ffmpegExecutable();
    if (!QFileInfo::exists(ff))
        return QString();

    const QString tmp = QDir::tempPath()
        + QStringLiteral("/gwm_vprev_%1.png").arg(QString::number(qlonglong(qHash(gifPath)), 16));
    if (!QFileInfo::exists(tmp)) {
        QProcess proc;
        proc.setProgram(ff);
        proc.setArguments({ QStringLiteral("-y"),
                            QStringLiteral("-i"), gifPath,
                            QStringLiteral("-vframes"), QStringLiteral("1"),
                            tmp });
        proc.start();
        if (!proc.waitForFinished(5000) && proc.state() != QProcess::NotRunning)
            return QString();
    }
    const QString url = QFileInfo::exists(tmp) ? QUrl::fromLocalFile(tmp).toString() : QString();
    if (!url.isEmpty())
        m_previewCache.insert(gifPath, url);
    return url;
}

void VideoExporter::exportOne(const QString &gifPath, int loops,
                              int outWidth, int outHeight, int fps, int crf,
                              const QString &outPath)
{
    if (m_running)
        return; // 防重入

    if (gifPath.isEmpty() || !QFileInfo::exists(gifPath)) {
        emit finished(false, ExportFailed, QString(), QStringLiteral("GIF 文件不存在"));
        return;
    }
    if (outPath.isEmpty()) {
        emit finished(false, ExportFailed, QString(), QStringLiteral("未设置导出路径"));
        return;
    }
    const QString ff = paths::ffmpegExecutable();
    if (!QFileInfo::exists(ff)) {
        emit finished(false, ExportFailed, QString(), QStringLiteral("找不到 ffmpeg.exe"));
        return;
    }

    // 等比缩进目标画布 + 黑边补齐 + 统一帧率 + yuv420p（兼容微信/QQ/浏览器）。
    // outWidth<=0 为「原始分辨率」档：不缩放，仅取偶（H.264 要求宽高偶数）。
    const QString vf = (outWidth > 0 && outHeight > 0)
        ? QStringLiteral("scale=%1:%2:force_original_aspect_ratio=decrease:flags=lanczos,"
                         "pad=%1:%2:(ow-iw)/2:(oh-ih)/2:black,").arg(outWidth).arg(outHeight)
        : QStringLiteral("scale=trunc(iw/2)*2:trunc(ih/2)*2:flags=lanczos,");
    const QString fullVf = vf + QStringLiteral("fps=%1,format=yuv420p").arg(fps);

    m_outPath = outPath;
    m_totalMs = gifprobe::durationMs(gifPath) * qMax(1, loops);   // 进度基准=源时长×次数
    m_cancelled = false;
    m_stderrBuffer.clear();
    setProgress(0);
    setRunning(true);

    if (!m_proc) {
        m_proc = new QProcess(this);
        connect(m_proc, &QProcess::readyReadStandardOutput,
                this, &VideoExporter::onReadyReadStandardOutput);
        connect(m_proc, &QProcess::readyReadStandardError,
                this, &VideoExporter::onReadyReadStandardError);
        connect(m_proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, &VideoExporter::onFinished);
    }

    QStringList args;
    args << QStringLiteral("-y")
         << QStringLiteral("-stream_loop") << QString::number(qMax(1, loops) - 1)
         << QStringLiteral("-i") << gifPath
         << QStringLiteral("-vf") << fullVf
         << QStringLiteral("-c:v") << QStringLiteral("libx264")
         << QStringLiteral("-crf") << QString::number(crf)
         << QStringLiteral("-preset") << QStringLiteral("medium")
         << QStringLiteral("-movflags") << QStringLiteral("+faststart")
         << QStringLiteral("-progress") << QStringLiteral("pipe:1")
         << QStringLiteral("-nostats")
         << outPath;
    m_proc->setProgram(ff);
    m_proc->setArguments(args);
    m_proc->start();
}

void VideoExporter::cancelExport()
{
    if (m_proc && m_running) {
        m_cancelled = true;
        m_proc->kill();
    }
}

bool VideoExporter::openContainingFolder(const QString &path) const
{
    const QFileInfo fi(path);
    const QString dir = fi.isDir() ? fi.absoluteFilePath() : fi.absolutePath();
    return QDesktopServices::openUrl(QUrl::fromLocalFile(dir));
}

void VideoExporter::onReadyReadStandardOutput()
{
    while (m_proc->canReadLine()) {
        const QString line = QString::fromLocal8Bit(m_proc->readLine()).trimmed();
        if (line.startsWith(QStringLiteral("out_time_us="))) {
            const qint64 us = line.mid(line.indexOf(QLatin1Char('=')) + 1).toLongLong();
            if (m_totalMs > 0) {
                const qint64 ms = us / 1000;
                setProgress(qBound(0, int(ms * 100 / m_totalMs), 99));
            }
        } else if (line == QStringLiteral("progress=end")) {
            setProgress(100);
        }
    }
}

void VideoExporter::onReadyReadStandardError()
{
    m_stderrBuffer.append(m_proc->readAllStandardError());
    if (m_stderrBuffer.size() > 8192)
        m_stderrBuffer = m_stderrBuffer.right(8192);
}

void VideoExporter::onFinished(int exitCode, QProcess::ExitStatus)
{
    const bool produced = QFileInfo::exists(m_outPath);

    if (m_cancelled) {
        setRunning(false);
        emit finished(false, ExportCancelled, m_outPath, QStringLiteral("已取消"));
    } else if (exitCode != 0 || !produced) {
        setRunning(false);
        const QString tail = QString::fromLocal8Bit(m_stderrBuffer.right(600));
        emit finished(false, ExportFailed, m_outPath,
                      QStringLiteral("导出失败 (exit %1)\n%2").arg(exitCode).arg(tail));
    } else {
        setProgress(100);
        setRunning(false);
        emit finished(true, ExportSuccess, m_outPath, QString());
    }
    m_stderrBuffer.clear();
}

void VideoExporter::setProgress(int pct)
{
    if (m_progress != pct) {
        m_progress = pct;
        emit progressChanged();
    }
}

void VideoExporter::setRunning(bool r)
{
    if (m_running != r) {
        m_running = r;
        emit runningChanged();
    }
}
