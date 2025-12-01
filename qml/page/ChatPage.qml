import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI
import AtChat 1.0
import "../global"
import "../component"

FluPage {
    id: root
    title: qsTr("聊天")
    launchMode: FluPageType.SingleTask

    property int currentChatIndex: -1
    property string currentChatId: ""
    property string currentChatName: ""
    property bool currentIsFriend: false

    // 登录检查
    LoginRequired {}

    FluContentDialog {
        id: addFriendFromChatDialog
        title: qsTr("添加好友")
        message: qsTr("确定要添加此用户为好友吗？")
        buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
        negativeText: qsTr("取消")
        positiveText: qsTr("发送请求")
        property string targetUserId: ""
        onPositiveClicked: {
            NetworkManager.sendFriendRequest(targetUserId, "")
        }
    }

    property bool usersLoaded: false

    Component.onCompleted: {
        if (NetworkManager.userId !== "" && !usersLoaded) {
            NetworkManager.fetchUsers()
            usersLoaded = true
        }
    }

    Connections {
        target: NetworkManager
        function onUserChanged() {
            if (NetworkManager.userId !== "" && !usersLoaded) {
                NetworkManager.fetchUsers()
                usersLoaded = true
            }
        }
    }

    Connections {
        target: NetworkManager
        function onUsersReceived(users) {
            chatListModel.clear()
            for (var i = 0; i < users.length; i++) {
                var u = users[i]
                if (u.id !== NetworkManager.userId) {
                    chatListModel.append({
                        oderId: u.id,
                        name: u.nickname || u.username,
                        lastMessage: u.signature || "",
                        time: "",
                        unread: 0,
                        online: u.online
                    })
                }
            }
        }
        function onMessageReceived(msg) {
            console.log("Message received:", JSON.stringify(msg))
            var isMe = msg.from === NetworkManager.userId
            var otherUserId = isMe ? msg.to : msg.from

            // 如果是当前聊天，添加消息
            if (currentChatId !== "" && currentChatId === otherUserId) {
                var msgTime = msg.timestamp ? new Date(msg.timestamp) : new Date()
                messageModel.append({
                    isMe: isMe,
                    content: msg.content,
                    time: Qt.formatTime(msgTime, "hh:mm"),
                    isRead: false
                })
                Qt.callLater(function() { messageListView.positionViewAtEnd() })
            }

            // 更新会话列表
            var found = false
            for (var i = 0; i < chatListModel.count; i++) {
                if (chatListModel.get(i).oderId === otherUserId) {
                    chatListModel.setProperty(i, "lastMessage", msg.content)
                    chatListModel.setProperty(i, "time", Qt.formatTime(new Date(), "hh:mm"))
                    if (!isMe && currentChatId !== otherUserId) {
                        chatListModel.setProperty(i, "unread", chatListModel.get(i).unread + 1)
                    }
                    found = true
                    break
                }
            }

            // 如果会话列表中没有这个用户，添加它
            if (!found && !isMe) {
                chatListModel.insert(0, {
                    oderId: otherUserId,
                    name: otherUserId.substring(0, 8),
                    lastMessage: msg.content,
                    time: Qt.formatTime(new Date(), "hh:mm"),
                    unread: currentChatId !== otherUserId ? 1 : 0,
                    online: false
                })
            }
        }
        function onUserStatusChanged(userId, online) {
            for (var i = 0; i < chatListModel.count; i++) {
                if (chatListModel.get(i).oderId === userId) {
                    chatListModel.setProperty(i, "online", online)
                    break
                }
            }
        }
        function onHistoryReceived(messages) {
            messageModel.clear()
            var lastDate = ""
            for (var i = 0; i < messages.length; i++) {
                var msg = messages[i]
                var msgDate = new Date(msg.timestamp)
                var dateStr = Qt.formatDate(msgDate, "yyyy-MM-dd")
                var timeStr = Qt.formatTime(msgDate, "hh:mm")

                if (dateStr !== lastDate) {
                    lastDate = dateStr
                    timeStr = dateStr + " " + timeStr
                }

                messageModel.append({
                    isMe: msg.from === NetworkManager.userId,
                    content: msg.content,
                    time: timeStr,
                    isRead: msg.is_read
                })
            }
            messageListView.positionViewAtEnd()
        }
        function onMessagesDeleted(success) {
            if (success) {
                showSuccess(qsTr("删除成功"))
            }
        }
        function onConnectionError(error) {
            showError(error)
        }
    }

    ListModel { id: chatListModel }
    ListModel { id: messageModel }

    function sendMsg() {
        var text = inputBox.text.trim()
        if (text.length > 0 && currentChatId !== "") {
            NetworkManager.sendMessage(currentChatId, text, "text")
            inputBox.clear()
        }
    }

    function loadMessages(chatIndex) {
        messageModel.clear()
        if (chatIndex >= 0 && chatIndex < chatListModel.count) {
            var chat = chatListModel.get(chatIndex)
            NetworkManager.fetchHistory(chat.oderId)
            chatListModel.setProperty(chatIndex, "unread", 0)
            checkFriendStatus(chat.oderId)
        }
    }

    function checkFriendStatus(userId) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "http://localhost:8080/api/friends?user_id=" + NetworkManager.userId)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var friends = JSON.parse(xhr.responseText)
                root.currentIsFriend = false
                if (friends && friends.length) {
                    for (var i = 0; i < friends.length; i++) {
                        if (friends[i].friend_id === userId) {
                            root.currentIsFriend = true
                            break
                        }
                    }
                }
            }
        }
        xhr.send()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 左侧会话列表
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: FluTheme.dark ? Qt.rgba(0.03, 0.03, 0.03, 1) : Qt.rgba(0.95, 0.95, 0.95, 1)

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // 搜索框
                FluTextBox {
                    Layout.fillWidth: true
                    Layout.margins: 10
                    placeholderText: qsTr("搜索")
                    iconSource: FluentIcons.Search
                }

                // 会话列表
                ListView {
                    id: chatListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: chatListModel
                    clip: true
                    currentIndex: root.currentChatIndex

                    delegate: Rectangle {
                        width: chatListView.width
                        height: 70
                        color: {
                            if (chatListView.currentIndex === index)
                                return FluTheme.dark ? Qt.rgba(0.1, 0.1, 0.1, 1) : Qt.rgba(0.9, 0.9, 0.9, 1)
                            if (mouseArea.containsMouse)
                                return FluTheme.itemHoverColor
                            return "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // 头像
                            Rectangle {
                                width: 45
                                height: 45
                                radius: 4
                                color: FluTheme.primaryColor

                                FluText {
                                    anchors.centerIn: parent
                                    text: model.name.charAt(0)
                                    color: "white"
                                    font.pixelSize: 18
                                }

                                // 在线状态
                                Rectangle {
                                    visible: model.online
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: "#4CAF50"
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    border.width: 2
                                    border.color: FluTheme.dark ? "#1a1a1a" : "#f0f0f0"
                                }
                            }

                            // 名称和消息
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true
                                    FluText {
                                        text: model.name
                                        font: FluTextStyle.BodyStrong
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    FluText {
                                        text: model.time
                                        font: FluTextStyle.Caption
                                        color: FluTheme.fontSecondaryColor
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    FluText {
                                        text: model.lastMessage
                                        font: FluTextStyle.Caption
                                        color: FluTheme.fontSecondaryColor
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    // 未读数
                                    Rectangle {
                                        visible: model.unread > 0
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: "#F44336"
                                        FluText {
                                            anchors.centerIn: parent
                                            text: model.unread > 99 ? "99+" : model.unread
                                            font.pixelSize: 10
                                            color: "white"
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.currentChatIndex = index
                                root.currentChatId = model.oderId
                                root.currentChatName = model.name
                                loadMessages(index)
                            }
                        }
                    }
                }
            }
        }

        // 分隔线
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: FluTheme.dark ? Qt.rgba(0.2, 0.2, 0.2, 1) : Qt.rgba(0.85, 0.85, 0.85, 1)
        }

        // 右侧聊天区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: FluTheme.dark ? Qt.rgba(0.05, 0.05, 0.05, 1) : Qt.rgba(0.98, 0.98, 0.98, 1)

            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                visible: currentChatId !== ""

                // 聊天标题栏
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: currentIsFriend ? 50 : 90
                    color: FluTheme.dark ? Qt.rgba(0.08, 0.08, 0.08, 1) : Qt.rgba(0.96, 0.96, 0.96, 1)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true

                            FluText {
                                text: currentChatName
                                font: FluTextStyle.BodyStrong
                                Layout.fillWidth: true
                            }

                            FluIconButton {
                                iconSource: FluentIcons.More
                                iconSize: 16
                                onClicked: chatMenu.popup()

                                FluMenu {
                                    id: chatMenu
                                    FluMenuItem {
                                        text: qsTr("删除聊天记录")
                                        onClicked: deleteMessagesDialog.open()
                                    }
                                }
                            }

                            FluContentDialog {
                                id: deleteMessagesDialog
                                title: qsTr("删除聊天记录")
                                message: qsTr("是否同时删除服务器上的漫游记录？")
                                buttonFlags: FluContentDialogType.NeutralButton | FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
                                neutralText: qsTr("仅本地")
                                negativeText: qsTr("取消")
                                positiveText: qsTr("全部删除")

                                onNeutralClicked: {
                                    NetworkManager.deleteMessages(currentChatId, false)
                                    messageModel.clear()
                                }

                                onPositiveClicked: {
                                    NetworkManager.deleteMessages(currentChatId, true)
                                    messageModel.clear()
                                }
                            }
                        }

                        // 临时会话提示
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 35
                            visible: !currentIsFriend && currentChatId !== ""
                            color: FluTheme.dark ? Qt.rgba(0.15, 0.1, 0.05, 1) : Qt.rgba(1, 0.95, 0.85, 1)
                            radius: 4

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                FluIcon {
                                    iconSource: FluentIcons.Info
                                    iconSize: 14
                                    color: "#FF9800"
                                }

                                FluText {
                                    text: qsTr("你们还不是好友，临时会话在对方回复前最多只能发送一条消息")
                                    font: FluTextStyle.Caption
                                    color: "#FF9800"
                                    Layout.fillWidth: true
                                }

                                FluButton {
                                    text: qsTr("添加好友")
                                    onClicked: {
                                        addFriendFromChatDialog.targetUserId = currentChatId
                                        addFriendFromChatDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }

                // 分隔线
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: FluTheme.dark ? Qt.rgba(0.2, 0.2, 0.2, 1) : Qt.rgba(0.9, 0.9, 0.9, 1)
                }

                // 消息列表
                ListView {
                    id: messageListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 10
                    model: messageModel
                    clip: true
                    spacing: 10

                    delegate: Item {
                        width: messageListView.width
                        height: msgBubble.height + timeText.height + 20

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 5

                            // 时间戳
                            FluText {
                                id: timeText
                                text: model.time
                                font: FluTextStyle.Caption
                                color: FluTheme.fontSecondaryColor
                                Layout.alignment: Qt.AlignHCenter
                                visible: index === 0 || (index > 0 && model.time !== messageModel.get(index - 1).time)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                layoutDirection: model.isMe ? Qt.RightToLeft : Qt.LeftToRight
                                spacing: 10

                                // 头像
                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 4
                                    color: model.isMe ? FluTheme.primaryColor : "#9E9E9E"
                                    Layout.alignment: Qt.AlignTop

                                    FluText {
                                        anchors.centerIn: parent
                                        text: model.isMe ? "我" : (currentChatName.length > 0 ? currentChatName.charAt(0) : "")
                                        color: "white"
                                        font.pixelSize: 14
                                    }
                                }

                                // 消息气泡
                                Rectangle {
                                    id: msgBubble
                                    Layout.maximumWidth: messageListView.width * 0.6
                                    implicitWidth: msgText.implicitWidth + 24
                                    implicitHeight: msgText.implicitHeight + 16
                                    radius: 8
                                    color: model.isMe ? FluTheme.primaryColor : (FluTheme.dark ? Qt.rgba(0.15, 0.15, 0.15, 1) : "white")

                                    FluText {
                                        id: msgText
                                        anchors.centerIn: parent
                                        width: Math.min(implicitWidth, messageListView.width * 0.6 - 24)
                                        text: model.content
                                        wrapMode: Text.Wrap
                                        color: model.isMe ? "white" : FluTheme.fontPrimaryColor
                                        textFormat: Text.PlainText
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }

                // 分隔线
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: FluTheme.dark ? Qt.rgba(0.2, 0.2, 0.2, 1) : Qt.rgba(0.9, 0.9, 0.9, 1)
                }

                // 输入区域
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    color: FluTheme.dark ? Qt.rgba(0.08, 0.08, 0.08, 1) : Qt.rgba(0.96, 0.96, 0.96, 1)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // 工具栏
                        RowLayout {
                            spacing: 5
                            FluIconButton {
                                id: emojiBtn
                                iconSource: FluentIcons.Emoji2
                                iconSize: 18
                                onClicked: emojiPicker.open()
                            }
                            FluIconButton { iconSource: FluentIcons.Picture; iconSize: 18 }
                            FluIconButton { iconSource: FluentIcons.Attach; iconSize: 18 }
                            FluIconButton { iconSource: FluentIcons.History; iconSize: 18 }
                        }

                        EmojiPicker {
                            id: emojiPicker
                            onEmojiSelected: function(emoji) {
                                inputBox.text += emoji
                            }
                        }

                        // 输入框
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            FluMultilineTextBox {
                                id: inputBox
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                placeholderText: qsTr("输入消息...")
                                onCommit: function(text) {
                                    sendMsg()
                                }
                            }

                            FluFilledButton {
                                text: qsTr("发送")
                                Layout.alignment: Qt.AlignBottom
                                onClicked: sendMsg()
                            }
                        }
                    }
                }
            }

            // 未选择聊天时的提示
            FluText {
                anchors.centerIn: parent
                text: qsTr("选择一个聊天开始对话")
                font: FluTextStyle.Title
                color: FluTheme.fontSecondaryColor
                visible: currentChatId === ""
            }
        }
    }
}
