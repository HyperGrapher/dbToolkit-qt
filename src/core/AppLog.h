#pragma once

#include <QString>

namespace dbtoolkit {

class AppLog final {
public:
    static void initialize();
    static void operation(const QString &operation, bool succeeded, const QString &message,
                          const QString &recoveryHint);
};

} // namespace dbtoolkit
