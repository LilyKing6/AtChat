import QtQuick
import QtQuick.Window
import FluentUI

FluLauncher {
    id: app

    Component.onCompleted: {
        FluApp.init(app)

        FluTheme.darkMode = FluThemeType.Light
        FluTheme.enableAnimation = true
        FluTheme.nativeText = false

        FluRouter.routes = {
            "/": "qrc:/qml/AppMainWindow.qml",
        }
        FluRouter.navigate("/")
    }
}
