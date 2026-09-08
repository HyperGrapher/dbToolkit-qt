#pragma once

#include "core/DomainTypes.h"

#include <QAbstractListModel>

namespace dbtoolkit {

class ColumnListModel final : public QAbstractListModel {
    Q_OBJECT

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        TypeNameRole,
        NullableRole,
        GeneratedRole,
        BinaryRole,
        OrdinalRole
    };
    Q_ENUM(Role)

    explicit ColumnListModel(QObject *parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    void replaceColumns(QList<TableColumn> columns);
    void clear();

private:
    QList<TableColumn> m_columns;
};

} // namespace dbtoolkit
