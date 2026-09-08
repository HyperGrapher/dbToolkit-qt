#include "models/ColumnListModel.h"

#include <utility>

namespace dbtoolkit {

ColumnListModel::ColumnListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ColumnListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_columns.size();
}

QVariant ColumnListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_columns.size()) {
        return {};
    }

    const TableColumn &column = m_columns.at(index.row());
    switch (role) {
    case NameRole:
        return column.name;
    case TypeNameRole:
        return column.typeName;
    case NullableRole:
        return column.isNullable;
    case GeneratedRole:
        return column.isGenerated;
    case BinaryRole:
        return column.isBinary;
    case OrdinalRole:
        return column.ordinal;
    default:
        return {};
    }
}

QHash<int, QByteArray> ColumnListModel::roleNames() const
{
    return {{NameRole, "name"},       {TypeNameRole, "typeName"},
            {NullableRole, "nullable"}, {GeneratedRole, "generated"},
            {BinaryRole, "binary"},   {OrdinalRole, "ordinal"}};
}

void ColumnListModel::replaceColumns(QList<TableColumn> columns)
{
    beginResetModel();
    m_columns = std::move(columns);
    endResetModel();
}

void ColumnListModel::clear()
{
    replaceColumns({});
}

} // namespace dbtoolkit
