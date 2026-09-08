#pragma once

#include "core/DomainTypes.h"
#include "core/CachedSnapshotStore.h"
#include "core/SessionCredentialStore.h"
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
    Q_PROPERTY(bool isScanningServices READ isScanningServices NOTIFY scanningServicesChanged)
    Q_PROPERTY(int discoveredServiceCount READ discoveredServiceCount NOTIFY servicesChanged)

public:
    explicit ApplicationController(QObject *parent = nullptr);
    [[nodiscard]] QObject *connectionsModel();
    [[nodiscard]] QObject *servicesModel();
    [[nodiscard]] QObject *databasesModel();
    [[nodiscard]] QString activeConnectionId() const;
    [[nodiscard]] QString activeDatabaseName() const;
    [[nodiscard]] bool isBusy() const;
    [[nodiscard]] bool isScanningServices() const;
    [[nodiscard]] int discoveredServiceCount() const;
    void setSessionProfiles(QList<ConnectionProfile> profiles);
    void setActiveConnectionId(const QString &connectionId);
    void setActiveDatabaseName(const QString &databaseName);
    Q_INVOKABLE bool saveConnection(const QString &displayName, int engine, const QString &host,
                                    int port, const QString &administratorUser,
                                    const QString &administratorPassword,
                                    const QString &maintenanceDatabase = {},
                                    const QString &serviceName = {});
    Q_INVOKABLE void removeActiveConnection();
    Q_INVOKABLE void testActiveConnection();
    Q_INVOKABLE void cancelActiveWork();
    Q_INVOKABLE void refreshActiveDatabases();
    Q_INVOKABLE void refreshServices();
    Q_INVOKABLE void startService(const QString &serviceName);

signals:
    void activeConnectionChanged();
    void activeDatabaseChanged();
    void busyChanged();
    void scanningServicesChanged();
    void servicesChanged();
    void operationCompleted(const QString &operation, bool succeeded, const QString &message,
                            const QString &recoveryHint);

private:
    [[nodiscard]] const ConnectionProfile *activeProfile() const;
    void setBusy(bool isBusy);
    void setScanningServices(bool isScanning);
    ConnectionListModel m_connections;
    ServiceListModel m_services;
    DatabaseListModel m_databases;
    SessionCredentialStore m_sessionCredentials;
    CachedSnapshotStore m_snapshotStore;
    StaleResultGate m_resultGate;
    StaleResultGate m_serviceResultGate;
    QUuid m_activeConnectionId;
    QString m_activeDatabaseName;
    bool m_isBusy{false};
    bool m_isScanningServices{false};
};

} // namespace dbtoolkit
