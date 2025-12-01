import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI
import AtChat 1.0

FluContentDialog {
    id: root
    title: qsTr("添加好友")
    width: 500
    buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
    negativeText: qsTr("取消")
    positiveText: qsTr("搜索")
    onNegativeClicked: close()

    property var searchResult: null

    onPositiveClicked: {
        if (uidInput.text.trim().length > 0) {
            NetworkManager.searchUser(uidInput.text.trim())
        }
    }

    Connections {
        target: NetworkManager
        function onUserSearchResult(user) {
            if (user.id) {
                searchResult = user
            } else {
                showError(qsTr("用户不存在"))
                searchResult = null
            }
        }
        function onFriendRequestSent(success) {
            if (success) {
                showSuccess(qsTr("好友请求已发送"))
                searchResult = null
                uidInput.text = ""
                messageInput.text = ""
                root.close()
            } else {
                showError(qsTr("发送失败"))
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 40

        FluTextBox {
            id: uidInput
            Layout.fillWidth: true
            placeholderText: qsTr("输入用户UID")
            onAccepted: {
                if (text.trim().length > 0) {
                    NetworkManager.searchUser(text.trim())
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: 8
            color: FluTheme.dark ? Qt.rgba(0.1, 0.1, 0.1, 1) : Qt.rgba(0.95, 0.95, 0.95, 1)
            visible: searchResult !== null

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 15

                Rectangle {
                    width: 70
                    height: 70
                    radius: 4
                    color: FluTheme.primaryColor

                    FluText {
                        anchors.centerIn: parent
                        text: searchResult ? (searchResult.nickname ? searchResult.nickname.charAt(0) : "?") : ""
                        color: "white"
                        font.pixelSize: 24
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    FluText {
                        text: searchResult ? (searchResult.nickname || searchResult.username) : ""
                        font: FluTextStyle.BodyStrong
                    }

                    RowLayout {
                        spacing: 5
                        FluText {
                            text: qsTr("UID: ") + (searchResult ? searchResult.id : "")
                            font: FluTextStyle.Caption
                            color: FluTheme.fontSecondaryColor
                        }
                        FluIconButton {
                            iconSource: FluentIcons.Copy
                            iconSize: 12
                            onClicked: {
                                if (searchResult) {
                                    // 复制到剪贴板的简单实现
                                    uidInput.text = searchResult.id
                                    showSuccess(qsTr("UID已复制到搜索框"))
                                }
                            }
                        }
                    }

                    FluText {
                        text: searchResult ? (searchResult.signature || qsTr("[无签名]")) : ""
                        font: FluTextStyle.Caption
                        color: FluTheme.fontSecondaryColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    FluText {
                        text: qsTr("点赞: ") + (searchResult ? searchResult.likes : 0)
                        font: FluTextStyle.Caption
                        color: FluTheme.fontSecondaryColor
                    }
                }
            }
        }

        FluMultilineTextBox {
            id: messageInput
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            placeholderText: qsTr("验证消息（可选）")
            visible: searchResult !== null
        }

        FluFilledButton {
            text: qsTr("发送好友请求")
            Layout.alignment: Qt.AlignRight
            visible: searchResult !== null
            onClicked: {
                if (searchResult) {
                    NetworkManager.sendFriendRequest(searchResult.id, messageInput.text)
                }
            }
        }
    }
}
