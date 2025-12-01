pragma Singleton

import QtQuick 2.15
import FluentUI

FluObject{

    property var navigationView
    property var paneItemMenu

    id: footer_items

    FluPaneItemSeparator{}

    FluPaneItem{
        title:qsTr("设置")
        menuDelegate: paneItemMenu
        icon: FluentIcons.Settings
        url: "qrc:/qml/page/Settings.qml"
        onTap:{
            navigationView.push(url)
        }
    }
}
