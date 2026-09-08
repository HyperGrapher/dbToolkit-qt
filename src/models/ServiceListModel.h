#pragma once

#include "core/DomainTypes.h"

#include <QAbstractListModel>

namespace dbtoolkit {

class ServiceListModel final : public QAbstractListModel {
    Q_OBJECT

public:
    enum Role {
        ConnectionIdRole = Qt::UserRole + 1,
        DisplayNameRole,
        StateRole,
        DetailRole,
        ObservedAtRole
    };
    Q_ENUM(Role)

    explicit ServiceListModel(QObject *parent = nullptr);
    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;
    void replaceServices(QList<ServiceSummary> services);

private:
    QList<ServiceSummary> m_services;
};

} // namespace dbtoolkit
