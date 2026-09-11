#pragma once

#include "core/DomainTypes.h"
#include "core/CachedSnapshotStore.h"
#include "core/SessionCredentialStore.h"
#include "core/StaleResultGate.h"
#include "models/ConnectionListModel.h"
#include "models/ColumnListModel.h"
#include "models/DatabaseListModel.h"
#include "models/RowTableModel.h"
#include "models/ServiceListModel.h"
#include "models/TableListModel.h"

#include <QObject>
#include <QVariantMap>

namespace dbtoolkit {

class ApplicationController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QObject *connectionsModel READ connectionsModel CONSTANT)
    Q_PROPERTY(QObject *servicesModel READ servicesModel CONSTANT)
    Q_PROPERTY(QObject *databasesModel READ databasesModel CONSTANT)
    Q_PROPERTY(QObject *tablesModel READ tablesModel CONSTANT)
    Q_PROPERTY(QObject *columnsModel READ columnsModel CONSTANT)
    Q_PROPERTY(QObject *tableDataModel READ tableDataModel CONSTANT)
    Q_PROPERTY(QString activeConnectionId READ activeConnectionId WRITE setActiveConnectionId NOTIFY activeConnectionChanged)
    Q_PROPERTY(QString activeConnectionName READ activeConnectionName NOTIFY activeConnectionChanged)
    Q_PROPERTY(int activeConnectionEngine READ activeConnectionEngine NOTIFY activeConnectionChanged)
    Q_PROPERTY(int activeConnectionPort READ activeConnectionPort NOTIFY activeConnectionChanged)
    Q_PROPERTY(QString activeDatabaseName READ activeDatabaseName WRITE setActiveDatabaseName NOTIFY activeDatabaseChanged)
    Q_PROPERTY(int tableCount READ tableCount NOTIFY tablesChanged)
    Q_PROPERTY(QString activeSchemaName READ activeSchemaName NOTIFY activeTableChanged)
    Q_PROPERTY(QString activeTableName READ activeTableName NOTIFY activeTableChanged)
    Q_PROPERTY(int loadedRowCount READ loadedRowCount NOTIFY tableDataChanged)
    Q_PROPERTY(bool hasMoreRows READ hasMoreRows NOTIFY tableDataChanged)
    Q_PROPERTY(bool hasStableRowOrder READ hasStableRowOrder NOTIFY tableDataChanged)
    Q_PROPERTY(int tablePageNumber READ tablePageNumber NOTIFY tableDataChanged)
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(bool isScanningServices READ isScanningServices NOTIFY scanningServicesChanged)
    Q_PROPERTY(int discoveredServiceCount READ discoveredServiceCount NOTIFY servicesChanged)

public:
    explicit ApplicationController(QObject *parent = nullptr);
    [[nodiscard]] QObject *connectionsModel();
    [[nodiscard]] QObject *servicesModel();
    [[nodiscard]] QObject *databasesModel();
    [[nodiscard]] QObject *tablesModel();
    [[nodiscard]] QObject *columnsModel();
    [[nodiscard]] QObject *tableDataModel();
    [[nodiscard]] QString activeConnectionId() const;
    [[nodiscard]] QString activeConnectionName() const;
    [[nodiscard]] int activeConnectionEngine() const;
    [[nodiscard]] int activeConnectionPort() const;
    [[nodiscard]] QString activeDatabaseName() const;
    [[nodiscard]] int tableCount() const;
    [[nodiscard]] QString activeSchemaName() const;
    [[nodiscard]] QString activeTableName() const;
    [[nodiscard]] int loadedRowCount() const;
    [[nodiscard]] bool hasMoreRows() const;
    [[nodiscard]] bool hasStableRowOrder() const;
    [[nodiscard]] int tablePageNumber() const;
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
                                    const QString &serviceName = {},
                                    const QString &connectionId = {});
    Q_INVOKABLE bool saveAndTestConnection(const QString &displayName, int engine, const QString &host,
                                           int port, const QString &administratorUser,
                                           const QString &administratorPassword,
                                           const QString &maintenanceDatabase = {},
                                           const QString &serviceName = {},
                                           const QString &connectionId = {});
    Q_INVOKABLE QVariantMap connectionDetails(const QString &connectionId) const;
    Q_INVOKABLE void removeConnection(const QString &connectionId);
    Q_INVOKABLE void removeActiveConnection();
    Q_INVOKABLE void testActiveConnection();
    Q_INVOKABLE void cancelActiveWork();
    Q_INVOKABLE void refreshActiveDatabases();
    Q_INVOKABLE bool openDatabase(const QString &databaseName);
    Q_INVOKABLE void refreshActiveTables();
    Q_INVOKABLE bool openTable(const QString &schemaName, const QString &tableName);
    Q_INVOKABLE void refreshActiveTable();
    Q_INVOKABLE void previousTablePage();
    Q_INVOKABLE void nextTablePage();
    Q_INVOKABLE void copyTableCell(int row, int column);
    Q_INVOKABLE void refreshServices();
    Q_INVOKABLE void startService(const QString &serviceName);

signals:
    void activeConnectionChanged();
    void activeDatabaseChanged();
    void tablesChanged();
    void activeTableChanged();
    void tableDataChanged();
    void busyChanged();
    void scanningServicesChanged();
    void servicesChanged();
    void operationCompleted(const QString &operation, bool succeeded, const QString &message,
                            const QString &recoveryHint);

private:
    [[nodiscard]] const ConnectionProfile *activeProfile() const;
    void testConnection(const QUuid &connectionId, bool discardIfTestFails);
    void setBusy(bool isBusy);
    void setScanningServices(bool isScanning);
    void clearActiveTable();
    void clearTableData();
    ConnectionListModel m_connections;
    ServiceListModel m_services;
    DatabaseListModel m_databases;
    TableListModel m_tables;
    ColumnListModel m_columns;
    RowTableModel m_tableData;
    SessionCredentialStore m_sessionCredentials;
    CachedSnapshotStore m_snapshotStore;
    StaleResultGate m_resultGate;
    StaleResultGate m_serviceResultGate;
    QUuid m_activeConnectionId;
    QString m_activeDatabaseName;
    QString m_activeSchemaName;
    QString m_activeTableName;
    bool m_hasMoreRows{false};
    bool m_hasStableRowOrder{false};
    int m_tablePageNumber{0};
    bool m_isBusy{false};
    bool m_isScanningServices{false};
};

} // namespace dbtoolkit
