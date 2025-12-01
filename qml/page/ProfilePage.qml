import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI
import AtChat 1.0
import "../global"
import "../component"

FluPage {
    id: root
    title: qsTr("个人中心")
    launchMode: FluPageType.SingleTask

    LoginRequired {}

    property var statusList: [
        {text: qsTr("在线"), icon: FluentIcons.StatusCircleOuter, color: "#4CAF50"},
        {text: qsTr("忙碌"), icon: FluentIcons.StatusCircleOuter, color: "#FF9800"},
        {text: qsTr("请勿打扰"), icon: FluentIcons.StatusCircleOuter, color: "#F44336"},
        {text: qsTr("离开"), icon: FluentIcons.StatusCircleOuter, color: "#9E9E9E"},
        {text: qsTr("隐身"), icon: FluentIcons.StatusCircleOuter, color: "#607D8B"}
    ]
    property int currentStatus: 0

    FluScrollablePage {
        anchors.fill: parent

        ColumnLayout {
            width: parent.width
            spacing: 20

            // 个人资料卡
            FluFrame {
                Layout.fillWidth: true
                Layout.topMargin: 20
                padding: 30

                ColumnLayout {
                    width: parent.width - 60
                    spacing: 20

                    // 头像和基本信息
                    RowLayout {
                        spacing: 20

                        // 头像
                        Rectangle {
                            width: 100
                            height: 100
                            radius: 50
                            color: FluTheme.primaryColor

                            FluText {
                                anchors.centerIn: parent
                                text: NetworkManager.nickname.length > 0 ? NetworkManager.nickname.charAt(0) : "?"
                                font.pixelSize: 40
                                color: "white"
                            }

                            // 状态指示
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: statusList[currentStatus].color
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                border.width: 3
                                border.color: FluTheme.dark ? "#1a1a1a" : "white"
                            }
                        }

                        ColumnLayout {
                            spacing: 8

                            FluText {
                                text: NetworkManager.nickname || NetworkManager.username
                                font: FluTextStyle.Title
                            }

                            FluText {
                                text: "@" + NetworkManager.username
                                font: FluTextStyle.Body
                                color: FluTheme.fontSecondaryColor
                            }

                            FluText {
                                text: "UID: " + NetworkManager.userId.substring(0, 8)
                                font: FluTextStyle.Caption
                                color: FluTheme.fontSecondaryColor
                            }

                            // 点赞数
                            RowLayout {
                                spacing: 5
                                FluIcon {
                                    iconSource: FluentIcons.Like
                                    iconSize: 16
                                    color: "#E91E63"
                                }
                                FluText {
                                    id: likesText
                                    text: "0"
                                    font: FluTextStyle.Body
                                }
                                FluTextButton {
                                    text: qsTr("+1")
                                    onClicked: showSuccess(qsTr("点赞成功！"))
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // 状态选择
                        ColumnLayout {
                            spacing: 5
                            FluText {
                                text: qsTr("当前状态")
                                font: FluTextStyle.Caption
                                color: FluTheme.fontSecondaryColor
                            }
                            FluComboBox {
                                id: statusCombo
                                width: 140
                                model: ListModel {
                                    ListElement { text: "在线" }
                                    ListElement { text: "忙碌" }
                                    ListElement { text: "请勿打扰" }
                                    ListElement { text: "离开" }
                                    ListElement { text: "隐身" }
                                }
                                Component.onCompleted: currentIndex = currentStatus
                                onActivated: {
                                    currentStatus = currentIndex
                                    NetworkManager.updateStatus(currentIndex)
                                }
                            }
                        }
                    }
                }
            }

            // 个性签名
            FluFrame {
                Layout.fillWidth: true
                padding: 20

                ColumnLayout {
                    width: parent.width - 40
                    spacing: 10

                    FluText {
                        text: qsTr("个性签名")
                        font: FluTextStyle.BodyStrong
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        FluTextBox {
                            id: signatureInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("这个人很懒，什么都没写...")
                        }

                        FluButton {
                            text: qsTr("保存")
                            onClicked: {
                                NetworkManager.updateSignature(signatureInput.text)
                                showSuccess(qsTr("签名已更新"))
                            }
                        }
                    }
                }
            }

            // 修改昵称
            FluFrame {
                Layout.fillWidth: true
                padding: 20

                ColumnLayout {
                    width: parent.width - 40
                    spacing: 10

                    FluText {
                        text: qsTr("修改昵称")
                        font: FluTextStyle.BodyStrong
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        FluTextBox {
                            id: nicknameInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("输入新昵称")
                            text: NetworkManager.nickname
                        }

                        FluButton {
                            text: qsTr("保存")
                            onClicked: {
                                if (nicknameInput.text.trim().length > 0) {
                                    NetworkManager.updateNickname(nicknameInput.text.trim())
                                    showSuccess(qsTr("昵称已更新"))
                                }
                            }
                        }
                    }
                }
            }

            // 修改密码
            FluFrame {
                Layout.fillWidth: true
                padding: 20

                ColumnLayout {
                    width: parent.width - 40
                    spacing: 10

                    FluText {
                        text: qsTr("修改密码")
                        font: FluTextStyle.BodyStrong
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10
                        Layout.fillWidth: true

                        FluText { text: qsTr("当前密码：") }
                        FluPasswordBox {
                            id: oldPasswordInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("输入当前密码")
                        }

                        FluText { text: qsTr("新密码：") }
                        FluPasswordBox {
                            id: newPasswordInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("输入新密码")
                        }

                        FluText { text: qsTr("确认密码：") }
                        FluPasswordBox {
                            id: confirmPasswordInput
                            Layout.fillWidth: true
                            placeholderText: qsTr("再次输入新密码")
                        }
                    }

                    FluButton {
                        text: qsTr("修改密码")
                        onClicked: {
                            if (oldPasswordInput.text.length === 0) {
                                showError(qsTr("请输入当前密码"))
                                return
                            }
                            if (newPasswordInput.text.length < 4) {
                                showError(qsTr("新密码至少4位"))
                                return
                            }
                            if (newPasswordInput.text !== confirmPasswordInput.text) {
                                showError(qsTr("两次密码不一致"))
                                return
                            }
                            NetworkManager.changePassword(oldPasswordInput.text, newPasswordInput.text)
                        }
                    }
                }
            }

            // 退出登录
            FluFrame {
                Layout.fillWidth: true
                padding: 20

                RowLayout {
                    width: parent.width - 40
                    spacing: 20

                    FluButton {
                        text: qsTr("退出登录")
                        onClicked: {
                            logoutDialog.open()
                        }
                    }

                    FluText {
                        text: qsTr("退出后需要重新登录")
                        color: FluTheme.fontSecondaryColor
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    FluContentDialog {
        id: logoutDialog
        title: qsTr("退出登录")
        message: qsTr("确定要退出当前账号吗？")
        buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
        negativeText: qsTr("取消")
        positiveText: qsTr("退出")
        onPositiveClicked: {
            NetworkManager.logout()
            showSuccess(qsTr("已退出登录"))
        }
    }

    Component.onCompleted: {
        if (NetworkManager.userId) {
            loadUserProfile()
        }
    }

    function loadUserProfile() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "http://localhost:8080/api/users")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var users = JSON.parse(xhr.responseText)
                if (users && users.length) {
                    for (var i = 0; i < users.length; i++) {
                        if (users[i].id === NetworkManager.userId) {
                            signatureInput.text = users[i].signature || ""
                            currentStatus = users[i].status || 0
                            statusCombo.currentIndex = currentStatus
                            likesText.text = users[i].likes || 0
                            break
                        }
                    }
                }
            }
        }
        xhr.send()
    }

    Connections {
        target: NetworkManager
        function onPasswordChanged(success, error) {
            if (success) {
                showSuccess(qsTr("密码修改成功"))
                oldPasswordInput.text = ""
                newPasswordInput.text = ""
                confirmPasswordInput.text = ""
            } else {
                showError(error)
            }
        }
        function onLoginSuccess() {
            loadUserProfile()
        }
    }
}
