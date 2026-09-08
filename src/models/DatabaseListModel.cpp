#include "models/DatabaseListModel.h"

#include <utility>

namespace dbtoolkit {

DatabaseListModel::DatabaseListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int DatabaseListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_databases.size();
}

QVariant DatabaseListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_databases.size()) {
        return {};
    }

    const auto &database = m_databases.at(index.row());
    switch (role) {
    case NameRole:
        return database.name;
    case SchemaRole:
        return database.schema;
    case OwnerRole:
        return database.owner;
    case SizeRole:
        return database.sizeText;
    case TableCountRole:
        return database.tableCount;
    case ManagedRole:
        return database.isManaged;
    case RefreshedAtRole:
        return database.refreshedAt;
    default:
        return {};
    }
}

QHash<int, QByteArray> DatabaseListModel::roleNames() const
{
    return {{NameRole, "name"},
            {SchemaRole, "schema"},
            {OwnerRole, "owner"},
            {SizeRole, "size"},
            {TableCountRole, "tableCount"},
            {ManagedRole, "isManaged"},
            {RefreshedAtRole, "refreshedAt"}};
}

void DatabaseListModel::replaceDatabases(QList<DatabaseSummary> databases)
{
    beginResetModel();
    m_databases = std::move(databases);
    endResetModel();
}

void DatabaseListModel::clear()
{
    replaceDatabases({});
}

} // namespace dbtoolkit
