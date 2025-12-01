import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI

// 通用聊天提示组件
// 支持三种类型：
// - "banner": 顶部横幅提示（临时会话、非好友等）
// - "inline": 内联消息提示（入群、禁言、防诈骗等）
// - "popup": 弹窗提示（群公告等）

Item {
    id: root

    property string type: "banner"  // banner, inline, popup
    property string message: ""
    property string iconSource: FluentIcons.Info
    property color iconColor: "#FF9800"
    property color bgColor: FluTheme.dark ? Qt.rgba(0.15, 0.1, 0.05, 1) : Qt.rgba(1, 0.95, 0.85, 1)
    property color textColor: "#FF9800"
    property bool showButton: false
    property string buttonText: ""
    signal buttonClicked()

    implicitHeight: type === "banner" ? 35 : (type === "inline" ? 30 : 0)
    implicitWidth: parent ? parent.width : 0

    // Banner 类型（顶部横幅）
    Rectangle {
        visible: type === "banner"
        anchors.fill: parent
        color: root.bgColor
        radius: 4

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            FluIcon {
                iconSource: root.iconSource
                iconSize: 14
                color: root.iconColor
            }

            FluText {
                text: root.message
                font: FluTextStyle.Caption
                color: root.textColor
                Layout.fillWidth: true
            }

            FluButton {
                visible: root.showButton
                text: root.buttonText
                onClicked: root.buttonClicked()
            }
        }
    }

    // Inline 类型（内联消息）
    Rectangle {
        visible: type === "inline"
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width * 0.8, contentRow.implicitWidth + 20)
        height: 30
        color: FluTheme.dark ? Qt.rgba(0.2, 0.2, 0.2, 0.6) : Qt.rgba(0.9, 0.9, 0.9, 0.6)
        radius: 4

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            FluIcon {
                iconSource: root.iconSource
                iconSize: 12
                color: FluTheme.fontSecondaryColor
            }

            FluText {
                text: root.message
                font: FluTextStyle.Caption
                color: FluTheme.fontSecondaryColor
            }
        }
    }

    // Popup 类型（弹窗）
    FluContentDialog {
        id: popupDialog
        visible: type === "popup"
        title: qsTr("提示")
        message: root.message
        buttonFlags: FluContentDialogType.PositiveButton
        positiveText: qsTr("确定")
    }

    function show() {
        if (type === "popup") {
            popupDialog.open()
        }
    }
}
