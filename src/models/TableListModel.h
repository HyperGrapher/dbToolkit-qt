#pragma once

#include "core/DomainTypes.h"

#include <QAbstractListModel>

namespace dbtoolkit {

class TableListModel final : public QAbstractListModel {
    Q_OBJECT

public:
    enum Role {
        SchemaNameRole = Qt::UserRole + 1,
        TableNameRole,
        QualifiedNameRole
    };
    Q_ENUM(Role)

    explicit TableListModel(QObject *parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    void replaceTables(QList<TableSummary> tables);
    void clear();

private:
    QList<TableSummary> m_tables;
};

} // namespace dbtoolkit
