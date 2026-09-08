#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setApplicationName("dbToolKit");
    QCoreApplication::setOrganizationName("dbToolKit");
    QCoreApplication::setApplicationVersion("0.1.0");
    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;

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
