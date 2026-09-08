#include "services/WindowsDatabaseService.h"

#include <QFileInfo>
#include <QThread>

#ifdef Q_OS_WIN
#include <windows.h>

#include <cstddef>
#include <memory>
#include <optional>
#include <string>
#include <type_traits>
#include <vector>
#endif

namespace dbtoolkit {

#ifdef Q_OS_WIN
namespace {

struct ServiceHandleCloser {
    void operator()(SC_HANDLE handle) const
    {
        if (handle != nullptr) {
            CloseServiceHandle(handle);
        }
    }
};

using ServiceHandle = std::unique_ptr<std::remove_pointer_t<SC_HANDLE>, ServiceHandleCloser>;

QString windowsErrorMessage(DWORD error)
{
    wchar_t *buffer = nullptr;
    const DWORD length = FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
                                            FORMAT_MESSAGE_IGNORE_INSERTS,
                                        nullptr, error, 0, reinterpret_cast<wchar_t *>(&buffer), 0,
                                        nullptr);
    const QString message = length > 0 ? QString::fromWCharArray(buffer, static_cast<qsizetype>(length)).trimmed()
                                       : QString("Windows error %1").arg(error);
    if (buffer != nullptr) {
        LocalFree(buffer);
    }
    return message;
}

QString executableFromCommand(const QString &command)
{
    QString expanded = command.trimmed();
    if (expanded.contains('%')) {
        std::vector<wchar_t> output(32768);
        const DWORD length = ExpandEnvironmentStringsW(reinterpret_cast<const wchar_t *>(expanded.utf16()),
                                                       output.data(), static_cast<DWORD>(output.size()));
        if (length > 0 && length < output.size()) {
            expanded = QString::fromWCharArray(output.data());
        }
    }

    if (expanded.startsWith('"')) {
        const qsizetype closingQuote = expanded.indexOf('"', 1);
        return closingQuote > 1 ? expanded.sliced(1, closingQuote - 1) : QString{};
    }

    const qsizetype firstSpace = expanded.indexOf(' ');
    return firstSpace < 0 ? expanded : expanded.first(firstSpace);
}

std::optional<DatabaseEngine> classifyExecutable(const QString &executablePath,
                                                 const QString &serviceName,
                                                 const QString &displayName)
{
    const QString fileName = QFileInfo(executablePath).fileName().toLower();
    if (fileName == "postgres.exe" || fileName == "postmaster.exe") {
        return DatabaseEngine::PostgreSql;
    }
    if (fileName != "mysqld.exe") {
        return std::nullopt;
    }

    const QString identity = (executablePath + ' ' + serviceName + ' ' + displayName).toLower();
    return identity.contains("mariadb") ? DatabaseEngine::MariaDb : DatabaseEngine::MySql;
}

ServiceState serviceState(DWORD state)
{
    switch (state) {
    case SERVICE_RUNNING:
        return ServiceState::Running;
    case SERVICE_STOPPED:
        return ServiceState::Stopped;
    case SERVICE_START_PENDING:
    case SERVICE_STOP_PENDING:
    case SERVICE_CONTINUE_PENDING:
    case SERVICE_PAUSE_PENDING:
        return ServiceState::Pending;
    default:
        return ServiceState::Unavailable;
    }
}

QString queryExecutablePath(SC_HANDLE service)
{
    DWORD bytesNeeded = 0;
    QueryServiceConfigW(service, nullptr, 0, &bytesNeeded);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER || bytesNeeded == 0) {
        return {};
    }
    std::vector<std::byte> buffer(bytesNeeded);
    auto *config = reinterpret_cast<QUERY_SERVICE_CONFIGW *>(buffer.data());
    if (!QueryServiceConfigW(service, config, bytesNeeded, &bytesNeeded)) {
        return {};
    }
    return executableFromCommand(QString::fromWCharArray(config->lpBinaryPathName));
}

} // namespace
#endif

QList<ServiceSummary> WindowsDatabaseService::discover()
{
#ifdef Q_OS_WIN
    const ServiceHandle manager(OpenSCManagerW(nullptr, nullptr, SC_MANAGER_ENUMERATE_SERVICE));
    if (!manager) {
        return {};
    }

    DWORD bytesNeeded = 0;
    DWORD serviceCount = 0;
    DWORD resumeHandle = 0;
    EnumServicesStatusExW(manager.get(), SC_ENUM_PROCESS_INFO, SERVICE_WIN32_OWN_PROCESS,
                          SERVICE_STATE_ALL, nullptr, 0, &bytesNeeded, &serviceCount,
                          &resumeHandle, nullptr);
    if (GetLastError() != ERROR_MORE_DATA || bytesNeeded == 0) {
        return {};
    }

    std::vector<std::byte> buffer(bytesNeeded);
    if (!EnumServicesStatusExW(manager.get(), SC_ENUM_PROCESS_INFO, SERVICE_WIN32_OWN_PROCESS,
                               SERVICE_STATE_ALL, reinterpret_cast<LPBYTE>(buffer.data()), bytesNeeded,
                               &bytesNeeded, &serviceCount, &resumeHandle, nullptr)) {
        return {};
    }

    QList<ServiceSummary> services;
    const auto *entries = reinterpret_cast<const ENUM_SERVICE_STATUS_PROCESSW *>(buffer.data());
    for (DWORD index = 0; index < serviceCount; ++index) {
        const QString serviceName = QString::fromWCharArray(entries[index].lpServiceName);
        const QString displayName = QString::fromWCharArray(entries[index].lpDisplayName);
        const ServiceHandle service(OpenServiceW(manager.get(), entries[index].lpServiceName,
                                                 SERVICE_QUERY_CONFIG));
        if (!service) {
            continue;
        }
        const QString executablePath = queryExecutablePath(service.get());
        const auto engine = classifyExecutable(executablePath, serviceName, displayName);
        if (!engine.has_value()) {
            continue;
        }

        ServiceSummary summary;
        summary.serviceName = serviceName;
        summary.displayName = displayName;
        summary.executablePath = executablePath;
        summary.engine = *engine;
        summary.port = *engine == DatabaseEngine::PostgreSql ? 5432 : 3306;
        summary.state = serviceState(entries[index].ServiceStatusProcess.dwCurrentState);
        summary.observedAt = QDateTime::currentDateTime();
        services.append(std::move(summary));
    }
    return services;
#else
    return {};
#endif
}

OperationResult WindowsDatabaseService::start(const QString &serviceName)
{
#ifdef Q_OS_WIN
    const ServiceHandle manager(OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT));
    if (!manager) {
        return OperationResult::failure("Windows Service Manager is unavailable.",
                                        windowsErrorMessage(GetLastError()));
    }
    const std::wstring nativeName = serviceName.toStdWString();
    const ServiceHandle service(OpenServiceW(manager.get(), nativeName.c_str(),
                                             SERVICE_QUERY_CONFIG | SERVICE_QUERY_STATUS | SERVICE_START));
    if (!service) {
        return OperationResult::failure("The database service could not be opened.",
                                        windowsErrorMessage(GetLastError()));
    }

    const QString executablePath = queryExecutablePath(service.get());
    if (!classifyExecutable(executablePath, serviceName, {}).has_value()) {
        return OperationResult::failure("The selected Windows service is not a supported database service.");
    }

    SERVICE_STATUS_PROCESS status{};
    DWORD bytesNeeded = 0;
    if (QueryServiceStatusEx(service.get(), SC_STATUS_PROCESS_INFO,
                             reinterpret_cast<LPBYTE>(&status), sizeof(status), &bytesNeeded) &&
        status.dwCurrentState == SERVICE_RUNNING) {
        return OperationResult::success("The database service is already running.");
    }
    if (!StartServiceW(service.get(), 0, nullptr)) {
        const DWORD error = GetLastError();
        const QString hint = error == ERROR_ACCESS_DENIED
                                 ? "Windows denied permission. Service elevation support will be added next."
                                 : windowsErrorMessage(error);
        return OperationResult::failure("The database service could not be started.", hint);
    }

    for (int attempt = 0; attempt < 50; ++attempt) {
        QThread::msleep(100);
        if (!QueryServiceStatusEx(service.get(), SC_STATUS_PROCESS_INFO,
                                  reinterpret_cast<LPBYTE>(&status), sizeof(status), &bytesNeeded)) {
            break;
        }
        if (status.dwCurrentState == SERVICE_RUNNING) {
            return OperationResult::success("Database service started.");
        }
        if (status.dwCurrentState == SERVICE_STOPPED) {
            break;
        }
    }
    return OperationResult::failure("The database service did not reach the running state.",
                                    "Check Windows Services for the service-specific error.");
#else
    Q_UNUSED(serviceName)
    return OperationResult::unsupported("Windows service control is unavailable on this platform.");
#endif
}

} // namespace dbtoolkit
