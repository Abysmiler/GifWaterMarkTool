#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QSettings>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QMessageLogContext>

// 日志文件（exe 同目录 gwm.log），实时落盘，便于排查"点击无响应"等问题。
// 捕获所有 Qt 消息：qDebug/qWarning/qCritical + QML 的 console.log/warn。
static QFile g_logFile;

static void gwmMessageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    static const char *levels[] = {"DEBUG", "WARN", "CRIT", "FATAL", "INFO"};
    const char *lvl = (type >= 0 && type <= 4) ? levels[type] : "?";
    QString line = QStringLiteral("[%1] [%2] %3")
                       .arg(QDateTime::currentDateTime().toString("hh:mm:ss.zzz"),
                            QString::fromLatin1(lvl), msg);
    if (ctx.file && ctx.line > 0)
        line += QStringLiteral("  @ %1:%2").arg(QString::fromLatin1(ctx.file)).arg(ctx.line);

    QTextStream out(&g_logFile);
    out << line << "\n";
    out.flush();  // 实时落盘，崩溃也保留

    if (type == QtFatalMsg)
        abort();
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 打开日志（覆盖模式：每次启动只保留最新一次运行）
    g_logFile.setFileName(app.applicationDirPath() + QStringLiteral("/gwm.log"));
    g_logFile.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate);
    qInstallMessageHandler(gwmMessageHandler);

    qDebug("==== GifWaterMarkTool 启动 dir=%s ====", qPrintable(app.applicationDirPath()));

    // 所有设置持久化到 exe 同目录的 GifWaterMarkTool.ini
    QCoreApplication::setOrganizationName("GifWaterMarkTool");
    QCoreApplication::setApplicationName("GifWaterMarkTool");
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope,
                       QCoreApplication::applicationDirPath());

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("GifWaterMarkTool", "Main");

    return QGuiApplication::exec();
}
