#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include "controllers/ApplicationController.h"
#include "services/WindowsDatabaseService.h"

#ifdef Q_OS_WIN
#include <QString>
#endif

int main(int argc, char *argv[])
{
#ifdef Q_OS_WIN
    if (argc == 3 && QString::fromLocal8Bit(argv[1]) == "--dbtoolkit-start-service") {
        return dbtoolkit::WindowsDatabaseService::startElevatedHelper(
                   QString::fromLocal8Bit(argv[2])).isSuccess()
                   ? 0
                   : 1;
    }
#endif
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName("dbToolKit");
    QCoreApplication::setOrganizationName("dbToolKit");
    QCoreApplication::setApplicationVersion("0.1.0");
    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;
    dbtoolkit::ApplicationController applicationController;
    engine.rootContext()->setContextProperty("applicationController", &applicationController);

    // Exit application if QML fails to load
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    // Load Main.qml from the registered QML module
    engine.loadFromModule("DbToolKit", "Main");

    return app.exec();
}
