#include "core/DomainTypes.h"

#include <utility>

namespace dbtoolkit {

OperationResult OperationResult::success(QString message)
{
    return {.status = OperationStatus::Succeeded, .message = std::move(message)};
}

OperationResult OperationResult::failure(QString message, QString recoveryHint)
{
    return {.status = OperationStatus::Failed,
            .message = std::move(message),
            .recoveryHint = std::move(recoveryHint)};
}

OperationResult OperationResult::unsupported(QString message)
{
    return {.status = OperationStatus::Unsupported, .message = std::move(message)};
}

} // namespace dbtoolkit
