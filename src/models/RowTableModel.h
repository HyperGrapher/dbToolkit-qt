#pragma once

#include "core/DomainTypes.h"

#include <QAbstractTableModel>

namespace dbtoolkit {

class RowTableModel final : public QAbstractTableModel {
    Q_OBJECT

public:
    enum Role {
        DisplayTextRole = Qt::UserRole + 1,
        FullTextRole,
        ValueKindRole
    };
    Q_ENUM(Role)

    explicit RowTableModel(QObject *parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] int columnCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role) const override;
    [[nodiscard]] QVariant headerData(int section, Qt::Orientation orientation,
                                      int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    void replacePage(TablePage page);
    void clear();

private:
    TablePage m_page;
};

} // namespace dbtoolkit
