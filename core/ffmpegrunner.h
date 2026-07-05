#pragma once

#include <QByteArray>
#include <QObject>
#include <QProcess>
#include <QString>
#include <qqml.h>   // QML_ELEMENT / QML_NAMED_ELEMENT 等 QML 注册宏

// 核心导出类：拼装 ffmpeg 滤镜命令 + QProcess 异步调度 + 进度/取消/错误处理。
// 暴露给 QML：QML 直接设属性、调 exportGif()、监听 finished()。
class FFmpegRunner : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString gifPath    READ gifPath    WRITE setGifPath    NOTIFY gifPathChanged)
    Q_PROPERTY(QString waterPath READ waterPath WRITE setWaterPath NOTIFY waterPathChanged)
    Q_PROPERTY(QString outPath   READ outPath   WRITE setOutPath   NOTIFY outPathChanged)

    // 水印中心点，GIF 原图像素坐标（由 QML 预览换算后传入）
    Q_PROPERTY(double wmX       READ wmX       WRITE setWmX       NOTIFY wmXChanged)
    Q_PROPERTY(double wmY       READ wmY       WRITE setWmY       NOTIFY wmYChanged)
    Q_PROPERTY(double wmScale   READ wmScale   WRITE setWmScale   NOTIFY wmScaleChanged)   // S
    Q_PROPERTY(double wmOpacity READ wmOpacity WRITE setWmOpacity NOTIFY wmOpacityChanged) // O 0~1
    Q_PROPERTY(double wmRotate  READ wmRotate  WRITE setWmRotate  NOTIFY wmRotateChanged)  // A 度

    Q_PROPERTY(int  progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    // 调色板色数：0=256, 1=128, 2=64, 3=32
    Q_PROPERTY(int  qualityLevel READ qualityLevel WRITE setQualityLevel NOTIFY qualityLevelChanged)

    // 压缩参数（默认值均为"不压缩/保持原画质"，由 QML 预设或手动覆盖）
    Q_PROPERTY(int maxWidth   READ maxWidth   WRITE setMaxWidth   NOTIFY maxWidthChanged)     // 0=不缩放；>0 按宽等比缩（只缩不放）
    Q_PROPERTY(int targetFps  READ targetFps  WRITE setTargetFps  NOTIFY targetFpsChanged)     // 0=保持原帧率；>0 降帧率
    Q_PROPERTY(int ditherMode READ ditherMode WRITE setDitherMode NOTIFY ditherModeChanged)    // 0=bayer, 1=none, 2=sierra2_4a

    // 导出后用 gifsicle 做深度优化（帧间差异 + 有损压缩，再瘦 30~40%）
    Q_PROPERTY(bool deepOptimize READ deepOptimize WRITE setDeepOptimize NOTIFY deepOptimizeChanged)

    // 文字水印
    Q_PROPERTY(bool useTextWater READ useTextWater WRITE setUseTextWater NOTIFY useTextWaterChanged)
    Q_PROPERTY(QString textContent READ textContent WRITE setTextContent NOTIFY textContentChanged)
    Q_PROPERTY(int  textFontSize READ textFontSize WRITE setTextFontSize NOTIFY textFontSizeChanged)
    Q_PROPERTY(QString textColor READ textColor WRITE setTextColor NOTIFY textColorChanged)

public:
    // 导出结束状态（finished 信号的 status 参数）
    enum ExportState { ExportSuccess = 0, ExportFailed = 1, ExportCancelled = 2 };
    Q_ENUM(ExportState)

    explicit FFmpegRunner(QObject *parent = nullptr);

    QString gifPath() const { return m_gifPath; }
    QString waterPath() const { return m_waterPath; }
    QString outPath() const { return m_outPath; }
    void setGifPath(const QString &v);
    void setWaterPath(const QString &v);
    void setOutPath(const QString &v);

    double wmX() const { return m_wmX; }
    double wmY() const { return m_wmY; }
    double wmScale() const { return m_wmScale; }
    double wmOpacity() const { return m_wmOpacity; }
    double wmRotate() const { return m_wmRotate; }
    void setWmX(double v);
    void setWmY(double v);
    void setWmScale(double v);
    void setWmOpacity(double v);
    void setWmRotate(double v);

    int  progress() const { return m_progress; }
    int  qualityLevel() const { return m_qualityLevel; }
    void setQualityLevel(int v);

    int  maxWidth() const { return m_maxWidth; }
    int  targetFps() const { return m_targetFps; }
    int  ditherMode() const { return m_ditherMode; }
    void setMaxWidth(int v);
    void setTargetFps(int v);
    void setDitherMode(int v);

    bool deepOptimize() const { return m_deepOptimize; }
    void setDeepOptimize(bool v);

    bool running() const { return m_running; }

    bool useTextWater() const { return m_useTextWater; }
    void setUseTextWater(bool v);
    QString textContent() const { return m_textContent; }
    void setTextContent(const QString &v);
    int  textFontSize() const { return m_textFontSize; }
    void setTextFontSize(int v);
    QString textColor() const { return m_textColor; }
    void setTextColor(const QString &v);

    // 探测当前 gifPath 总时长（毫秒），失败返回 -1（调用方应降级为帧数进度）
    Q_INVOKABLE qint64 totalDurationMs() const;

    // 拼命令 + 启动 QProcess（异步）。输入缺失/ffmpeg 缺失时直接 emit finished(false)
    Q_INVOKABLE void exportGif();

    // 中途取消：kill ffmpeg，finished 以 status=Cancelled 回调
    Q_INVOKABLE void cancelExport();

    // 在资源管理器中打开 path 所在文件夹（导出成功后调用）
    Q_INVOKABLE bool openContainingFolder(const QString &path);

    // 同步抽取第一帧（已废弃，保留兼容；新代码请用异步版）
    Q_INVOKABLE QString extractPreview(const QString &gifPath);

    // 异步抽取第一帧 PNG（不阻塞 UI）。完成后 emit previewFrameReady。
    // 多次调用自动 kill 上次未完成的进程。
    Q_INVOKABLE void requestPreviewAsync(const QString &gifPath);

signals:
    void gifPathChanged();
    void waterPathChanged();
    void outPathChanged();
    void wmXChanged();
    void wmYChanged();
    void wmScaleChanged();
    void wmOpacityChanged();
    void wmRotateChanged();
    void progressChanged();
    void runningChanged();
    void qualityLevelChanged();
    void maxWidthChanged();
    void targetFpsChanged();
    void ditherModeChanged();
    void deepOptimizeChanged();
    void useTextWaterChanged();
    void textContentChanged();
    void textFontSizeChanged();
    void textColorChanged();

    // ok=true 成功；ok=false 时 status 区分 Failed/Cancelled，errorMsg 含排错信息
    void finished(bool ok, int status, const QString &outputPath, const QString &errorMsg);

    // 异步预览抽帧完成；空串表示失败。w/h 为 PNG 实际像素尺寸。
    void previewFrameReady(const QString &pngPath, int width, int height);

private:
    QString buildFilterComplex() const; // §4.2 锁中心版滤镜图（参数 clamp + 定点格式化）
    void setProgress(int pct);
    void setRunning(bool r);

    void onReadyReadStandardOutput();
    void onReadyReadStandardError();
    void onFinished(int exitCode, QProcess::ExitStatus exitStatus);

    // gifsicle 后处理（ffmpeg 成功后按需启动）
    void runGifsicle(const QString &gifsicleExe);
    void onGifsicleFinished(int exitCode, QProcess::ExitStatus exitStatus);

    QProcess *m_proc = nullptr;
    QProcess *m_previewProc = nullptr;   // 异步预览专用（独立于导出 pipeline）
    QProcess *m_gifsicleProc = nullptr;  // gifsicle 后处理专用

    QString m_gifPath;
    QString m_waterPath;
    QString m_outPath;
    QString m_optPath;          // gifsicle 优化输出临时文件（m_outPath + ".opt.gif"）

    double m_wmX = 0.0;
    double m_wmY = 0.0;
    double m_wmScale = 1.0;
    double m_wmOpacity = 1.0;
    double m_wmRotate = 0.0;

    int  m_progress = 0;
    int  m_qualityLevel = 0;
    int  m_maxWidth = 0;       // 0=不缩放
    int  m_targetFps = 0;      // 0=保持原帧率
    int  m_ditherMode = 0;     // 0=bayer,1=none,2=sierra2_4a
    bool m_deepOptimize = false; // 导出后是否跑 gifsicle 深度优化

    bool m_useTextWater = false;
    QString m_textContent;
    int  m_textFontSize = 24;
    QString m_textColor = "#ffffff";
    bool m_running = false;
    bool m_cancelled = false;

    qint64 m_totalMs = -1;      // 缓存 GIF 总时长（-1 表示未知，进度降级为不更新百分比）
    QByteArray m_stderrBuffer;  // 缓存 stderr 末尾用于出错排错
};
