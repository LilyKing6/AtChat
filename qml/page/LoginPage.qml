import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI
import AtChat 1.0

FluPage {
    id: root
    // title: qsTr("登录")
    launchMode: FluPageType.SingleTask

    property bool isRegister: false

    Connections {
        target: NetworkManager
        function onLoginSuccess(user) {
            showSuccess(qsTr("登录成功"))
            FluRouter.navigate("/")
        }
        function onLoginFailed(error) {
            showError(qsTr("登录失败: ") + error)
        }
        function onRegisterSuccess(user) {
            showSuccess(qsTr("注册成功，请登录"))
            isRegister = false
        }
        function onRegisterFailed(error) {
            showError(qsTr("注册失败: ") + error)
        }
    }

    FluFrame {
        width: 400
        anchors.centerIn: parent
        padding: 30

        ColumnLayout {
            width: parent.width - 60
            spacing: 20

            // Logo
            // FluImage {
            //     source: "qrc:/res/logo.png"
            //     width: 80
            //     height: 80
            //     Layout.alignment: Qt.AlignHCenter
            // }

            FluText {
                text: "AtChat"
                font: FluTextStyle.Title
                Layout.alignment: Qt.AlignHCenter
            }

            FluText {
                text: isRegister ? qsTr("创建新账号") : qsTr("登录到您的账号")
                font: FluTextStyle.Body
                color: FluTheme.fontSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }

            // 用户名
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                FluText { text: qsTr("用户名") }
                FluTextBox {
                    id: usernameInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("请输入用户名")
                }
            }

            // 昵称（仅注册）
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                visible: isRegister
                FluText { text: qsTr("昵称") }
                FluTextBox {
                    id: nicknameInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("请输入昵称")
                }
            }

            // 密码
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                FluText { text: qsTr("密码") }
                FluPasswordBox {
                    id: passwordInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("请输入密码")
                }
            }

            // 确认密码（仅注册）
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                visible: isRegister
                FluText { text: qsTr("确认密码") }
                FluPasswordBox {
                    id: confirmPasswordInput
                    Layout.fillWidth: true
                    placeholderText: qsTr("请再次输入密码")
                }
            }

            // 登录/注册按钮
            FluFilledButton {
                text: isRegister ? qsTr("注册") : qsTr("登录")
                Layout.fillWidth: true
                Layout.topMargin: 10
                onClicked: {
                    if (usernameInput.text.trim().length === 0) {
                        showError(qsTr("请输入用户名"))
                        return
                    }
                    if (passwordInput.text.length === 0) {
                        showError(qsTr("请输入密码"))
                        return
                    }

                    if (isRegister) {
                        if (passwordInput.text !== confirmPasswordInput.text) {
                            showError(qsTr("两次密码不一致"))
                            return
                        }
                        var nickname = nicknameInput.text.trim()
                        if (nickname.length === 0) nickname = usernameInput.text.trim()
                        NetworkManager.registerUser(usernameInput.text.trim(), passwordInput.text, nickname)
                    } else {
                        NetworkManager.login(usernameInput.text.trim(), passwordInput.text)
                    }
                }
            }

            // 切换登录/注册
            FluTextButton {
                text: isRegister ? qsTr("已有账号？去登录") : qsTr("没有账号？去注册")
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    isRegister = !isRegister
                }
            }

            // 测试账号提示
            FluText {
                visible: !isRegister
                text: qsTr("测试账号: test / test")
                font: FluTextStyle.Caption
                color: FluTheme.fontSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
