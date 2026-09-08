#pragma once

#include "core/DomainTypes.h"

#include <QAbstractListModel>

namespace dbtoolkit {

class DatabaseListModel final : public QAbstractListModel {
    Q_OBJECT

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        SchemaRole,
        OwnerRole,
        SizeRole,
        TableCountRole,
        ManagedRole,
        RefreshedAtRole
    };
    Q_ENUM(Role)

    explicit DatabaseListModel(QObject *parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    void replaceDatabases(QList<DatabaseSummary> databases);
    void clear();

private:
    QList<DatabaseSummary> m_databases;
};

} // namespace dbtoolkit
