#include "core/CachedSnapshotStore.h"

#include <utility>

namespace dbtoolkit {

void CachedSnapshotStore::replace(CachedDatabaseSnapshot snapshot)
{
    m_snapshots.insert(snapshot.connectionId, std::move(snapshot));
}

CachedDatabaseSnapshot CachedSnapshotStore::snapshotFor(const QUuid &connectionId) const
{
    return m_snapshots.value(connectionId);
}

void CachedSnapshotStore::remove(const QUuid &connectionId)
{
    m_snapshots.remove(connectionId);
}

void CachedSnapshotStore::clear()
{
    m_snapshots.clear();
}

} // namespace dbtoolkit
