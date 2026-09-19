#include "renamer.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSet>

Renamer::Renamer(QObject *parent) : QObject(parent) {}

void Renamer::setStripTimestamp(bool v)  { if (m_stripTimestamp != v)  { m_stripTimestamp = v;  emit stripTimestampChanged(); } }
void Renamer::setStripBrackets(bool v)   { if (m_stripBrackets != v)   { m_stripBrackets = v;   emit stripBracketsChanged(); } }
void Renamer::setStripCopySuffix(bool v) { if (m_stripCopySuffix != v) { m_stripCopySuffix = v; emit stripCopySuffixChanged(); } }
void Renamer::setGifOnly(bool v)         { if (m_gifOnly != v)         { m_gifOnly = v;         emit gifOnlyChanged(); } }
void Renamer::setRecursive(bool v)       { if (m_recursive != v)       { m_recursive = v;       emit recursiveChanged(); } }
void Renamer::setCustomPatterns(const QStringList &v)
{
    if (m_customPatterns != v) { m_customPatterns = v; emit customPatternsChanged(); }
}

// 时间戳两种形态：2026-06-26-20-07-33（日期-时间连字符）与 20260626200917（14 位纯数字）。
// 用完整段精确匹配，不误伤普通数字名（如 "1.gif"、"test1"）。
static const QRegularExpression kDateTimeSeg(QStringLiteral("^\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}-\\d{2}$"));
static const QRegularExpression kStamp14Seg(QStringLiteral("^\\d{14}$"));
// 副本后缀：段尾的 "空格 + 数字"（资源管理器复制品风格，如 "哭 1"）
static const QRegularExpression kCopySuffix(QStringLiteral("\\s+\\d+$"));

QString Renamer::cleanName(const QString &fileName) const
{
    QString stem = fileName;
    QString ext;
    const int dot = stem.lastIndexOf(QLatin1Char('.'));
    if (dot > 0) {
        ext = stem.mid(dot);
        stem = stem.left(dot);
    }

    QStringList keep;
    bool dropped = false;   // 是否发生过整段丢弃（时间戳）——丢弃后剩余段无分隔拼接，否则保留原 _
    const QStringList segs = stem.split(QLatin1Char('_'));
    for (QString s : segs) {
        if (m_stripTimestamp
                && (kDateTimeSeg.match(s).hasMatch() || kStamp14Seg.match(s).hasMatch())) {
            dropped = true;
            continue;
        }
        if (m_stripCopySuffix)
            s.remove(kCopySuffix);
        if (m_stripBrackets)
            s.remove(QLatin1Char('(')).remove(QLatin1Char(')'))
             .remove(QChar(0xFF08)).remove(QChar(0xFF09));   // 全角（ ）
        keep.append(s);
    }
    QString newStem = dropped ? keep.join(QString())
                              : keep.join(QLatin1Char('_'));
    if (!dropped && newStem == stem)
        newStem = stem;   // 无丢弃且段内无清洗：名字未变（走下方空判断统一处理）

    // 自定义正则：匹配到的部分直接删除；非法正则跳过（预览期 QML 已提示）
    for (const QString &p : m_customPatterns) {
        const QRegularExpression re(p);
        if (re.isValid())
            newStem.remove(re);
    }

    if (newStem.trimmed().isEmpty())
        return fileName;   // 清洗后无内容可保留：不动
    return newStem + ext;
}

QString Renamer::dedupeName(const QString &dir, const QString &base, const QString &ext,
                            QSet<QString> &used) const
{
    // 不冲突 = 不在本批已占用集合 且 磁盘上不存在（进入本函数时 cleaned != oldName，
    // 第一候选不可能等于自己，磁盘存在的同名只能是他者，必须避让）
    QString name = base + ext;
    QString full = QDir(dir).filePath(name);
    if (!used.contains(full.toLower()) && !QFile::exists(full))
        return name;
    // 撞名（本批或磁盘）→ 追加序号 " 2"、" 3"…（与副本后缀风格一致）
    for (int i = 2; ; ++i) {
        name = base + QStringLiteral(" %1").arg(i) + ext;
        full = QDir(dir).filePath(name);
        if (!used.contains(full.toLower()) && !QFile::exists(full))
            return name;
    }
}

QVariantList Renamer::preview(const QStringList &folders) const
{
    QVariantList out;
    QSet<QString> used;   // 本批已占用的小写全路径（磁盘已存在的文件天然占用，见 dedupe）

    // 收集文件（先目录序、后文件名序，保证加序号结果稳定可重现）
    struct Entry { QString path, dir, oldName, newName; };
    QList<Entry> entries;
    for (const QString &folder : folders) {
        const QDir d(folder);
        if (!d.exists())
            continue;
        const QFileInfoList fis = m_recursive
            ? [&] {
                  QFileInfoList acc;
                  QDirIterator it(folder, QDir::Files, QDirIterator::Subdirectories);
                  while (it.hasNext()) { it.next(); acc.append(it.fileInfo()); }
                  return acc;
              }()
            : d.entryInfoList(QDir::Files, QDir::Name);
        for (const QFileInfo &fi : fis) {
            if (m_gifOnly && fi.suffix().compare(QLatin1String("gif"), Qt::CaseInsensitive) != 0)
                continue;
            entries.append({ fi.absoluteFilePath(), fi.absolutePath(),
                             fi.fileName(), QString() });
        }
    }

    for (Entry &e : entries) {
        const QString cleaned = cleanName(e.oldName);
        if (cleaned == e.oldName) {
            e.newName = e.oldName;   // 无需改名：原样占用名字，不参与序号
        } else {
            const int dot = cleaned.lastIndexOf(QLatin1Char('.'));
            const QString base = dot > 0 ? cleaned.left(dot) : cleaned;
            const QString ext = dot > 0 ? cleaned.mid(dot) : QString();
            e.newName = dedupeName(e.dir, base, ext, used);
        }
        used.insert(QDir(e.dir).filePath(e.newName).toLower());

        QVariantMap m;
        m.insert(QStringLiteral("path"), e.path);
        m.insert(QStringLiteral("dir"), e.dir);
        m.insert(QStringLiteral("oldName"), e.oldName);
        m.insert(QStringLiteral("newName"), e.newName);
        m.insert(QStringLiteral("changed"), e.newName != e.oldName);
        out.append(m);
    }
    return out;
}

QVariantList Renamer::apply(const QVariantList &items) const
{
    QVariantList failures;
    for (const QVariant &v : items) {
        const QVariantMap m = v.toMap();
        if (!m.value(QStringLiteral("changed")).toBool())
            continue;
        const QString path = m.value(QStringLiteral("path")).toString();
        const QString oldName = m.value(QStringLiteral("oldName")).toString();
        const QString newName = m.value(QStringLiteral("newName")).toString();
        const QString target = QDir(m.value(QStringLiteral("dir")).toString()).filePath(newName);

        QVariantMap f;
        f.insert(QStringLiteral("path"), path);
        f.insert(QStringLiteral("oldName"), oldName);
        f.insert(QStringLiteral("newName"), newName);

        if (QFile::exists(target) && path.compare(target, Qt::CaseInsensitive) != 0) {
            f.insert(QStringLiteral("error"), QStringLiteral("目标文件已存在"));
            failures.append(f);
            continue;
        }
        if (!QFile::rename(path, target)) {
            // rename 原子失败：原文件保持原名（即"恢复该名字"）
            f.insert(QStringLiteral("error"), QStringLiteral("系统拒绝改名（文件被占用或无权限）"));
            failures.append(f);
        }
    }
    return failures;
}
