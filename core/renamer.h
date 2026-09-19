#pragma once

#include <QObject>
#include <QRegularExpression>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <qqml.h>

// 批量重命名引擎：按分段规则清洗文件名（去时间戳段 / 括号 / 副本后缀 + 自定义正则），
// 预览并执行整目录改名。单文件改名是原子操作，失败自动保持原名。
// 规则示例：阿念_吃(爆米花)_2026-06-26-20-07-33_20260626200917.gif → 阿念吃爆米花.gif
class Renamer : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool stripTimestamp READ stripTimestamp WRITE setStripTimestamp NOTIFY stripTimestampChanged)
    Q_PROPERTY(bool stripBrackets READ stripBrackets WRITE setStripBrackets NOTIFY stripBracketsChanged)
    Q_PROPERTY(bool stripCopySuffix READ stripCopySuffix WRITE setStripCopySuffix NOTIFY stripCopySuffixChanged)
    Q_PROPERTY(bool gifOnly READ gifOnly WRITE setGifOnly NOTIFY gifOnlyChanged)
    Q_PROPERTY(bool recursive READ recursive WRITE setRecursive NOTIFY recursiveChanged)
    // 自定义「匹配即删除」正则列表（QML 从设置读出注入）
    Q_PROPERTY(QStringList customPatterns READ customPatterns WRITE setCustomPatterns NOTIFY customPatternsChanged)

public:
    explicit Renamer(QObject *parent = nullptr);

    bool stripTimestamp() const { return m_stripTimestamp; }
    bool stripBrackets() const { return m_stripBrackets; }
    bool stripCopySuffix() const { return m_stripCopySuffix; }
    bool gifOnly() const { return m_gifOnly; }
    bool recursive() const { return m_recursive; }
    QStringList customPatterns() const { return m_customPatterns; }
    void setStripTimestamp(bool v);
    void setStripBrackets(bool v);
    void setStripCopySuffix(bool v);
    void setGifOnly(bool v);
    void setRecursive(bool v);
    void setCustomPatterns(const QStringList &v);

    // 清洗单个文件名（纯文件名，不含路径）。清洗后无内容可保留时原样返回。
    Q_INVOKABLE QString cleanName(const QString &fileName) const;

    // 预览一批文件夹，返回条目列表：{path, dir, oldName, newName, changed}
    // 同批映射到同名（或与磁盘已有文件撞名）时自动加序号："阿念哭 2.gif"。
    Q_INVOKABLE QVariantList preview(const QStringList &folders) const;

    // 执行改名（items 取 preview 返回的条目）。返回失败清单：{path, oldName, newName, error}；
    // 失败的文件保持原名。目标已存在 / 被占用 / 无权限都会归入失败并带原因。
    Q_INVOKABLE QVariantList apply(const QVariantList &items) const;

    // 自定义正则是否合法（QML 输入框即时标红用）
    Q_INVOKABLE bool isPatternValid(const QString &pattern) const
    { return QRegularExpression(pattern).isValid(); }

signals:
    void stripTimestampChanged();
    void stripBracketsChanged();
    void stripCopySuffixChanged();
    void gifOnlyChanged();
    void recursiveChanged();
    void customPatternsChanged();

private:
    // 在 dir 内为 newBase.ext 找一个不冲突的名字（used 是本批已占用的全路径集合）
    QString dedupeName(const QString &dir, const QString &base, const QString &ext,
                       QSet<QString> &used) const;

    bool m_stripTimestamp = true;
    bool m_stripBrackets = true;
    bool m_stripCopySuffix = true;
    bool m_gifOnly = true;
    bool m_recursive = false;
    QStringList m_customPatterns;
};
