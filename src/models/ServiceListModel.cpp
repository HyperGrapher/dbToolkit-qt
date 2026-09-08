#include "models/ServiceListModel.h"

#include <utility>

namespace dbtoolkit {

ServiceListModel::ServiceListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ServiceListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_services.size();
}

QVariant ServiceListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_services.size()) {
        return {};
    }

    const auto &service = m_services.at(index.row());
    switch (role) {
    case ConnectionIdRole:
        return service.connectionId;
    case DisplayNameRole:
        return service.displayName;
    case StateRole:
        return static_cast<int>(service.state);
    case DetailRole:
        return service.detail;
    case ObservedAtRole:
        return service.observedAt;
    default:
        return {};
    }
}

QHash<int, QByteArray> ServiceListModel::roleNames() const
{
    return {{ConnectionIdRole, "connectionId"},
            {DisplayNameRole, "displayName"},
            {StateRole, "state"},
            {DetailRole, "detail"},
            {ObservedAtRole, "observedAt"}};
}

void ServiceListModel::replaceServices(QList<ServiceSummary> services)
{
    beginResetModel();
    m_services = std::move(services);
    endResetModel();
}

} // namespace dbtoolkit
