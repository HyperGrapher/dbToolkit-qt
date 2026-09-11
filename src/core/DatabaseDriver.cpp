#include "core/DatabaseDriver.h"

#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
#include <mysql/mysql.h>
#include <pqxx/pqxx>
#endif

#include <algorithm>
#include <array>
#include <iterator>
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

TablePageResult unavailableTablePage()
{
    return {.operation = driversUnavailableResult()};
}

TableCell textCell(const QByteArray &bytes, bool isBinary)
{
    if (isBinary) {
        const QString description = QString("Binary · %1 bytes").arg(bytes.size());
        return {.kind = CellValueKind::Binary,
                .displayText = description,
                .fullText = description};
    }

    const QString value = QString::fromUtf8(bytes);
    if (value.isEmpty()) {
        return {.kind = CellValueKind::Text, .displayText = "Empty string", .fullText = {}};
    }

    QString display = value;
    display.replace('\r', " ");
    display.replace('\n', " ");
    if (display.size() > 240) {
        display = display.left(239) + "…";
    }
    return {.kind = CellValueKind::Text, .displayText = display, .fullText = value};
}

TableCell nullCell()
{
    return {.kind = CellValueKind::Null, .displayText = "NULL", .fullText = "NULL"};
}

struct KeyCandidate {
    QString name;
    bool isPrimary{false};
    QStringList columns;
};

bool columnIsNonNullable(const QList<TableColumn> &columns, const QString &name)
{
    for (const TableColumn &column : columns) {
        if (column.name == name) {
            return !column.isNullable;
        }
    }
    return false;
}

QStringList chooseStableKey(const QList<KeyCandidate> &candidates,
                            const QList<TableColumn> &columns)
{
    for (const KeyCandidate &candidate : candidates) {
        bool allNonNullable = !candidate.columns.isEmpty();
        for (const QString &columnName : candidate.columns) {
            if (!columnIsNonNullable(columns, columnName)) {
                allNonNullable = false;
                break;
            }
        }
        if (candidate.isPrimary || allNonNullable) {
            return candidate.columns;
        }
    }
    return {};
}

QString quoteMySqlIdentifier(const QString &identifier)
{
    QString escaped = identifier;
    escaped.replace('`', "``");
    return '`' + escaped + '`';
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

TablePageResult PostgreSqlDriver::loadTablePage(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials,
    const QString &databaseName, const QString &schemaName, const QString &tableName,
    int pageNumber) const
{
#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
    try {
        pqxx::connection connection{
            postgreSqlConnectionString(profile, credentials, databaseName).toStdString()};
        pqxx::read_transaction transaction{connection};
        const std::string schema = schemaName.toUtf8().toStdString();
        const std::string table = tableName.toUtf8().toStdString();
        const pqxx::result columnRows = transaction.exec_params(
            "SELECT column_name, data_type, udt_name, is_nullable = 'YES', "
            "is_generated <> 'NEVER', ordinal_position "
            "FROM information_schema.columns "
            "WHERE table_schema = $1 AND table_name = $2 ORDER BY ordinal_position",
            schema, table);
        if (columnRows.empty()) {
            return {.operation = OperationResult::failure(
                        "The selected PostgreSQL table no longer exists.",
                        "Refresh the table list and choose an available table.")};
        }

        TablePage page;
        page.metadata.connectionId = profile.id;
        page.metadata.databaseName = databaseName;
        page.metadata.schemaName = schemaName;
        page.metadata.tableName = tableName;
        for (const auto &row : columnRows) {
            TableColumn column;
            column.name = QString::fromUtf8(row[0].c_str());
            column.typeName = QString::fromUtf8(row[1].c_str());
            column.isNullable = row[3].as<bool>();
            column.isGenerated = row[4].as<bool>();
            column.isBinary = QString::fromUtf8(row[2].c_str()) == "bytea";
            column.ordinal = row[5].as<int>();
            page.metadata.columns.append(std::move(column));
        }

        const pqxx::result keyRows = transaction.exec_params(
            "SELECT tc.constraint_name, tc.constraint_type, kcu.column_name, "
            "kcu.ordinal_position "
            "FROM information_schema.table_constraints AS tc "
            "JOIN information_schema.key_column_usage AS kcu "
            "ON tc.constraint_catalog = kcu.constraint_catalog "
            "AND tc.constraint_schema = kcu.constraint_schema "
            "AND tc.constraint_name = kcu.constraint_name "
            "WHERE tc.table_schema = $1 AND tc.table_name = $2 "
            "AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE') "
            "ORDER BY CASE WHEN tc.constraint_type = 'PRIMARY KEY' THEN 0 ELSE 1 END, "
            "tc.constraint_name, kcu.ordinal_position",
            schema, table);
        QList<KeyCandidate> candidates;
        for (const auto &row : keyRows) {
            const QString constraintName = QString::fromUtf8(row[0].c_str());
            if (candidates.isEmpty() || candidates.last().name != constraintName) {
                candidates.append({.name = constraintName,
                                   .isPrimary = QString::fromUtf8(row[1].c_str()) == "PRIMARY KEY"});
            }
            candidates.last().columns.append(QString::fromUtf8(row[2].c_str()));
        }
        page.orderColumns = chooseStableKey(candidates, page.metadata.columns);
        page.hasStableOrder = !page.orderColumns.isEmpty();
        page.pageNumber = pageNumber;
        if (pageNumber > 0 && !page.hasStableOrder) {
            return {.operation = OperationResult::failure(
                        "This table has no stable key for reliable pagination.",
                        "Choose a table with a primary key or non-null unique key.")};
        }

        std::string query = "SELECT * FROM " + transaction.quote_name(schema) + "." +
                            transaction.quote_name(table);
        if (page.hasStableOrder) {
            query += " ORDER BY ";
            for (qsizetype index = 0; index < page.orderColumns.size(); ++index) {
                if (index > 0) {
                    query += ", ";
                }
                query += transaction.quote_name(page.orderColumns.at(index).toUtf8().toStdString());
            }
        }
        query += " LIMIT 101 OFFSET " + std::to_string(static_cast<long long>(pageNumber) * 100);
        const pqxx::result dataRows = transaction.exec(query);
        for (const auto &row : dataRows) {
            QList<TableCell> cells;
            cells.reserve(page.metadata.columns.size());
            for (qsizetype columnIndex = 0; columnIndex < page.metadata.columns.size();
                 ++columnIndex) {
                const auto field = row[static_cast<pqxx::row::size_type>(columnIndex)];
                if (field.is_null()) {
                    cells.append(nullCell());
                    continue;
                }
                const std::string_view value = field.view();
                cells.append(textCell(QByteArray(value.data(), static_cast<qsizetype>(value.size())),
                                      page.metadata.columns.at(columnIndex).isBinary));
            }
            page.rows.append(std::move(cells));
        }
        page.hasMoreRows = page.rows.size() > 100;
        if (page.hasMoreRows) {
            page.rows.removeLast();
        }
        transaction.commit();
        return {.operation = OperationResult::success("Loaded the first table page."),
                .page = std::move(page)};
    } catch (const std::exception &error) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(error.what()),
                    "Refresh the table list and check the account's read privileges.")};
    }
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    Q_UNUSED(databaseName)
    Q_UNUSED(schemaName)
    Q_UNUSED(tableName)
    Q_UNUSED(pageNumber)
    return unavailableTablePage();
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

TablePageResult MySqlDriver::loadTablePage(
    const ConnectionProfile &profile, const ConnectionCredentials &credentials,
    const QString &databaseName, const QString &schemaName, const QString &tableName,
    int pageNumber) const
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
    mysql_set_character_set(connection.get(), "utf8mb4");

    const QString quotedTable = quoteMySqlIdentifier(tableName);
    const QByteArray columnQuery = ("SHOW FULL COLUMNS FROM " + quotedTable).toUtf8();
    if (mysql_query(connection.get(), columnQuery.constData()) != 0) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "Refresh the table list and check the account's metadata privileges.")};
    }
    std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> columnRows(
        mysql_store_result(connection.get()), mysql_free_result);
    if (!columnRows) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The server did not return column metadata.")};
    }

    TablePage page;
    page.metadata.connectionId = profile.id;
    page.metadata.databaseName = databaseName;
    page.metadata.schemaName = schemaName;
    page.metadata.tableName = tableName;
    int ordinal = 1;
    while (MYSQL_ROW row = mysql_fetch_row(columnRows.get())) {
        TableColumn column;
        column.name = QString::fromUtf8(row[0]);
        column.typeName = QString::fromUtf8(row[1]);
        column.isNullable = QString::fromUtf8(row[3]) == "YES";
        column.isGenerated = row[6] != nullptr &&
                             QString::fromUtf8(row[6]).contains("GENERATED", Qt::CaseInsensitive);
        const QString loweredType = column.typeName.toLower();
        column.isBinary = loweredType.startsWith("binary") || loweredType.startsWith("varbinary") ||
                          loweredType.contains("blob");
        column.ordinal = ordinal++;
        page.metadata.columns.append(std::move(column));
    }
    if (page.metadata.columns.isEmpty()) {
        return {.operation = OperationResult::failure(
                    "The selected MySQL/MariaDB table no longer exists.",
                    "Refresh the table list and choose an available table.")};
    }
    columnRows.reset();

    const QByteArray keyQuery = ("SHOW INDEX FROM " + quotedTable).toUtf8();
    if (mysql_query(connection.get(), keyQuery.constData()) != 0) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The table is readable but its index metadata could not be loaded.")};
    }
    std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> keyRows(
        mysql_store_result(connection.get()), mysql_free_result);
    QList<KeyCandidate> candidates;
    if (keyRows) {
        while (MYSQL_ROW row = mysql_fetch_row(keyRows.get())) {
            if (row[1] == nullptr || QString::fromUtf8(row[1]) != "0" || row[2] == nullptr ||
                row[4] == nullptr) {
                continue;
            }
            const QString keyName = QString::fromUtf8(row[2]);
            auto candidate = std::find_if(candidates.begin(), candidates.end(),
                                          [&keyName](const KeyCandidate &item) {
                                              return item.name == keyName;
                                          });
            if (candidate == candidates.end()) {
                candidates.append({.name = keyName, .isPrimary = keyName == "PRIMARY"});
                candidate = std::prev(candidates.end());
            }
            candidate->columns.append(QString::fromUtf8(row[4]));
        }
    }
    std::stable_sort(candidates.begin(), candidates.end(),
                     [](const KeyCandidate &left, const KeyCandidate &right) {
                         if (left.isPrimary != right.isPrimary) {
                             return left.isPrimary;
                         }
                         return left.columns.size() < right.columns.size();
                     });
    page.orderColumns = chooseStableKey(candidates, page.metadata.columns);
    page.hasStableOrder = !page.orderColumns.isEmpty();
    page.pageNumber = pageNumber;
    if (pageNumber > 0 && !page.hasStableOrder) {
        return {.operation = OperationResult::failure(
                    "This table has no stable key for reliable pagination.",
                    "Choose a table with a primary key or non-null unique key.")};
    }
    keyRows.reset();

    QString dataQuery = "SELECT * FROM " + quotedTable;
    if (page.hasStableOrder) {
        QStringList quotedColumns;
        for (const QString &columnName : page.orderColumns) {
            quotedColumns.append(quoteMySqlIdentifier(columnName));
        }
        dataQuery += " ORDER BY " + quotedColumns.join(", ");
    }
    dataQuery += " LIMIT 101 OFFSET " + QString::number(static_cast<qint64>(pageNumber) * 100);
    const QByteArray encodedDataQuery = dataQuery.toUtf8();
    if (mysql_query(connection.get(), encodedDataQuery.constData()) != 0) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The metadata loaded, but the table rows could not be read.")};
    }
    const std::unique_ptr<MYSQL_RES, decltype(&mysql_free_result)> dataRows(
        mysql_store_result(connection.get()), mysql_free_result);
    if (!dataRows) {
        return {.operation = OperationResult::failure(
                    QString::fromUtf8(mysql_error(connection.get())),
                    "The server did not return table rows.")};
    }
    while (MYSQL_ROW row = mysql_fetch_row(dataRows.get())) {
        const unsigned long *lengths = mysql_fetch_lengths(dataRows.get());
        QList<TableCell> cells;
        cells.reserve(page.metadata.columns.size());
        for (qsizetype columnIndex = 0; columnIndex < page.metadata.columns.size(); ++columnIndex) {
            if (row[columnIndex] == nullptr) {
                cells.append(nullCell());
                continue;
            }
            cells.append(textCell(
                QByteArray(row[columnIndex], static_cast<qsizetype>(lengths[columnIndex])),
                page.metadata.columns.at(columnIndex).isBinary));
        }
        page.rows.append(std::move(cells));
    }
    page.hasMoreRows = page.rows.size() > 100;
    if (page.hasMoreRows) {
        page.rows.removeLast();
    }
    return {.operation = OperationResult::success("Loaded the first table page."),
            .page = std::move(page)};
#else
    Q_UNUSED(profile)
    Q_UNUSED(credentials)
    Q_UNUSED(databaseName)
    Q_UNUSED(schemaName)
    Q_UNUSED(tableName)
    Q_UNUSED(pageNumber)
    return unavailableTablePage();
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
