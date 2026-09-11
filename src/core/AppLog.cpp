#include "core/AppLog.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QLoggingCategory>
#include <QMutex>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTextStream>

namespace dbtoolkit {

namespace {

QMutex logMutex;
QString logFilePath;

QString sanitized(QString value)
{
    static const QRegularExpression passwordPattern(
        "(password\\s*[=:]\\s*)([^\\s,;]+)", QRegularExpression::CaseInsensitiveOption);
    value.replace(passwordPattern, "\\1<redacted>");
    return value;
}

void writeMessage(QtMsgType type, const QMessageLogContext &, const QString &message)
{
    QMutexLocker lock(&logMutex);
    if (logFilePath.isEmpty()) {
        return;
    }

    QFile file(logFilePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        return;
    }
    const char *level = type == QtWarningMsg ? "WARN" : type == QtCriticalMsg || type == QtFatalMsg
                                                  ? "ERROR"
                                                  : "INFO";
    QTextStream stream(&file);
    stream << QDateTime::currentDateTime().toString(Qt::ISODateWithMs) << " " << level << " "
           << sanitized(message) << Qt::endl;
}

} // namespace

void AppLog::initialize()
{
    const QString root = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    const QDir directory(root + "/logs");
    if (!directory.exists()) {
        QDir().mkpath(directory.path());
    }

    {
        QMutexLocker lock(&logMutex);
        logFilePath = directory.filePath("dbtoolkit.log");
    }
    qInstallMessageHandler(writeMessage);
    qInfo().noquote() << "Application logging initialized.";
}

void AppLog::operation(const QString &operation, bool succeeded, const QString &message,
                       const QString &recoveryHint)
{
    const QString text = "operation=" + operation + " result=" +
                         (succeeded ? "success" : "failure") + " message=" + sanitized(message) +
                         (recoveryHint.isEmpty() ? QString{} : " hint=" + sanitized(recoveryHint));
    if (succeeded) {
        qInfo().noquote() << text;
    } else {
        qWarning().noquote() << text;
    }
}

} // namespace dbtoolkit
