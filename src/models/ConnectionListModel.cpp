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
    case ConnectionStateRole:
        return static_cast<int>(profile.lastTestState);
    case LastTestedAtRole:
        return profile.lastTestedAt;
    default:
        return {};
    }
}

QHash<int, QByteArray> ConnectionListModel::roleNames() const
{
    return {{IdRole, "connectionId"},
            {DisplayNameRole, "displayName"},
            {EngineRole, "engine"},
            {HostRole, "host"},
            {PortRole, "port"},
            {AdministratorRole, "administratorUser"},
            {MaintenanceDatabaseRole, "maintenanceDatabase"},
            {ServiceNameRole, "serviceName"},
            {ConnectionStateRole, "connectionState"},
            {LastTestedAtRole, "lastTestedAt"}};
}

void ConnectionListModel::replaceProfiles(QList<ConnectionProfile> profiles)
{
    beginResetModel();
    m_profiles = std::move(profiles);
    endResetModel();
}

void ConnectionListModel::upsertProfile(ConnectionProfile profile)
{
    for (qsizetype index = 0; index < m_profiles.size(); ++index) {
        if (m_profiles.at(index).id != profile.id) {
            continue;
        }

        m_profiles[index] = std::move(profile);
        const QModelIndex modelIndex = this->index(index);
        emit dataChanged(modelIndex, modelIndex);
        return;
    }

    const qsizetype row = m_profiles.size();
    beginInsertRows({}, row, row);
    m_profiles.append(std::move(profile));
    endInsertRows();
}

bool ConnectionListModel::removeProfile(const QUuid &id)
{
    for (qsizetype index = 0; index < m_profiles.size(); ++index) {
        if (m_profiles.at(index).id != id) {
            continue;
        }

        beginRemoveRows({}, index, index);
        m_profiles.removeAt(index);
        endRemoveRows();
        return true;
    }

    return false;
}

void ConnectionListModel::setTestResult(const QUuid &id, bool isOnline, const QDateTime &testedAt)
{
    for (qsizetype index = 0; index < m_profiles.size(); ++index) {
        ConnectionProfile &profile = m_profiles[index];
        if (profile.id != id) {
            continue;
        }

        profile.lastTestState = isOnline ? ConnectionState::Online : ConnectionState::Offline;
        profile.lastTestedAt = testedAt;
        const QModelIndex modelIndex = this->index(index);
        emit dataChanged(modelIndex, modelIndex, {ConnectionStateRole, LastTestedAtRole});
        return;
    }
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
