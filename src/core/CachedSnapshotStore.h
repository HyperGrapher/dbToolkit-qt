#pragma once

#include "core/DomainTypes.h"

#include <QHash>

namespace dbtoolkit {

class CachedSnapshotStore final {
public:
    void replace(CachedDatabaseSnapshot snapshot);
    [[nodiscard]] CachedDatabaseSnapshot snapshotFor(const QUuid &connectionId) const;
    void remove(const QUuid &connectionId);
    void clear();

private:
    QHash<QUuid, CachedDatabaseSnapshot> m_snapshots;
};

} // namespace dbtoolkit
