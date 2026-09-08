#pragma once

#include <QDateTime>
#include <QFlags>
#include <QList>
#include <QString>
#include <QStringList>
#include <QUuid>
#include <QVariant>

namespace dbtoolkit {

enum class DatabaseEngine {
    PostgreSql,
    MySql,
    MariaDb
};

enum class ServiceState {
    Unknown,
    Running,
    Stopped,
    Pending,
    Unavailable
};

enum class ConnectionState {
    Untested,
    Online,
    Offline
};

enum class OperationStatus {
    Succeeded,
    Failed,
    Cancelled,
    Unsupported
};

enum class DatabaseCapability {
    BrowseTables = 0x1,
    CreateDatabase = 0x2,
    ImportSql = 0x4,
    ExportSql = 0x8,
    ManageService = 0x10,
    EditRows = 0x20
};
Q_DECLARE_FLAGS(DatabaseCapabilities, DatabaseCapability)

struct ConnectionProfile {
    QUuid id{QUuid::createUuid()};
    QString displayName;
    DatabaseEngine engine{DatabaseEngine::PostgreSql};
    QString host{"127.0.0.1"};
    quint16 port{0};
    QString administratorUser;
    QString maintenanceDatabase;
    QString serviceName;
    ConnectionState lastTestState{ConnectionState::Untested};
    QDateTime lastTestedAt;
};

struct ConnectionCredentials {
    QString administratorPassword;
    QString projectUser;
    QString projectPassword;
};

struct ServiceSummary {
    QUuid connectionId;
    QString serviceName;
    QString displayName;
    QString executablePath;
    DatabaseEngine engine{DatabaseEngine::PostgreSql};
    quint16 port{0};
    ServiceState state{ServiceState::Unknown};
    QString detail;
    QDateTime observedAt;
};

struct DatabaseSummary {
    QUuid connectionId;
    QString name;
    QString schema;
    QString owner;
    QString sizeText;
    int tableCount{-1};
    bool isManaged{false};
    QDateTime refreshedAt;
};

struct TableSummary {
    QUuid connectionId;
    QString databaseName;
    QString schemaName;
    QString tableName;
};

struct CachedDatabaseSnapshot {
    QUuid connectionId;
    QList<DatabaseSummary> databases;
    QDateTime refreshedAt;
    QString serverVersion;
};

struct TableColumn {
    QString name;
    QString typeName;
    bool isNullable{true};
    bool isGenerated{false};
    bool isBinary{false};
    int ordinal{0};
};

struct TableMetadata {
    QUuid connectionId;
    QString databaseName;
    QString schemaName;
    QString tableName;
    QList<TableColumn> columns;
};

enum class CellValueKind {
    Text,
    Null,
    Binary
};

struct TableCell {
    CellValueKind kind{CellValueKind::Text};
    QString displayText;
    QString fullText;
};

struct TablePage {
    TableMetadata metadata;
    QList<QList<TableCell>> rows;
    QStringList orderColumns;
    bool hasStableOrder{false};
    bool hasMoreRows{false};
};

struct RowIdentity {
    QStringList columnNames;
    QVariantList values;

    [[nodiscard]] bool isUsable() const
    {
        return !columnNames.isEmpty() && columnNames.size() == values.size();
    }
};

struct OperationResult {
    OperationStatus status{OperationStatus::Succeeded};
    QString message;
    QString recoveryHint;

    [[nodiscard]] bool isSuccess() const { return status == OperationStatus::Succeeded; }

    static OperationResult success(QString message = {});
    static OperationResult failure(QString message, QString recoveryHint = {});
    static OperationResult unsupported(QString message);
};

struct TransferProgress {
    QUuid operationId{QUuid::createUuid()};
    qint64 completedBytes{0};
    qint64 totalBytes{-1};
    QString stage;
    bool isCancellable{true};
};

} // namespace dbtoolkit

Q_DECLARE_OPERATORS_FOR_FLAGS(dbtoolkit::DatabaseCapabilities)
Q_DECLARE_METATYPE(dbtoolkit::ConnectionProfile)
Q_DECLARE_METATYPE(dbtoolkit::DatabaseSummary)
Q_DECLARE_METATYPE(dbtoolkit::TableSummary)
Q_DECLARE_METATYPE(dbtoolkit::CachedDatabaseSnapshot)
Q_DECLARE_METATYPE(dbtoolkit::TableMetadata)
Q_DECLARE_METATYPE(dbtoolkit::TablePage)
Q_DECLARE_METATYPE(dbtoolkit::RowIdentity)
Q_DECLARE_METATYPE(dbtoolkit::OperationResult)
