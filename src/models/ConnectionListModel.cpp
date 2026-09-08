#include "models/ConnectionListModel.h"

#include <utility>

namespace dbtoolkit {

ConnectionListModel::ConnectionListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ConnectionListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_profiles.size();
}

QVariant ConnectionListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_profiles.size()) {
        return {};
    }

    const auto &profile = m_profiles.at(index.row());
    switch (role) {
    case IdRole:
        return profile.id;
    case DisplayNameRole:
        return profile.displayName;
    case EngineRole:
        return static_cast<int>(profile.engine);
    case HostRole:
        return profile.host;
    case PortRole:
        return profile.port;
    case AdministratorRole:
        return profile.administratorUser;
    case MaintenanceDatabaseRole:
        return profile.maintenanceDatabase;
    case ServiceNameRole:
        return profile.serviceName;
    default:
        return {};
    }
}

QHash<int, QByteArray> ConnectionListModel::roleNames() const
{
    return {{IdRole, "id"},
            {DisplayNameRole, "displayName"},
            {EngineRole, "engine"},
            {HostRole, "host"},
            {PortRole, "port"},
            {AdministratorRole, "administratorUser"},
            {MaintenanceDatabaseRole, "maintenanceDatabase"},
            {ServiceNameRole, "serviceName"}};
}

void ConnectionListModel::replaceProfiles(QList<ConnectionProfile> profiles)
{
    beginResetModel();
    m_profiles = std::move(profiles);
    endResetModel();
}

const ConnectionProfile *ConnectionListModel::profile(const QUuid &id) const
{
    for (const auto &profile : m_profiles) {
        if (profile.id == id) {
            return &profile;
        }
    }

    return nullptr;
}

} // namespace dbtoolkit
