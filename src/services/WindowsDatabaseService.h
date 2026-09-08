#pragma once

#include "core/DomainTypes.h"

namespace dbtoolkit {

class WindowsDatabaseService final {
public:
    [[nodiscard]] static QList<ServiceSummary> discover();
    [[nodiscard]] static OperationResult start(const QString &serviceName);
};

} // namespace dbtoolkit
