import QtQuick 2.15
import QtQuick.Layouts 1.15
import FluentUI
import AtChat 1.0

Rectangle {
    id: root
    anchors.fill: parent
    visible: !NetworkManager.connected && NetworkManager.userId === ""
    color: FluTheme.dark ? Qt.rgba(0, 0, 0, 0.85) : Qt.rgba(1, 1, 1, 0.9)
    z: 1000

    MouseArea {
        anchors.fill: parent
        onClicked: {} // 阻止点击穿透
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        FluIcon {
            iconSource: FluentIcons.Lock
            iconSize: 64
            Layout.alignment: Qt.AlignHCenter
            color: FluTheme.primaryColor
        }

        FluText {
            text: qsTr("请先登录")
            font: FluTextStyle.Title
            Layout.alignment: Qt.AlignHCenter
        }

        FluText {
            text: qsTr("登录后即可使用消息和通讯录功能")
            font: FluTextStyle.Body
            color: FluTheme.fontSecondaryColor
            Layout.alignment: Qt.AlignHCenter
        }

        FluFilledButton {
            text: qsTr("立即登录")
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 150
            onClicked: {
                loginDialog.open()
            }
        }
    }

    // 登录对话框
    // FluContentDialog {
    //     id: loginDialog
    //     title: qsTr("登录")
    //     contentDelegate: Component {
    //         ColumnLayout {
    //             spacing: 15
    //             width: 300

    //             property bool isRegister: false

    //             Connections {
    //                 target: NetworkManager
    //                 function onLoginSuccess(user) {
    //                     loginDialog.close()
    //                     showSuccess(qsTr("登录成功"))
    //                 }
    //                 function onLoginFailed(error) {
    //                     showError(qsTr("登录失败: ") + error)
    //                 }
    //                 function onRegisterSuccess(user) {
    //                     showSuccess(qsTr("注册成功，请登录"))
    //                     isRegister = false
    //                 }
    //                 function onRegisterFailed(error) {
    //                     showError(qsTr("注册失败: ") + error)
    //                 }
    //             }

    //             FluTextBox {
    //                 id: usernameInput
    //                 Layout.fillWidth: true
    //                 placeholderText: qsTr("用户名")
    //             }

    //             FluTextBox {
    //                 id: nicknameInput
    //                 Layout.fillWidth: true
    //                 placeholderText: qsTr("昵称")
    //                 visible: parent.isRegister
    //             }

    //             FluPasswordBox {
    //                 id: passwordInput
    //                 Layout.fillWidth: true
    //                 placeholderText: qsTr("密码")
    //             }

    //             FluPasswordBox {
    //                 id: confirmInput
    //                 Layout.fillWidth: true
    //                 placeholderText: qsTr("确认密码")
    //                 visible: parent.isRegister
    //             }

    //             FluFilledButton {
    //                 text: parent.isRegister ? qsTr("注册") : qsTr("登录")
    //                 Layout.fillWidth: true
    //                 onClicked: {
    //                     if (usernameInput.text.trim() === "" || passwordInput.text === "") {
    //                         showError(qsTr("请填写完整信息"))
    //                         return
    //                     }
    //                     if (parent.isRegister) {
    //                         if (passwordInput.text !== confirmInput.text) {
    //                             showError(qsTr("两次密码不一致"))
    //                             return
    //                         }
    //                         NetworkManager.registerUser(usernameInput.text.trim(), passwordInput.text, nicknameInput.text.trim() || usernameInput.text.trim())
    //                     } else {
    //                         NetworkManager.login(usernameInput.text.trim(), passwordInput.text)
    //                     }
    //                 }
    //             }

    //             FluTextButton {
    //                 text: parent.isRegister ? qsTr("已有账号？登录") : qsTr("没有账号？注册")
    //                 Layout.alignment: Qt.AlignHCenter
    //                 onClicked: parent.isRegister = !parent.isRegister
    //             }

    //             FluText {
    //                 text: qsTr("测试账号: test / test")
    //                 font: FluTextStyle.Caption
    //                 color: FluTheme.fontSecondaryColor
    //                 Layout.alignment: Qt.AlignHCenter
    //                 visible: !parent.isRegister
    //             }
    //         }
    //     }
    //     negativeText: qsTr("取消")
    //     onNegativeClicked: loginDialog.close()
    // }
    FluPopup {
        id: loginDialog

        //title: qsTr("登录")
        //launchMode: FluPageType.SingleTask

        property bool isRegister: false

        Connections {
            target: NetworkManager
            function onLoginSuccess(user) {
                loginDialog.close()
                showSuccess(qsTr("登录成功"))
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
                RowLayout {
                    Layout.fillWidth: true

                    FluText {
                        text: "AtChat"
                        font: FluTextStyle.Title
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                    }

                    FluIconButton {
                        iconSource: FluentIcons.ChromeClose
                        iconSize: 16
                        onClicked: loginDialog.close()
                    }
                }

                FluText {
                    text: parent.isRegister ? qsTr("创建新账号") : qsTr("登录到您的账号")
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
                    visible: loginDialog.isRegister
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
                    visible: loginDialog.isRegister
                    FluText { text: qsTr("确认密码") }
                    FluPasswordBox {
                        id: confirmPasswordInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("请再次输入密码")
                    }
                }

                // 登录/注册按钮
                FluFilledButton {
                    text: parent.isRegister ? qsTr("注册") : qsTr("登录")
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

                        if (loginDialog.isRegister) {
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
                    text: parent.isRegister ? qsTr("已有账号？去登录") : qsTr("没有账号？去注册")
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: {
                        loginDialog.isRegister = !loginDialog.isRegister
                    }
                }

                // 测试账号提示
                FluText {
                    visible: !parent.isRegister
                    text: qsTr("测试账号: test / test")
                    font: FluTextStyle.Caption
                    color: FluTheme.fontSecondaryColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

}
