#include "core/StaleResultGate.h"

namespace dbtoolkit {

StaleResultGate::StaleResultGate(QObject *parent)
    : QObject(parent)
{
}

quint64 StaleResultGate::beginWork()
{
    return ++m_generation;
}

void StaleResultGate::invalidate()
{
    ++m_generation;
}

bool StaleResultGate::isCurrent(quint64 token) const
{
    return token == m_generation;
}

} // namespace dbtoolkit
