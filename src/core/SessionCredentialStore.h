#pragma once

#include "core/DomainTypes.h"

#include <QHash>

namespace dbtoolkit {

class SessionCredentialStore final {
public:
    SessionCredentialStore() = default;
    ~SessionCredentialStore();

    SessionCredentialStore(const SessionCredentialStore &) = delete;
    SessionCredentialStore &operator=(const SessionCredentialStore &) = delete;

    void store(const QUuid &connectionId, ConnectionCredentials credentials);
    [[nodiscard]] ConnectionCredentials credentialsFor(const QUuid &connectionId) const;
    void remove(const QUuid &connectionId);
    void clear();

private:
    static void clearSecrets(ConnectionCredentials &credentials);
    QHash<QUuid, ConnectionCredentials> m_credentials;
};

} // namespace dbtoolkit
