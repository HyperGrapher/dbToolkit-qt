#include "services/WindowsDatabaseService.h"

#include <QCoreApplication>
#include <QFileInfo>
#include <QThread>

#ifdef Q_OS_WIN
#include <windows.h>
#include <shellapi.h>

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

std::optional<DatabaseEngine> classifyService(const QString &commandLine, const QString &serviceName,
                                              const QString &displayName)
{
    const QString executablePath = executableFromCommand(commandLine);
    const QString fileName = QFileInfo(executablePath).fileName().toLower();
    const QString identity = (commandLine + ' ' + serviceName + ' ' + displayName).toLower();
    if (fileName == "postgres.exe" || fileName == "postmaster.exe" ||
        fileName == "pg_ctl.exe" || fileName == "postgresql.exe" ||
        identity.contains("postgres")) {
        return DatabaseEngine::PostgreSql;
    }
    if (fileName != "mysqld.exe") {
        return std::nullopt;
    }

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

QString queryServiceCommand(SC_HANDLE service)
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
    return QString::fromWCharArray(config->lpBinaryPathName);
}

OperationResult startDirect(const QString &serviceName)
{
    const ServiceHandle manager(OpenSCManagerW(nullptr, nullptr, SC_MANAGER_CONNECT));
    if (!manager) {
        return OperationResult::failure("Windows Service Manager is unavailable.",
                                        windowsErrorMessage(GetLastError()));
    }
    const std::wstring nativeName = serviceName.toStdWString();
    const ServiceHandle service(OpenServiceW(manager.get(), nativeName.c_str(),
                                             SERVICE_QUERY_CONFIG | SERVICE_QUERY_STATUS | SERVICE_START));
    if (!service) {
        const DWORD error = GetLastError();
        return OperationResult::failure(
            "The database service could not be opened.",
            error == ERROR_ACCESS_DENIED ? "DBTOOLKIT_ACCESS_DENIED" : windowsErrorMessage(error));
    }

    const QString commandLine = queryServiceCommand(service.get());
    if (!classifyService(commandLine, serviceName, {}).has_value()) {
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
        return OperationResult::failure(
            "The database service could not be started.",
            error == ERROR_ACCESS_DENIED ? "DBTOOLKIT_ACCESS_DENIED" : windowsErrorMessage(error));
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
}

OperationResult startWithElevation(const QString &serviceName)
{
    if (serviceName.contains('"') || serviceName.contains('\r') || serviceName.contains('\n')) {
        return OperationResult::failure("The Windows service name is invalid.");
    }

    const QString applicationPath = QCoreApplication::applicationFilePath();
    if (applicationPath.isEmpty()) {
        return OperationResult::failure("Could not locate the application for elevated service control.");
    }
    const QString parameters = "--dbtoolkit-start-service \"" + serviceName + "\"";
    SHELLEXECUTEINFOW request{};
    request.cbSize = sizeof(request);
    request.fMask = SEE_MASK_NOCLOSEPROCESS;
    request.lpVerb = L"runas";
    request.lpFile = reinterpret_cast<const wchar_t *>(applicationPath.utf16());
    request.lpParameters = reinterpret_cast<const wchar_t *>(parameters.utf16());
    request.nShow = SW_HIDE;
    if (!ShellExecuteExW(&request)) {
        const DWORD error = GetLastError();
        const QString hint = error == ERROR_CANCELLED ? "Elevation was cancelled."
                                                    : windowsErrorMessage(error);
        return OperationResult::failure("Windows could not elevate database service control.", hint);
    }

    const DWORD waitResult = WaitForSingleObject(request.hProcess, 60000);
    if (waitResult != WAIT_OBJECT_0) {
        CloseHandle(request.hProcess);
        return OperationResult::failure("The elevated service operation did not finish in time.");
    }
    DWORD exitCode = 1;
    GetExitCodeProcess(request.hProcess, &exitCode);
    CloseHandle(request.hProcess);
    return exitCode == 0 ? OperationResult::success("Database service started with elevation.")
                         : OperationResult::failure("The elevated database service operation failed.",
                                                    "Check Windows Services for the service-specific error.");
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

    DWORD resumeHandle = 0;
    QList<ServiceSummary> services;
    do {
        DWORD bytesNeeded = 0;
        DWORD serviceCount = 0;
        EnumServicesStatusExW(manager.get(), SC_ENUM_PROCESS_INFO, SERVICE_WIN32,
                              SERVICE_STATE_ALL, nullptr, 0, &bytesNeeded, &serviceCount,
                              &resumeHandle, nullptr);
        if (GetLastError() != ERROR_MORE_DATA || bytesNeeded == 0) {
            break;
        }

        std::vector<std::byte> buffer(bytesNeeded);
        const BOOL succeeded = EnumServicesStatusExW(
            manager.get(), SC_ENUM_PROCESS_INFO, SERVICE_WIN32, SERVICE_STATE_ALL,
            reinterpret_cast<LPBYTE>(buffer.data()), bytesNeeded, &bytesNeeded, &serviceCount,
            &resumeHandle, nullptr);
        if (!succeeded && GetLastError() != ERROR_MORE_DATA) {
            break;
        }

        const auto *entries = reinterpret_cast<const ENUM_SERVICE_STATUS_PROCESSW *>(buffer.data());
        for (DWORD index = 0; index < serviceCount; ++index) {
            const QString serviceName = QString::fromWCharArray(entries[index].lpServiceName);
            const QString displayName = QString::fromWCharArray(entries[index].lpDisplayName);
            const ServiceHandle service(OpenServiceW(manager.get(), entries[index].lpServiceName,
                                                     SERVICE_QUERY_CONFIG));
            const QString commandLine = service ? queryServiceCommand(service.get()) : QString{};
            const auto engine = classifyService(commandLine, serviceName, displayName);
            if (!engine.has_value()) {
                continue;
            }

            ServiceSummary summary;
            summary.serviceName = serviceName;
            summary.displayName = displayName;
            summary.executablePath = executableFromCommand(commandLine);
            summary.engine = *engine;
            summary.port = *engine == DatabaseEngine::PostgreSql ? 5432 : 3306;
            summary.state = serviceState(entries[index].ServiceStatusProcess.dwCurrentState);
            summary.observedAt = QDateTime::currentDateTime();
            services.append(std::move(summary));
        }
    } while (resumeHandle != 0);
    return services;
#else
    return {};
#endif
}

OperationResult WindowsDatabaseService::start(const QString &serviceName)
{
#ifdef Q_OS_WIN
    const OperationResult directResult = startDirect(serviceName);
    if (directResult.isSuccess() || directResult.recoveryHint != "DBTOOLKIT_ACCESS_DENIED") {
        return directResult;
    }
    return startWithElevation(serviceName);
#else
    Q_UNUSED(serviceName)
    return OperationResult::unsupported("Windows service control is unavailable on this platform.");
#endif
}

OperationResult WindowsDatabaseService::startElevatedHelper(const QString &serviceName)
{
#ifdef Q_OS_WIN
    return startDirect(serviceName);
#else
    Q_UNUSED(serviceName)
    return OperationResult::unsupported("Windows service control is unavailable on this platform.");
#endif
}

} // namespace dbtoolkit
