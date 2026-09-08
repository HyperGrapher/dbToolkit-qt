#include "controllers/ApplicationController.h"

#include "core/DatabaseDriver.h"

#include <QMetaObject>
#include <QMetaType>
#include <QPointer>
#include <QThreadPool>

#include <utility>

namespace dbtoolkit {

ApplicationController::ApplicationController(QObject *parent)
    : QObject(parent), m_connections(this), m_services(this), m_databases(this), m_resultGate(this)
{
    qRegisterMetaType<OperationResult>();
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

QString ApplicationController::activeDatabaseName() const
{
    return m_activeDatabaseName;
}

bool ApplicationController::isBusy() const
{
    return m_isBusy;
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

void ApplicationController::testActiveConnection(const QString &administratorPassword)
{
    const ConnectionProfile *profile = activeProfile();
    if (profile == nullptr) {
        emit operationCompleted("testConnection", false, "Choose a saved connection first.", {});
        return;
    }
    const quint64 token = m_resultGate.beginWork();
    const ConnectionProfile profileCopy = *profile;
    ConnectionCredentials credentials;
    credentials.administratorPassword = administratorPassword;
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
        QMetaObject::invokeMethod(controller.data(), [controller, token, result]() {
            if (controller.isNull() || !controller->m_resultGate.isCurrent(token)) {
                return;
            }
            controller->setBusy(false);
            controller->operationCompleted("testConnection", result.isSuccess(), result.message,
                                           result.recoveryHint);
        }, Qt::QueuedConnection);
    });
}

void ApplicationController::cancelActiveWork()
{
    m_resultGate.invalidate();
    setBusy(false);
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

} // namespace dbtoolkit
