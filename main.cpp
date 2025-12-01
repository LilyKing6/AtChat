#include "LicenseManager.h"
#include "NetworkManager.h"
#include "AppInfo.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("AtChat");
    app.setApplicationName("AtChat");

    qmlRegisterSingletonType<LicenseManager>("AtChat", 1, 0, "LicenseManager",
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return new LicenseManager();
        });

    qmlRegisterSingletonType<NetworkManager>("AtChat", 1, 0, "NetworkManager",
        NetworkManager::create);

    qmlRegisterSingletonType<AppInfo>("AtChat", 1, 0, "AppInfo",
        AppInfo::create);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("AtChat", "Main");

    return app.exec();
}
