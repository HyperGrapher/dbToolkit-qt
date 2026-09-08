#include "controllers/ApplicationController.h"

#include "core/DatabaseDriver.h"
#include "services/WindowsDatabaseService.h"

#include <QMetaObject>
#include <QMetaType>
#include <QPointer>
#include <QThreadPool>

#include <utility>

namespace dbtoolkit {

ApplicationController::ApplicationController(QObject *parent)
    : QObject(parent)
    , m_connections(this)
    , m_services(this)
    , m_databases(this)
    , m_resultGate(this)
    , m_serviceResultGate(this)
{
    qRegisterMetaType<OperationResult>();
    QMetaObject::invokeMethod(this, &ApplicationController::refreshServices, Qt::QueuedConnection);
}

QObject *ApplicationController::connectionsModel()
{
    return &m_connections;
}

QObject *ApplicationController::servicesModel()
{
    return &m_services;
}

QObject *ApplicationController::databasesModel()
{
    return &m_databases;
}

QString ApplicationController::activeConnectionId() const
{
    return m_activeConnectionId.toString(QUuid::WithoutBraces);
}

QString ApplicationController::activeConnectionName() const
{
    const ConnectionProfile *profile = activeProfile();
    return profile == nullptr ? QString{} : profile->displayName;
}

int ApplicationController::activeConnectionEngine() const
{
    const ConnectionProfile *profile = activeProfile();
    return profile == nullptr ? -1 : static_cast<int>(profile->engine);
}

int ApplicationController::activeConnectionPort() const
{
    const ConnectionProfile *profile = activeProfile();
    return profile == nullptr ? 0 : profile->port;
}

QString ApplicationController::activeDatabaseName() const
{
    return m_activeDatabaseName;
}

bool ApplicationController::isBusy() const
{
    return m_isBusy;
}

bool ApplicationController::isScanningServices() const
{
    return m_isScanningServices;
}

int ApplicationController::discoveredServiceCount() const
{
    return m_services.rowCount();
}

void ApplicationController::setSessionProfiles(QList<ConnectionProfile> profiles)
{
    m_connections.replaceProfiles(std::move(profiles));
}

void ApplicationController::setActiveConnectionId(const QString &connectionId)
{
    const QUuid nextConnectionId(connectionId);
    if (m_activeConnectionId == nextConnectionId) {
        return;
    }
    m_resultGate.invalidate();
    m_activeConnectionId = nextConnectionId;
    m_activeDatabaseName.clear();
    m_databases.clear();
    emit activeConnectionChanged();
    emit activeDatabaseChanged();
}

void ApplicationController::setActiveDatabaseName(const QString &databaseName)
{
    if (m_activeDatabaseName == databaseName) {
        return;
    }
    m_resultGate.invalidate();
    m_activeDatabaseName = databaseName;
    emit activeDatabaseChanged();
}

bool ApplicationController::saveConnection(const QString &displayName, int engine, const QString &host,
                                           int port, const QString &administratorUser,
                                           const QString &administratorPassword,
                                           const QString &maintenanceDatabase,
                                           const QString &serviceName,
                                           const QString &connectionId)
{
    if (displayName.trimmed().isEmpty() || host.trimmed().isEmpty() || administratorUser.trimmed().isEmpty() ||
        port < 1 || port > 65535 || engine < static_cast<int>(DatabaseEngine::PostgreSql) ||
        engine > static_cast<int>(DatabaseEngine::MariaDb)) {
        emit operationCompleted("saveConnection", false,
                                "Enter a connection name, host, port, and administrator username.", {});
        return false;
    }

    ConnectionProfile profile;
    const QUuid existingId(connectionId);
    const ConnectionProfile *existingProfile = m_connections.profile(existingId);
    if (existingProfile != nullptr) {
        profile = *existingProfile;
    }
    profile.displayName = displayName.trimmed();
    profile.engine = static_cast<DatabaseEngine>(engine);
    profile.host = host.trimmed();
    profile.port = static_cast<quint16>(port);
    profile.administratorUser = administratorUser.trimmed();
    profile.maintenanceDatabase = maintenanceDatabase.trimmed();
    profile.serviceName = serviceName.trimmed();
    if (profile.maintenanceDatabase.isEmpty() && profile.engine == DatabaseEngine::PostgreSql) {
        profile.maintenanceDatabase = "postgres";
    }

    ConnectionCredentials credentials = m_sessionCredentials.credentialsFor(profile.id);
    if (!administratorPassword.isEmpty()) {
        credentials.administratorPassword = administratorPassword;
    }
    m_sessionCredentials.store(profile.id, std::move(credentials));
    m_connections.upsertProfile(profile);
    setActiveConnectionId(profile.id.toString(QUuid::WithoutBraces));
    emit operationCompleted("saveConnection", true,
                            "Connection saved for this app session. It will be encrypted and persisted with P04.", {});
    return true;
}

QVariantMap ApplicationController::connectionDetails(const QString &connectionId) const
{
    const ConnectionProfile *profile = m_connections.profile(QUuid(connectionId));
    if (profile == nullptr) {
        return {};
    }
    return {{"connectionId", profile->id.toString(QUuid::WithoutBraces)},
            {"displayName", profile->displayName},
            {"engine", static_cast<int>(profile->engine)},
            {"host", profile->host},
            {"port", profile->port},
            {"administratorUser", profile->administratorUser},
            {"maintenanceDatabase", profile->maintenanceDatabase},
            {"serviceName", profile->serviceName}};
}

void ApplicationController::removeConnection(const QString &connectionId)
{
    const QUuid id(connectionId);
    if (id.isNull() || !m_connections.removeProfile(id)) {
        emit operationCompleted("removeConnection", false, "The selected connection no longer exists.", {});
        return;
    }
    m_sessionCredentials.remove(id);
    if (m_activeConnectionId == id) {
        setActiveConnectionId({});
    }
    emit operationCompleted("removeConnection", true, "Connection removed from this app session.", {});
}

void ApplicationController::removeActiveConnection()
{
    if (m_activeConnectionId.isNull()) {
        return;
    }

    m_sessionCredentials.remove(m_activeConnectionId);
    m_connections.removeProfile(m_activeConnectionId);
    setActiveConnectionId({});
}

void ApplicationController::testActiveConnection()
{
    const ConnectionProfile *profile = activeProfile();
    if (profile == nullptr) {
        emit operationCompleted("testConnection", false, "Choose a saved connection first.", {});
        return;
    }
    const quint64 token = m_resultGate.beginWork();
    const ConnectionProfile profileCopy = *profile;
    ConnectionCredentials credentials = m_sessionCredentials.credentialsFor(profile->id);
    if (credentials.administratorPassword.isEmpty()) {
        emit operationCompleted("testConnection", false,
                                "Enter an administrator password before testing this connection.", {});
        return;
    }
    setBusy(true);
    QPointer<ApplicationController> controller(this);
    QThreadPool::globalInstance()->start([controller, token, profileCopy, credentials = std::move(credentials)]() mutable {
        const auto driver = createDatabaseDriver(profileCopy.engine);
        const OperationResult result = driver->testConnection(profileCopy, credentials);
        credentials.administratorPassword.fill(u'\0');
        credentials.administratorPassword.clear();
        if (controller.isNull()) {
            return;
        }
        QMetaObject::invokeMethod(controller.data(), [controller, token, profileId = profileCopy.id, result]() {
            if (controller.isNull() || !controller->m_resultGate.isCurrent(token)) {
                return;
            }
            controller->setBusy(false);
            controller->m_connections.setTestResult(profileId, result.isSuccess(), QDateTime::currentDateTime());
            controller->operationCompleted("testConnection", result.isSuccess(), result.message,
                                           result.recoveryHint);
            if (result.isSuccess()) {
                controller->refreshActiveDatabases();
            }
        }, Qt::QueuedConnection);
    });
}

void ApplicationController::cancelActiveWork()
{
    m_resultGate.invalidate();
    setBusy(false);
}

void ApplicationController::refreshActiveDatabases()
{
    const ConnectionProfile *profile = activeProfile();
    if (profile == nullptr) {
        emit operationCompleted("refreshDatabases", false, "Choose a saved connection first.", {});
        return;
    }

    const ConnectionProfile profileCopy = *profile;
    ConnectionCredentials credentials = m_sessionCredentials.credentialsFor(profileCopy.id);
    if (credentials.administratorPassword.isEmpty()) {
        emit operationCompleted("refreshDatabases", false,
                                "Enter an administrator password before loading databases.", {});
        return;
    }
    const quint64 token = m_resultGate.beginWork();
    setBusy(true);
    QPointer<ApplicationController> controller(this);
    QThreadPool::globalInstance()->start([controller, token, profileCopy, credentials = std::move(credentials)]() mutable {
        const auto driver = createDatabaseDriver(profileCopy.engine);
        DatabaseListResult result = driver->listDatabases(profileCopy, credentials);
        credentials.administratorPassword.fill(u'\0');
        credentials.administratorPassword.clear();
        if (controller.isNull()) {
            return;
        }
        QMetaObject::invokeMethod(controller.data(), [controller, token, profileId = profileCopy.id,
                                                       result = std::move(result)]() mutable {
            if (controller.isNull() || !controller->m_resultGate.isCurrent(token) ||
                controller->m_activeConnectionId != profileId) {
                return;
            }
            controller->setBusy(false);
            if (result.operation.isSuccess()) {
                CachedDatabaseSnapshot snapshot;
                snapshot.connectionId = profileId;
                snapshot.databases = result.databases;
                snapshot.refreshedAt = QDateTime::currentDateTime();
                snapshot.serverVersion = result.serverVersion;
                controller->m_snapshotStore.replace(std::move(snapshot));
                controller->m_databases.replaceDatabases(std::move(result.databases));
            }
            controller->operationCompleted("refreshDatabases", result.operation.isSuccess(),
                                           result.operation.message, result.operation.recoveryHint);
        }, Qt::QueuedConnection);
    });
}

void ApplicationController::refreshServices()
{
    const quint64 token = m_serviceResultGate.beginWork();
    setScanningServices(true);
    QPointer<ApplicationController> controller(this);
    QThreadPool::globalInstance()->start([controller, token]() {
        QList<ServiceSummary> services = WindowsDatabaseService::discover();
        if (controller.isNull()) {
            return;
        }
        QMetaObject::invokeMethod(controller.data(), [controller, token, services = std::move(services)]() mutable {
            if (controller.isNull() || !controller->m_serviceResultGate.isCurrent(token)) {
                return;
            }
            controller->m_services.replaceServices(std::move(services));
            controller->setScanningServices(false);
            emit controller->servicesChanged();
        }, Qt::QueuedConnection);
    });
}

void ApplicationController::startService(const QString &serviceName)
{
    if (serviceName.trimmed().isEmpty()) {
        emit operationCompleted("startService", false, "Choose a discovered database service first.", {});
        return;
    }

    const quint64 token = m_serviceResultGate.beginWork();
    setScanningServices(true);
    QPointer<ApplicationController> controller(this);
    QThreadPool::globalInstance()->start([controller, token, serviceName]() {
        const OperationResult result = WindowsDatabaseService::start(serviceName);
        if (controller.isNull()) {
            return;
        }
        QMetaObject::invokeMethod(controller.data(), [controller, token, result]() {
            if (controller.isNull() || !controller->m_serviceResultGate.isCurrent(token)) {
                return;
            }
            controller->setScanningServices(false);
            emit controller->operationCompleted("startService", result.isSuccess(), result.message,
                                                result.recoveryHint);
            controller->refreshServices();
        }, Qt::QueuedConnection);
    });
}

const ConnectionProfile *ApplicationController::activeProfile() const
{
    return m_connections.profile(m_activeConnectionId);
}

void ApplicationController::setBusy(bool isBusy)
{
    if (m_isBusy == isBusy) {
        return;
    }
    m_isBusy = isBusy;
    emit busyChanged();
}

void ApplicationController::setScanningServices(bool isScanning)
{
    if (m_isScanningServices == isScanning) {
        return;
    }
    m_isScanningServices = isScanning;
    emit scanningServicesChanged();
}

} // namespace dbtoolkit
