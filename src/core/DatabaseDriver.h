#pragma once

#include "core/DomainTypes.h"

#include <memory>

namespace dbtoolkit {

struct DatabaseListResult {
    OperationResult operation;
    QList<DatabaseSummary> databases;
    QString serverVersion;
};

struct TableListResult {
    OperationResult operation;
    QList<TableSummary> tables;
};

struct TablePageResult {
    OperationResult operation;
    TablePage page;
};

class DatabaseDriver {
public:
    virtual ~DatabaseDriver() = default;

    [[nodiscard]] virtual DatabaseEngine engine() const = 0;
    [[nodiscard]] virtual DatabaseCapabilities capabilities() const = 0;
    [[nodiscard]] virtual OperationResult testConnection(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials) const = 0;
    [[nodiscard]] virtual DatabaseListResult listDatabases(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials) const = 0;
    [[nodiscard]] virtual TableListResult listTables(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials,
        const QString &databaseName) const = 0;
    [[nodiscard]] virtual TablePageResult loadTablePage(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials,
        const QString &databaseName, const QString &schemaName,
        const QString &tableName) const = 0;
};

class PostgreSqlDriver final : public DatabaseDriver {
public:
    [[nodiscard]] DatabaseEngine engine() const override;
    [[nodiscard]] DatabaseCapabilities capabilities() const override;
    [[nodiscard]] OperationResult testConnection(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials) const override;
    [[nodiscard]] DatabaseListResult listDatabases(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials) const override;
    [[nodiscard]] TableListResult listTables(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials,
        const QString &databaseName) const override;
    [[nodiscard]] TablePageResult loadTablePage(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials,
        const QString &databaseName, const QString &schemaName,
        const QString &tableName) const override;
};

class MySqlDriver final : public DatabaseDriver {
public:
    explicit MySqlDriver(DatabaseEngine engine);

    [[nodiscard]] DatabaseEngine engine() const override;
    [[nodiscard]] DatabaseCapabilities capabilities() const override;
    [[nodiscard]] OperationResult testConnection(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials) const override;
    [[nodiscard]] DatabaseListResult listDatabases(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials) const override;
    [[nodiscard]] TableListResult listTables(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials,
        const QString &databaseName) const override;
    [[nodiscard]] TablePageResult loadTablePage(
        const ConnectionProfile &profile, const ConnectionCredentials &credentials,
        const QString &databaseName, const QString &schemaName,
        const QString &tableName) const override;

private:
    DatabaseEngine m_engine;
};

[[nodiscard]] std::unique_ptr<DatabaseDriver> createDatabaseDriver(DatabaseEngine engine);

} // namespace dbtoolkit
