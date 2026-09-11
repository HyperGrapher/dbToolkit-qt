#include "core/ProtectedConnections.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>
#include <QStandardPaths>
#include <QDebug>
#ifdef Q_OS_WIN
#include <windows.h>
#include <dpapi.h>
#endif

namespace dbtoolkit {
namespace {
QString directory()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/connections";
}
QString path(const QUuid &id)
{
    return directory() + "/" + id.toString(QUuid::WithoutBraces) + ".protected";
}
}
OperationResult ProtectedConnections::save(const StoredConnection &connection)
{
#ifdef Q_OS_WIN
    const auto &p = connection.profile;
    QByteArray plain = QJsonDocument(QJsonObject{
        {"id", p.id.toString()}, {"name", p.displayName}, {"engine", int(p.engine)},
        {"host", p.host}, {"port", p.port}, {"user", p.administratorUser},
        {"database", p.maintenanceDatabase}, {"service", p.serviceName},
        {"password", connection.credentials.administratorPassword}}).toJson(QJsonDocument::Compact);
    DATA_BLOB input{DWORD(plain.size()), reinterpret_cast<BYTE *>(plain.data())};
    DATA_BLOB output{};
    const bool encrypted = CryptProtectData(&input, L"dbToolKit connection", nullptr, nullptr,
                                            nullptr, CRYPTPROTECT_UI_FORBIDDEN, &output);
    plain.fill('\0');
    if (!encrypted) {
        return OperationResult::failure("Windows could not protect the connection credentials.");
    }
    QDir().mkpath(directory());
    QSaveFile file(path(p.id));
    const bool written = file.open(QIODevice::WriteOnly) &&
        file.write(reinterpret_cast<const char *>(output.pbData), output.cbData) == output.cbData && file.commit();
    LocalFree(output.pbData);
    return written ? OperationResult::success() : OperationResult::failure("Could not save the protected connection.");
#else
    Q_UNUSED(connection)
    return OperationResult::unsupported("Protected connection storage requires Windows.");
#endif
}
QList<StoredConnection> ProtectedConnections::load()
{
    QList<StoredConnection> connections;
#ifdef Q_OS_WIN
    for (const QString &name : QDir(directory()).entryList({"*.protected"}, QDir::Files)) {
        QFile file(directory() + "/" + name);
        if (!file.open(QIODevice::ReadOnly)) { continue; }
        QByteArray encrypted = file.readAll();
        DATA_BLOB input{DWORD(encrypted.size()), reinterpret_cast<BYTE *>(encrypted.data())};
        DATA_BLOB output{};
        if (!CryptUnprotectData(&input, nullptr, nullptr, nullptr, nullptr, CRYPTPROTECT_UI_FORBIDDEN, &output)) {
            qWarning() << "Could not unlock a protected connection for this Windows account.";
            continue;
        }
        const auto object = QJsonDocument::fromJson(QByteArray(reinterpret_cast<const char *>(output.pbData), output.cbData)).object();
        SecureZeroMemory(output.pbData, output.cbData);
        LocalFree(output.pbData);
        StoredConnection entry;
        auto &p = entry.profile;
        p.id = QUuid(object.value("id").toString());
        const int engine = object.value("engine").toInt(-1);
        if (p.id.isNull() || engine < 0 || engine > 2) { continue; }
        p.engine = DatabaseEngine(engine);
        p.displayName = object.value("name").toString();
        p.host = object.value("host").toString();
        p.port = object.value("port").toInt();
        p.administratorUser = object.value("user").toString();
        p.maintenanceDatabase = object.value("database").toString();
        p.serviceName = object.value("service").toString();
        entry.credentials.administratorPassword = object.value("password").toString();
        connections.append(std::move(entry));
    }
#endif
    return connections;
}
bool ProtectedConnections::remove(const QUuid &id)
{
    return !QFile::exists(path(id)) || QFile::remove(path(id));
}
}
