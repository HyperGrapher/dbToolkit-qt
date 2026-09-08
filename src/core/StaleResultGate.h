#pragma once

#include <QObject>

namespace dbtoolkit {

class StaleResultGate final : public QObject {
    Q_OBJECT

public:
    explicit StaleResultGate(QObject *parent = nullptr);

    [[nodiscard]] quint64 beginWork();
    void invalidate();
    [[nodiscard]] bool isCurrent(quint64 token) const;

private:
    quint64 m_generation{0};
};

} // namespace dbtoolkit
