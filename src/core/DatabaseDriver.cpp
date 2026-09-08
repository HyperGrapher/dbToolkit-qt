#include "core/DatabaseDriver.h"

#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
#include <mysql/mysql.h>
#include <pqxx/pqxx>
#endif

#include <array>
#include <memory>

namespace dbtoolkit {

namespace {

QString escapePostgreSqlParameter(const QString &value)
{
    QString escaped = value;
    escaped.replace('\\', "\\\\");
    escaped.replace('\'', "\\'");
    return "'" + escaped + "'";
}

QString postgreSqlConnectionString(const ConnectionProfile &profile,
                                  const ConnectionCredentials &credentials,
                                  const QString &databaseOverride = {})
{
    const QString database = !databaseOverride.isEmpty()
                                 ? databaseOverride
                                 : profile.maintenanceDatabase.isEmpty() ? "postgres"
                                                                          : profile.maintenanceDatabase;
    return "host=" + escapePostgreSqlParameter(profile.host) + " port=" +
           QString::number(profile.port == 0 ? 5432 : profile.port) + " user=" +
           escapePostgreSqlParameter(profile.administratorUser) + " password=" +
           escapePostgreSqlParameter(credentials.administratorPassword) + " dbname=" +
           escapePostgreSqlParameter(database) + " connect_timeout='5'";
}

OperationResult driversUnavailableResult()
{
    return OperationResult::unsupported("Database drivers are unavailable in the UI preview build.");
}

DatabaseCapabilities commonCapabilities()
{
    return DatabaseCapability::BrowseTables | DatabaseCapability::CreateDatabase |
           DatabaseCapability::ImportSql | DatabaseCapability::ExportSql |
           DatabaseCapability::EditRows;
}

QString formatBytes(quint64 bytes)
{
    constexpr std::array<const char *, 5> units{"B", "KB", "MB", "GB", "TB"};
    double value = static_cast<double>(bytes);
    qsizetype unitIndex = 0;
    while (value >= 1024.0 && unitIndex < units.size() - 1) {
        value /= 1024.0;
        ++unitIndex;
    }
    return QString::number(value, 'f', unitIndex == 0 ? 0 : 1) + " " + units[unitIndex];
}

DatabaseListResult unavailableDatabaseList()
{
    return {.operation = driversUnavailableResult()};
}

TableListResult unavailableTableList()
{
    return {.operation = driversUnavailableResult()};
}

} // namespace

DatabaseEngine PostgreSqlDriver::engine() const
{
    return DatabaseEngine::PostgreSql;
}

DatabaseCapabilities PostgreSqlDriver::capabilities() const
{
    return commonCapabilities();
}

OperationResult PostgreSqlDriver::testConnection(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials) const
{
#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
    try {
        pqxx::connection connection{postgreSqlConnectionString(profile, credentials).toStdString()};
        if (!connection.is_open()) {
            return OperationResult::failure("PostgreSQL did not open a connection.",
                                            "Check that the service is running and the connection details are correct.");
        }
        return OperationResult::success("Connected to PostgreSQL.");
    } catch (const std::exception &error) {
        return OperationResult::failure(QString::fromUtf8(error.what()),
                                        "Check the service, administrator password, host, port, and maintenance database.");
    }
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    return driversUnavailableResult();
#endif
}

DatabaseListResult PostgreSqlDriver::listDatabases(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials) const
{
#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
    try {
        pqxx::connection connection{postgreSqlConnectionString(profile, credentials).toStdString()};
        pqxx::read_transaction transaction{connection};
        const pqxx::result rows = transaction.exec(
            "SELECT datname, pg_get_userbyid(datdba), pg_size_pretty(pg_database_size(datname)) "
            "FROM pg_database WHERE NOT datistemplate ORDER BY datname");
        const pqxx::result versionRows = transaction.exec("SHOW server_version");
        transaction.commit();

        DatabaseListResult result;
        result.operation = OperationResult::success("Database summaries refreshed.");
        result.serverVersion = versionRows.empty() ? QString{} : QString::fromUtf8(versionRows[0][0].c_str());
        for (const auto &row : rows) {
            DatabaseSummary summary;
            summary.connectionId = profile.id;
            summary.name = QString::fromUtf8(row[0].c_str());
            summary.owner = row[1].is_null() ? QString{} : QString::fromUtf8(row[1].c_str());
            summary.sizeText = row[2].is_null() ? "Unavailable" : QString::fromUtf8(row[2].c_str());
            summary.refreshedAt = QDateTime::currentDateTime();
            result.databases.append(std::move(summary));
        }
        return result;
    } catch (const std::exception &error) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(error.what()),
                    "Check that the service is running and the administrator account can read database metadata.")};
    }
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    return unavailableDatabaseList();
#endif
}

TableListResult PostgreSqlDriver::listTables(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials,
    const QString &databaseName) const
{
#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
    try {
        pqxx::connection connection{
            postgreSqlConnectionString(profile, credentials, databaseName).toStdString()};
        pqxx::read_transaction transaction{connection};
        const pqxx::result rows = transaction.exec(
            "SELECT table_schema, table_name FROM information_schema.tables "
            "WHERE table_type = 'BASE TABLE' "
            "AND table_schema NOT IN ('pg_catalog', 'information_schema') "
            "ORDER BY table_schema, table_name");
        transaction.commit();

        TableListResult result;
        result.operation = OperationResult::success("Tables loaded from " + databaseName + ".");
        for (const auto &row : rows) {
            TableSummary summary;
            summary.connectionId = profile.id;
            summary.databaseName = databaseName;
            summary.schemaName = QString::fromUtf8(row[0].c_str());
            summary.tableName = QString::fromUtf8(row[1].c_str());
            result.tables.append(std::move(summary));
        }
        return result;
    } catch (const std::exception &error) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(error.what()),
                    "Check that the database exists and the administrator account can read its table metadata.")};
    }
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    Q_UNUSED(databaseName)
    return unavailableTableList();
#endif
}

MySqlDriver::MySqlDriver(DatabaseEngine engine)
    : m_engine(engine)
{
}

DatabaseEngine MySqlDriver::engine() const
{
    return m_engine;
}

DatabaseCapabilities MySqlDriver::capabilities() const
{
    return commonCapabilities();
}

OperationResult MySqlDriver::testConnection(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials) const
{
#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
    MYSQL *rawConnection = mysql_init(nullptr);
    if (rawConnection == nullptr) {
        return OperationResult::failure("Could not initialize the MySQL client library.");
    }

    const std::unique_ptr<MYSQL, decltype(&mysql_close)> connection(rawConnection, mysql_close);
    const QByteArray host = profile.host.toUtf8();
    const QByteArray user = profile.administratorUser.toUtf8();
    const QByteArray password = credentials.administratorPassword.toUtf8();
    const QByteArray database = profile.maintenanceDatabase.toUtf8();
    const unsigned int port = profile.port == 0 ? 3306 : profile.port;
    if (mysql_real_connect(connection.get(), host.constData(), user.constData(), password.constData(),
                           database.isEmpty() ? nullptr : database.constData(), port, nullptr, 0) == nullptr) {
        return OperationResult::failure(QString::fromUtf8(mysql_error(connection.get())),
                                        "Check the service, administrator password, host, port, and database name.");
    }

    return OperationResult::success(m_engine == DatabaseEngine::MariaDb ? "Connected to MariaDB."
                                                                         : "Connected to MySQL.");
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    return driversUnavailableResult();
#endif
}

DatabaseListResult MySqlDriver::listDatabases(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials) const
{
#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
    MYSQL *rawConnection = mysql_init(nullptr);
    if (rawConnection == nullptr) {
        return {.operation = OperationResult::failure("Could not initialize the MySQL client library.")};
    }
    const std::unique_ptr<MYSQL, decltype(&mysql_close)> connection(rawConnection, mysql_close);
    const QByteArray host = profile.host.toUtf8();
    const QByteArray user = profile.administratorUser.toUtf8();
    const QByteArray password = credentials.administratorPassword.toUtf8();
    const unsigned int port = profile.port == 0 ? 3306 : profile.port;
    if (mysql_real_connect(connection.get(), host.constData(), user.constData(), password.constData(),
                           nullptr, port, nullptr, 0) == nullptr) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "Check the service, administrator password, host, and port.")};
    }

    constexpr const char *query =
        "SELECT s.schema_name, COALESCE(SUM(t.data_length + t.index_length), 0), COUNT(t.table_name) "
        "FROM information_schema.schemata AS s "
        "LEFT JOIN information_schema.tables AS t ON t.table_schema = s.schema_name "
        "GROUP BY s.schema_name ORDER BY s.schema_name";
    if (mysql_query(connection.get(), query) != 0) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The account connected but cannot read database metadata.")};
    }
    const std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> rows(mysql_store_result(connection.get()),
                                                                          mysql_free_result);
    if (!rows) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The server did not return database metadata.")};
    }

    DatabaseListResult result;
    result.operation = OperationResult::success("Database summaries refreshed.");
    result.serverVersion = QString::fromUtf8(mysql_get_server_info(connection.get()));
    while (MYSQL_ROW row = mysql_fetch_row(rows.get())) {
        DatabaseSummary summary;
        summary.connectionId = profile.id;
        summary.name = QString::fromUtf8(row[0]);
        summary.sizeText = formatBytes(QString::fromUtf8(row[1]).toULongLong());
        summary.tableCount = QString::fromUtf8(row[2]).toInt();
        summary.refreshedAt = QDateTime::currentDateTime();
        result.databases.append(std::move(summary));
    }
    return result;
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    return unavailableDatabaseList();
#endif
}

TableListResult MySqlDriver::listTables(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials,
    const QString &databaseName) const
{
#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
    MYSQL *rawConnection = mysql_init(nullptr);
    if (rawConnection == nullptr) {
        return {.operation = OperationResult::failure("Could not initialize the MySQL client library.")};
    }
    const std::unique_ptr<MYSQL, decltype(&mysql_close)> connection(rawConnection, mysql_close);
    const QByteArray host = profile.host.toUtf8();
    const QByteArray user = profile.administratorUser.toUtf8();
    const QByteArray password = credentials.administratorPassword.toUtf8();
    const QByteArray database = databaseName.toUtf8();
    const unsigned int port = profile.port == 0 ? 3306 : profile.port;
    if (mysql_real_connect(connection.get(), host.constData(), user.constData(), password.constData(),
                           database.constData(), port, nullptr, 0) == nullptr) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "Check that the database exists and the account can connect to it.")};
    }

    constexpr const char *query =
        "SELECT table_schema, table_name FROM information_schema.tables "
        "WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE' "
        "ORDER BY table_name";
    if (mysql_query(connection.get(), query) != 0) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The account connected but cannot read table metadata.")};
    }
    const std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> rows(
        mysql_store_result(connection.get()), mysql_free_result);
    if (!rows) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The server did not return table metadata.")};
    }

    TableListResult result;
    result.operation = OperationResult::success("Tables loaded from " + databaseName + ".");
    while (MYSQL_ROW row = mysql_fetch_row(rows.get())) {
        TableSummary summary;
        summary.connectionId = profile.id;
        summary.databaseName = databaseName;
        summary.schemaName = QString::fromUtf8(row[0]);
        summary.tableName = QString::fromUtf8(row[1]);
        result.tables.append(std::move(summary));
    }
    return result;
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    Q_UNUSED(databaseName)
    return unavailableTableList();
#endif
}

std::unique_ptr<DatabaseDriver> createDatabaseDriver(DatabaseEngine engine)
{
    if (engine == DatabaseEngine::PostgreSql) {
        return std::make_unique<PostgreSqlDriver>();
    }

    return std::make_unique<MySqlDriver>(engine);
}

} // namespace dbtoolkit
