#include "core/DatabaseDriver.h"

namespace dbtoolkit {

namespace {

OperationResult pendingDriverResult()
{
    return OperationResult::unsupported(
        "Live connection testing will be available when saved connections are implemented.");
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
    const ConnectionProfile &, const ConnectionCredentials &) const
{
    return pendingDriverResult();
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
    const ConnectionProfile &, const ConnectionCredentials &) const
{
    return pendingDriverResult();
}

std::unique_ptr<DatabaseDriver> createDatabaseDriver(DatabaseEngine engine)
{
    if (engine == DatabaseEngine::PostgreSql) {
        return std::make_unique<PostgreSqlDriver>();
    }

    return std::make_unique<MySqlDriver>(engine);
}

} // namespace dbtoolkit
