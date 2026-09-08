#pragma once

#include "core/DomainTypes.h"
#include "core/StaleResultGate.h"
#include "models/ConnectionListModel.h"
#include "models/DatabaseListModel.h"
#include "models/ServiceListModel.h"

#include <QObject>

namespace dbtoolkit {

class ApplicationController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QObject *connectionsModel READ connectionsModel CONSTANT)
    Q_PROPERTY(QObject *servicesModel READ servicesModel CONSTANT)
    Q_PROPERTY(QObject *databasesModel READ databasesModel CONSTANT)
    Q_PROPERTY(QString activeConnectionId READ activeConnectionId WRITE setActiveConnectionId NOTIFY activeConnectionChanged)
    Q_PROPERTY(QString activeDatabaseName READ activeDatabaseName WRITE setActiveDatabaseName NOTIFY activeDatabaseChanged)
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)

public:
    explicit ApplicationController(QObject *parent = nullptr);
    [[nodiscard]] QObject *connectionsModel();
    [[nodiscard]] QObject *servicesModel();
    [[nodiscard]] QObject *databasesModel();
    [[nodiscard]] QString activeConnectionId() const;
    [[nodiscard]] QString activeDatabaseName() const;
    [[nodiscard]] bool isBusy() const;
    void setSessionProfiles(QList<ConnectionProfile> profiles);
    void setActiveConnectionId(const QString &connectionId);
    void setActiveDatabaseName(const QString &databaseName);
    Q_INVOKABLE void testActiveConnection(const QString &administratorPassword);
    Q_INVOKABLE void cancelActiveWork();

signals:
    void activeConnectionChanged();
    void activeDatabaseChanged();
    void busyChanged();
    void operationCompleted(const QString &operation, bool succeeded, const QString &message,
                            const QString &recoveryHint);

private:
    [[nodiscard]] const ConnectionProfile *activeProfile() const;
    void setBusy(bool isBusy);
    ConnectionListModel m_connections;
    ServiceListModel m_services;
    DatabaseListModel m_databases;
    StaleResultGate m_resultGate;
    QUuid m_activeConnectionId;
    QString m_activeDatabaseName;
    bool m_isBusy{false};
};

} // namespace dbtoolkit
