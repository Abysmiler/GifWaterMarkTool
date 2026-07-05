#include "ffmpegrunner.h"

#include "gifprobe.h"
#include "paths.h"

#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QUrl>
#include <QtMath>

FFmpegRunner::FFmpegRunner(QObject *parent) : QObject(parent) {}

// ---- paths ----
void FFmpegRunner::setGifPath(const QString &v)   { if (m_gifPath != v)   { m_gifPath = v;   emit gifPathChanged(); } }
void FFmpegRunner::setWaterPath(const QString &v) { if (m_waterPath != v) { m_waterPath = v; emit waterPathChanged(); } }
void FFmpegRunner::setOutPath(const QString &v)   { if (m_outPath != v)   { m_outPath = v;   emit outPathChanged(); } }

// ---- watermark params ----
void FFmpegRunner::setWmX(double v)       { if (!qFuzzyCompare(m_wmX + 1.0, v + 1.0))       { m_wmX = v;       emit wmXChanged(); } }
void FFmpegRunner::setWmY(double v)       { if (!qFuzzyCompare(m_wmY + 1.0, v + 1.0))       { m_wmY = v;       emit wmYChanged(); } }
void FFmpegRunner::setWmScale(double v)   { if (!qFuzzyCompare(m_wmScale + 1.0, v + 1.0))   { m_wmScale = v;   emit wmScaleChanged(); } }
void FFmpegRunner::setWmOpacity(double v) { if (!qFuzzyCompare(m_wmOpacity + 1.0, v + 1.0)) { m_wmOpacity = v; emit wmOpacityChanged(); } }
void FFmpegRunner::setWmRotate(double v)  { if (!qFuzzyCompare(m_wmRotate + 1.0, v + 1.0))  { m_wmRotate = v;  emit wmRotateChanged(); } }

void FFmpegRunner::setQualityLevel(int v)
{
    v = qBound(0, v, 3);
    if (m_qualityLevel != v) { m_qualityLevel = v; emit qualityLevelChanged(); }
}

void FFmpegRunner::setMaxWidth(int v)
{
    v = qBound(0, v, 7680); // 上限 8K 宽，防非法
    if (m_maxWidth != v) { m_maxWidth = v; emit maxWidthChanged(); }
}
void FFmpegRunner::setTargetFps(int v)
{
    v = qBound(0, v, 120);
    if (m_targetFps != v) { m_targetFps = v; emit targetFpsChanged(); }
}
void FFmpegRunner::setDitherMode(int v)
{
    v = qBound(0, v, 2);
    if (m_ditherMode != v) { m_ditherMode = v; emit ditherModeChanged(); }
}

void FFmpegRunner::setDeepOptimize(bool v)
{
    if (m_deepOptimize != v) { m_deepOptimize = v; emit deepOptimizeChanged(); }
}

void FFmpegRunner::setUseTextWater(bool v)
{
    if (m_useTextWater != v) { m_useTextWater = v; emit useTextWaterChanged(); }
}
void FFmpegRunner::setTextContent(const QString &v)
{
    if (m_textContent != v) { m_textContent = v; emit textContentChanged(); }
}
void FFmpegRunner::setTextFontSize(int v)
{
    v = qBound(8, v, 200);
    if (m_textFontSize != v) { m_textFontSize = v; emit textFontSizeChanged(); }
}
void FFmpegRunner::setTextColor(const QString &v)
{
    if (m_textColor != v) { m_textColor = v; emit textColorChanged(); }
}

qint64 FFmpegRunner::totalDurationMs() const
{
    return m_gifPath.isEmpty() ? -1 : gifprobe::durationMs(m_gifPath);
}

QString FFmpegRunner::buildFilterComplex() const
{
    // clamp 防非法滤镜表达式（透明度严格 [0,1]，缩放严格 >0），定点格式化禁科学计数法/本地化逗号
    const double s  = qBound(0.05, m_wmScale, 10.0);
    const double a  = m_wmRotate;
    const double o  = qBound(0.0, m_wmOpacity, 1.0);
    const double cx = m_wmX;
    const double cy = m_wmY;

    const QString ss = QString::number(s, 'f', 4);
    const QString aa = QString::number(a, 'f', 4);
    const QString oo = QString::number(o, 'f', 4);
    const QString x  = QString::number(cx, 'f', 2);
    const QString y  = QString::number(cy, 'f', 2);
    const int colors[] = { 256, 128, 64, 32 };
    const int maxColors = colors[qBound(0, m_qualityLevel, 3)];

    // ---- 压缩段（0 值=不应用，保持原画质）----
    // fps 放输入最前：与像素坐标无关，不影响 wmX/wmY，且减少后续 overlay/palette 计算量
    const bool useFps = m_targetFps > 0;
    const QString head    = useFps ? QStringLiteral("[0:v]fps=%1[v0];").arg(m_targetFps) : QString();
    const QString inLabel = useFps ? QStringLiteral("[v0]") : QStringLiteral("[0:v]");
    // scale 放 overlay/drawtext 之后：保证 wmX/wmY 按"原图像素坐标"语义不变；
    // min(iw,W) 确保原图比 W 窄时不放大；-2 保证高度偶数；lanczos 降采样质量最好
    const QString scaleSeg = m_maxWidth > 0
        ? QStringLiteral(",scale='min(iw,%1)':-2:flags=lanczos").arg(m_maxWidth)
        : QString();
    // dither：bayer(规则网点,LZW 友好,体积小,无 banding) > none(最小但发糊) > sierra2_4a(最平滑但最大)
    QString ditherArg;
    switch (m_ditherMode) {
    case 1:  ditherArg = QStringLiteral("none"); break;
    case 2:  ditherArg = QStringLiteral("sierra2_4a"); break;
    default: ditherArg = QStringLiteral("bayer:bayer_scale=3"); break;
    }

    if (m_useTextWater && !m_textContent.isEmpty()) {
        // 文字水印：drawtext 滤镜
        QString escaped = m_textContent;
        escaped.replace(QLatin1Char('\''), QStringLiteral("\\'"));
        escaped.replace(QLatin1Char(':'), QStringLiteral("\\:"));
        const QString fs = QString::number(m_textFontSize);
        const QString alpha = QString::number(qBound(0.0, m_wmOpacity, 1.0), 'f', 2);
        return QStringLiteral(
            "%1%2drawtext=text='%3':fontsize=%4:fontcolor=%5@%6:"
            "x=%7-tw/2:y=%8-th/2%9,"
            "split=2[a][b];"
            "[a]palettegen=stats_mode=diff:max_colors=%10[pal];"
            "[b][pal]paletteuse=new=1:dither=%11[out]"
        ).arg(head, inLabel, escaped, fs, m_textColor, alpha, x, y, scaleSeg)
         .arg(maxColors).arg(ditherArg);
    }

    // 图像水印
    return QStringLiteral(
        "%1[1:v]scale=iw*%2:ih*%3,"
        "rotate=%4*PI/180:ow=rotw(%4*PI/180):oh=roth(%4*PI/180):fillcolor=0x00000000,"
        "format=rgba,colorchannelmixer=aa=%5[wm];"
        "%6[wm]overlay=x=%7-w/2:y=%8-h/2%9[comp];"
        "[comp]split=2[a][b];"
        "[a]palettegen=stats_mode=diff:max_colors=%10[pal];"
        "[b][pal]paletteuse=new=1:dither=%11[out]"
    ).arg(head, ss, ss, aa, oo, inLabel, x, y, scaleSeg)
     .arg(maxColors).arg(ditherArg);
}

void FFmpegRunner::exportGif()
{
    if (m_running)
        return; // 防重入

    if (m_gifPath.isEmpty() || !QFileInfo::exists(m_gifPath)) {
        emit finished(false, ExportFailed, QString(), QStringLiteral("GIF 文件不存在"));
        return;
    }
    if (!m_useTextWater && (m_waterPath.isEmpty() || !QFileInfo::exists(m_waterPath))) {
        emit finished(false, ExportFailed, QString(), QStringLiteral("水印文件不存在"));
        return;
    }
    if (m_outPath.isEmpty()) {
        emit finished(false, ExportFailed, QString(), QStringLiteral("未设置导出路径"));
        return;
    }
    const QString ff = paths::ffmpegExecutable();
    if (!QFileInfo::exists(ff)) {
        emit finished(false, ExportFailed, QString(), QStringLiteral("找不到 ffmpeg.exe"));
        return;
    }

    m_totalMs = gifprobe::durationMs(m_gifPath);
    m_cancelled = false;
    m_stderrBuffer.clear();
    setProgress(0);
    setRunning(true);

    if (!m_proc) {
        m_proc = new QProcess(this);
        connect(m_proc, &QProcess::readyReadStandardOutput,
                this, &FFmpegRunner::onReadyReadStandardOutput);
        connect(m_proc, &QProcess::readyReadStandardError,
                this, &FFmpegRunner::onReadyReadStandardError);
        connect(m_proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, &FFmpegRunner::onFinished);
    }

    QStringList args;
    args << QStringLiteral("-y") << QStringLiteral("-i") << m_gifPath;
    if (!m_useTextWater)
        args << QStringLiteral("-i") << m_waterPath;
    args << QStringLiteral("-filter_complex") << buildFilterComplex()
         << QStringLiteral("-map") << QStringLiteral("[out]")
         << QStringLiteral("-progress") << QStringLiteral("pipe:1")
         << QStringLiteral("-nostats")
         << m_outPath;
    m_proc->setProgram(ff);
    m_proc->setArguments(args);
    m_proc->start();
}

void FFmpegRunner::cancelExport()
{
    if (m_proc && m_running) {
        m_cancelled = true;
        m_proc->kill();
    }
    if (m_gifsicleProc && m_running) {
        m_cancelled = true;
        m_gifsicleProc->kill();
    }
}

bool FFmpegRunner::openContainingFolder(const QString &path)
{
    const QFileInfo fi(path);
    const QString dir = fi.exists() ? fi.absolutePath() : path;
    return QDesktopServices::openUrl(QUrl::fromLocalFile(dir));
}

QString FFmpegRunner::extractPreview(const QString &gifPath)
{
    if (gifPath.isEmpty() || !QFileInfo::exists(gifPath))
        return QString();
    const QString ff = paths::ffmpegExecutable();
    if (!QFileInfo::exists(ff))
        return QString();

    const QString tmp = QDir::tempPath() + QStringLiteral("/gwm_preview.png");
    QProcess proc;
    proc.setProgram(ff);
    proc.setArguments({
        QStringLiteral("-y"),
        QStringLiteral("-i"), gifPath,
        QStringLiteral("-vframes"), QStringLiteral("1"),
        tmp,
    });
    proc.start();
    if (!proc.waitForFinished(5000))
        return QString();
    return QFileInfo::exists(tmp) ? QUrl::fromLocalFile(tmp).toString() : QString();
}

void FFmpegRunner::requestPreviewAsync(const QString &gifPath)
{
    // 先清理上一次未完成的预览进程
    if (m_previewProc) {
        m_previewProc->kill();
        m_previewProc->deleteLater();
        m_previewProc = nullptr;
    }

    if (gifPath.isEmpty() || !QFileInfo::exists(gifPath)) {
        emit previewFrameReady(QString(), 0, 0);
        return;
    }
    const QString ff = paths::ffmpegExecutable();
    if (!QFileInfo::exists(ff)) {
        emit previewFrameReady(QString(), 0, 0);
        return;
    }

    const QString tmp = QDir::tempPath() + QStringLiteral("/gwm_preview.png");
    const QString tmpUrl = QUrl::fromLocalFile(tmp).toString(); // file:/// 格式

    m_previewProc = new QProcess(this);
    m_previewProc->setProgram(ff);
    m_previewProc->setArguments({
        QStringLiteral("-y"),
        QStringLiteral("-i"), gifPath,
        QStringLiteral("-vframes"), QStringLiteral("1"),
        tmp,
    });

    // 正常结束
    connect(m_previewProc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, tmp, tmpUrl](int exitCode, QProcess::ExitStatus) {
        const bool ok = (exitCode == 0 && QFileInfo::exists(tmp));
        if (ok) {
            QImage img(tmp);
            emit previewFrameReady(tmpUrl, img.width(), img.height());
        } else {
            emit previewFrameReady(QString(), 0, 0);
        }
        if (m_previewProc) {
            m_previewProc->deleteLater();
            m_previewProc = nullptr;
        }
    });

    // 进程启动/运行错误（如 ffmpeg 依赖缺失）→ 不回传结果，防止一直转圈
    connect(m_previewProc, &QProcess::errorOccurred,
            this, [this](QProcess::ProcessError) {
        emit previewFrameReady(QString(), 0, 0);
        if (m_previewProc) {
            m_previewProc->deleteLater();
            m_previewProc = nullptr;
        }
    });

    m_previewProc->start();
}

void FFmpegRunner::onReadyReadStandardOutput()
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

void FFmpegRunner::onReadyReadStandardError()
{
    m_stderrBuffer.append(m_proc->readAllStandardError());
    if (m_stderrBuffer.size() > 8192)
        m_stderrBuffer = m_stderrBuffer.right(8192);
}

void FFmpegRunner::onFinished(int exitCode, QProcess::ExitStatus)
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
        // ffmpeg 成功；按需跑 gifsicle 后处理（保持 running）
        setProgress(100);
        if (m_deepOptimize) {
            const QString gifsicle = paths::gifsicleExecutable();
            if (QFileInfo::exists(gifsicle)) {
                m_stderrBuffer.clear();
                runGifsicle(gifsicle);
                return;  // 等 onGifsicleFinished 再 emit finished
            }
        }
        setRunning(false);
        emit finished(true, ExportSuccess, m_outPath, QString());
    }
    m_stderrBuffer.clear();
}

void FFmpegRunner::runGifsicle(const QString &gifsicleExe)
{
    m_optPath = m_outPath + QStringLiteral(".opt.gif");
    QFile::remove(m_optPath);  // 清理上次残留

    if (!m_gifsicleProc) {
        m_gifsicleProc = new QProcess(this);
        connect(m_gifsicleProc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
                this, &FFmpegRunner::onGifsicleFinished);
    }
    QStringList args;
    args << QStringLiteral("--no-warnings")
         << QStringLiteral("-O3")         // 最高级别帧间差异优化
         << QStringLiteral("--lossy=80")  // 有损压缩（肉眼几乎无感）
         << m_outPath
         << QStringLiteral("-o") << m_optPath;
    m_gifsicleProc->setProgram(gifsicleExe);
    m_gifsicleProc->setArguments(args);
    m_gifsicleProc->start();
}

void FFmpegRunner::onGifsicleFinished(int exitCode, QProcess::ExitStatus)
{
    setRunning(false);
    const bool optOk = (exitCode == 0 && QFileInfo::exists(m_optPath));
    if (optOk) {
        QFile::remove(m_outPath);
        if (QFile::rename(m_optPath, m_outPath)) {
            emit finished(true, ExportSuccess, m_outPath, QString());
            return;
        }
    }
    // gifsicle 失败或 rename 失败：清理临时，降级用 ffmpeg 输出（仍算成功）
    QFile::remove(m_optPath);
    emit finished(true, ExportSuccess, m_outPath,
                  QFileInfo::exists(m_outPath)
                      ? QStringLiteral("（gifsicle 优化未生效，已用未优化版本）")
                      : QString());
}

void FFmpegRunner::setProgress(int pct)
{
    if (m_progress != pct) {
        m_progress = pct;
        emit progressChanged();
    }
}

void FFmpegRunner::setRunning(bool r)
{
    if (m_running != r) {
        m_running = r;
        emit runningChanged();
    }
}
