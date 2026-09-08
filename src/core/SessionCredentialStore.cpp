#include "core/SessionCredentialStore.h"

#include <utility>

namespace dbtoolkit {

SessionCredentialStore::~SessionCredentialStore()
{
    clear();
}

void SessionCredentialStore::store(const QUuid &connectionId, ConnectionCredentials credentials)
{
    remove(connectionId);
    m_credentials.insert(connectionId, std::move(credentials));
}

ConnectionCredentials SessionCredentialStore::credentialsFor(const QUuid &connectionId) const
{
    return m_credentials.value(connectionId);
}

void SessionCredentialStore::remove(const QUuid &connectionId)
{
    auto credentials = m_credentials.find(connectionId);
    if (credentials == m_credentials.end()) {
        return;
    }

    clearSecrets(credentials.value());
    m_credentials.erase(credentials);
}

void SessionCredentialStore::clear()
{
    for (auto &credentials : m_credentials) {
        clearSecrets(credentials);
    }
    m_credentials.clear();
}

void SessionCredentialStore::clearSecrets(ConnectionCredentials &credentials)
{
    credentials.administratorPassword.fill(u'\0');
    credentials.projectPassword.fill(u'\0');
    credentials.administratorPassword.clear();
    credentials.projectPassword.clear();
    credentials.projectUser.clear();
}

} // namespace dbtoolkit
