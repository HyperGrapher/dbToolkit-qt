#include "core/DatabaseDriver.h"

#ifdef DBTOOLKIT_WITH_DATABASE_DRIVERS
#include <mysql/mysql.h>
#include <pqxx/pqxx>
#endif

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
                                  const ConnectionCredentials &credentials)
{
    const QString database = profile.maintenanceDatabase.isEmpty() ? "postgres"
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

std::unique_ptr<DatabaseDriver> createDatabaseDriver(DatabaseEngine engine)
{
    if (engine == DatabaseEngine::PostgreSql) {
        return std::make_unique<PostgreSqlDriver>();
    }

    return std::make_unique<MySqlDriver>(engine);
}

} // namespace dbtoolkit
