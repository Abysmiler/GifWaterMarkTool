#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QVariantMap>
#include <qqml.h>

// GIF → MP4 视频导出引擎。刻意做成与水印管线（FFmpegRunner）零依赖的独立模块：
// 不含水印/调色板逻辑，未来可整体抽出做成独立软件（自带 probe/export/cancel/progress）。
// 单任务模型：QML 侧维护任务队列，逐个调 exportOne()；完成后 finished 信号回调。
class VideoExporter : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)

public:
    // finished 信号的 status 参数
    enum ExportState { ExportSuccess = 0, ExportFailed = 1, ExportCancelled = 2 };
    Q_ENUM(ExportState)

    explicit VideoExporter(QObject *parent = nullptr);

    bool running() const { return m_running; }
    int progress() const { return m_progress; }

    // 探测 GIF：durationMs(失败 -1)、width/height(失败 0)，供界面换算成片时长
    Q_INVOKABLE QVariantMap probeGif(const QString &gifPath) const;

    // 导出单个 GIF → MP4。loops=总播放次数(≥1，实现用 -stream_loop loops-1)。
    // outWidth/outHeight 为画布尺寸（GIF 等比缩进画布，余量补黑边），fps/crf 编码参数。
    Q_INVOKABLE void exportOne(const QString &gifPath, int loops,
                               int outWidth, int outHeight, int fps, int crf,
                               const QString &outPath);

    // 中途取消：kill ffmpeg，finished 以 status=Cancelled 回调
    Q_INVOKABLE void cancelExport();

    // 在资源管理器中打开 path 所在文件夹
    Q_INVOKABLE bool openContainingFolder(const QString &path) const;

signals:
    void runningChanged();
    void progressChanged();
    // ok=true 成功；false 时 status 区分 Failed/Cancelled，errorMsg 含排错信息
    void finished(bool ok, int status, const QString &outputPath, const QString &errorMsg);

private:
    void setProgress(int pct);
    void setRunning(bool r);

    void onReadyReadStandardOutput();
    void onReadyReadStandardError();
    void onFinished(int exitCode, QProcess::ExitStatus exitStatus);

    QProcess *m_proc = nullptr;
    QString m_outPath;
    qint64 m_totalMs = -1;
    int m_progress = 0;
    bool m_running = false;
    bool m_cancelled = false;
    QByteArray m_stderrBuffer;
};
