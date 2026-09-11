#include "models/RowTableModel.h"

#include <utility>

namespace dbtoolkit {

RowTableModel::RowTableModel(QObject *parent)
    : QAbstractTableModel(parent)
{
}

int RowTableModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_page.rows.size();
}

int RowTableModel::columnCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_page.metadata.columns.size();
}

QVariant RowTableModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_page.rows.size() ||
        index.column() < 0 || index.column() >= m_page.metadata.columns.size()) {
        return {};
    }

    const QList<TableCell> &row = m_page.rows.at(index.row());
    if (index.column() >= row.size()) {
        return {};
    }
    const TableCell &cell = row.at(index.column());
    switch (role) {
    case Qt::DisplayRole:
    case DisplayTextRole:
        return cell.displayText;
    case FullTextRole:
        return cell.fullText;
    case ValueKindRole:
        return static_cast<int>(cell.kind);
    default:
        return {};
    }
}

QVariant RowTableModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole) {
        return {};
    }
    if (orientation == Qt::Horizontal && section >= 0 &&
        section < m_page.metadata.columns.size()) {
        return m_page.metadata.columns.at(section).name;
    }
    if (orientation == Qt::Vertical && section >= 0 && section < m_page.rows.size()) {
        return section + 1;
    }
    return {};
}

QHash<int, QByteArray> RowTableModel::roleNames() const
{
    return {{Qt::DisplayRole, "display"}, {DisplayTextRole, "displayText"},
            {FullTextRole, "fullText"},
            {ValueKindRole, "valueKind"}};
}

void RowTableModel::replacePage(TablePage page)
{
    beginResetModel();
    m_page = std::move(page);
    endResetModel();
}

void RowTableModel::clear()
{
    replacePage({});
}

} // namespace dbtoolkit
