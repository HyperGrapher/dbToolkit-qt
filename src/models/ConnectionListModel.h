#pragma once

#include "core/DomainTypes.h"

#include <QAbstractListModel>

namespace dbtoolkit {

class ConnectionListModel final : public QAbstractListModel {
    Q_OBJECT

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        DisplayNameRole,
        EngineRole,
        HostRole,
        PortRole,
        AdministratorRole,
        MaintenanceDatabaseRole,
        ServiceNameRole
    };
    Q_ENUM(Role)

    explicit ConnectionListModel(QObject *parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex &parent = {}) const override;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    void replaceProfiles(QList<ConnectionProfile> profiles);
    void upsertProfile(ConnectionProfile profile);
    bool removeProfile(const QUuid &id);
    [[nodiscard]] const ConnectionProfile *profile(const QUuid &id) const;

private:
    QList<ConnectionProfile> m_profiles;
};

} // namespace dbtoolkit
