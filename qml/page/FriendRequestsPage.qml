import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI
import AtChat 1.0

FluPopup {
    id: root
    width: 500
    height: 600

    ListModel { id: requestsModel }

    Component.onCompleted: {
        NetworkManager.fetchFriendRequests()
    }

    Connections {
        target: NetworkManager
        function onFriendRequestsReceived(requests) {
            requestsModel.clear()
            for (var i = 0; i < requests.length; i++) {
                requestsModel.append(requests[i])
            }
        }
        function onFriendRequestHandled(success) {
            if (success) {
                showSuccess(qsTr("处理成功"))
                NetworkManager.fetchFriendRequests()
                NetworkManager.fetchFriends()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            FluText {
                text: qsTr("好友请求")
                font: FluTextStyle.Title
                Layout.fillWidth: true
            }

            FluIconButton {
                iconSource: FluentIcons.ChromeClose
                iconSize: 16
                onClicked: root.close()
            }
        }

        FluText {
            text: qsTr("待处理的好友请求")
            font: FluTextStyle.BodyStrong
            visible: requestsModel.count > 0
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: requestsModel
            clip: true
            spacing: 10

            delegate: Rectangle {
                width: ListView.view.width
                height: 80
                radius: 8
                color: FluTheme.dark ? Qt.rgba(0.1, 0.1, 0.1, 1) : Qt.rgba(0.95, 0.95, 0.95, 1)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 50
                        height: 50
                        radius: 4
                        color: FluTheme.primaryColor

                        FluText {
                            anchors.centerIn: parent
                            text: model.nickname ? model.nickname.charAt(0) : "?"
                            color: "white"
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        FluText {
                            text: model.nickname || model.username
                            font: FluTextStyle.BodyStrong
                        }

                        FluText {
                            text: model.message || qsTr("请求添加你为好友")
                            font: FluTextStyle.Caption
                            color: FluTheme.fontSecondaryColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    FluFilledButton {
                        text: qsTr("同意")
                        onClicked: {
                            NetworkManager.handleFriendRequest(model.id, true, "")
                        }
                    }

                    FluButton {
                        text: qsTr("拒绝")
                        onClicked: {
                            NetworkManager.handleFriendRequest(model.id, false, "")
                        }
                    }
                }
            }
        }

        FluText {
            text: qsTr("暂无好友请求")
            font: FluTextStyle.Body
            color: FluTheme.fontSecondaryColor
            visible: requestsModel.count === 0
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
