#pragma once
#include "core/DomainTypes.h"

namespace dbtoolkit {
struct StoredConnection {
    ConnectionProfile profile;
    ConnectionCredentials credentials;
};
class ProtectedConnections final {
public:
    static OperationResult save(const StoredConnection &connection);
    static QList<StoredConnection> load();
    static bool remove(const QUuid &id);
};
}
