#include "models/TableListModel.h"

#include <utility>

namespace dbtoolkit {

TableListModel::TableListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int TableListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_tables.size();
}

QVariant TableListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tables.size()) {
        return {};
    }

    const TableSummary &table = m_tables.at(index.row());
    switch (role) {
    case SchemaNameRole:
        return table.schemaName;
    case TableNameRole:
        return table.tableName;
    case QualifiedNameRole:
        return table.schemaName.isEmpty() ? table.tableName
                                          : table.schemaName + "." + table.tableName;
    default:
        return {};
    }
}

QHash<int, QByteArray> TableListModel::roleNames() const
{
    return {{SchemaNameRole, "schemaName"},
            {TableNameRole, "tableName"},
            {QualifiedNameRole, "qualifiedName"}};
}

void TableListModel::replaceTables(QList<TableSummary> tables)
{
    beginResetModel();
    m_tables = std::move(tables);
    endResetModel();
}

void TableListModel::clear()
{
    replaceTables({});
}

} // namespace dbtoolkit
