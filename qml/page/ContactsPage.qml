import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI
import AtChat 1.0
import "../global"
import "../component"

FluPage {
    id: root
    title: qsTr("通讯录")
    launchMode: FluPageType.SingleTask

    property var currentContact: null

    LoginRequired {}

    AddFriendDialog { id: addFriendDialog }
    FriendRequestsPage { id: friendRequestsDialog }

    ListModel { id: contactsModel }
    ListModel { id: friendsModel }

    property bool friendsLoaded: false

    Component.onCompleted: {
        if (NetworkManager.userId && !friendsLoaded) {
            loadFriends()
            friendsLoaded = true
        }
    }

    Connections {
        target: NetworkManager
        function onLoginSuccess() {
            if (!friendsLoaded) {
                loadFriends()
                friendsLoaded = true
            }
        }
        function onFriendGroupsReceived(groups) {
            contactsModel.clear()
            for (var i = 0; i < groups.length; i++) {
                contactsModel.append({groupName: groups[i].name, groupId: groups[i].id, expanded: true})
            }
        }
        function onFriendsReceived(friends) {
            friendsModel.clear()
            for (var i = 0; i < friends.length; i++) {
                var f = friends[i]
                var groupName = getGroupNameById(f.group_id)
                friendsModel.append({
                    id: f.friend_id,
                    name: f.remark || f.nickname,
                    nickname: f.nickname,
                    signature: f.signature,
                    group: groupName,
                    groupId: f.group_id,
                    online: f.online,
                    isMutual: f.is_mutual,
                    remark: f.remark,
                    note: f.note
                })
            }
        }
        function onFriendRequestHandled(success) {
            if (success && !friendsLoaded) {
                loadFriends()
                friendsLoaded = true
            }
        }
    }

    function loadFriends() {
        NetworkManager.fetchFriendGroups()
        NetworkManager.fetchFriends()
    }

    function getGroupNameById(groupId) {
        for (var i = 0; i < contactsModel.count; i++) {
            if (contactsModel.get(i).groupId === groupId) return contactsModel.get(i).groupName
        }
        return "我的好友"
    }

    function getFriendsByGroup(groupName) {
        var friends = []
        for (var i = 0; i < friendsModel.count; i++) {
            var friend = friendsModel.get(i)
            if (friend.group === groupName) friends.push(friend)
        }
        return friends
    }

    function getOnlineCount(groupName) {
        var count = 0
        for (var i = 0; i < friendsModel.count; i++) {
            var friend = friendsModel.get(i)
            if (friend.group === groupName && friend.online) count++
        }
        return count
    }

    function getTotalCount(groupName) {
        var count = 0
        for (var i = 0; i < friendsModel.count; i++) {
            if (friendsModel.get(i).group === groupName) count++
        }
        return count
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 左侧好友列表
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
                    placeholderText: qsTr("搜索联系人")
                    iconSource: FluentIcons.Search
                }

                // 功能入口
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 10
                    spacing: 10

                    Repeater {
                        model: [
                            {icon: FluentIcons.AddFriend, text: "新朋友", action: "requests"},
                            {icon: FluentIcons.Add, text: "添加", action: "add"},
                            {icon: FluentIcons.Group, text: "群聊", action: "group"}
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            radius: 8
                            color: funcMouse.containsMouse ? FluTheme.itemHoverColor : (FluTheme.dark ? Qt.rgba(0.1, 0.1, 0.1, 1) : "white")

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                FluIcon {
                                    iconSource: modelData.icon
                                    iconSize: 20
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                FluText {
                                    text: modelData.text
                                    font: FluTextStyle.Caption
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: funcMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.action === "requests") {
                                        friendRequestsDialog.open()
                                    } else if (modelData.action === "add") {
                                        addFriendDialog.open()
                                    }
                                }
                            }
                        }
                    }
                }

                // 好友分组列表
                ListView {
                    id: groupListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: contactsModel
                    clip: true

                    delegate: Column {
                        width: groupListView.width

                        // 分组标题
                        Rectangle {
                            width: parent.width
                            height: 36
                            color: groupMouse.containsMouse ? FluTheme.itemHoverColor : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 5

                                FluIcon {
                                    iconSource: model.expanded ? FluentIcons.ChevronDown : FluentIcons.ChevronRight
                                    iconSize: 12
                                }

                                FluText {
                                    text: model.groupName
                                    font: FluTextStyle.Caption
                                    Layout.fillWidth: true
                                }

                                FluText {
                                    text: getOnlineCount(model.groupName) + "/" + getTotalCount(model.groupName)
                                    font: FluTextStyle.Caption
                                    color: FluTheme.fontSecondaryColor
                                }
                            }

                            MouseArea {
                                id: groupMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    contactsModel.setProperty(index, "expanded", !model.expanded)
                                }
                            }
                        }

                        // 分组内的好友
                        Repeater {
                            model: parent.parent.model.expanded ? getFriendsByGroup(parent.parent.model.groupName) : []
                            delegate: Rectangle {
                                    width: groupListView.width
                                    height: 55
                                    color: {
                                        if (currentContact && currentContact.name === modelData.name)
                                            return FluTheme.dark ? Qt.rgba(0.1, 0.1, 0.1, 1) : Qt.rgba(0.9, 0.9, 0.9, 1)
                                        if (friendMouse.containsMouse)
                                            return FluTheme.itemHoverColor
                                        return "transparent"
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 20
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        // 头像
                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: 4
                                            color: modelData.online ? FluTheme.primaryColor : "#9E9E9E"

                                            FluText {
                                                anchors.centerIn: parent
                                                text: modelData.name.charAt(0)
                                                color: "white"
                                                font.pixelSize: 16
                                            }

                                            Rectangle {
                                                visible: modelData.online
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

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            FluText {
                                                text: modelData.name
                                                font: FluTextStyle.Body
                                            }

                                            FluText {
                                                text: modelData.signature || qsTr("[无签名]")
                                                font: FluTextStyle.Caption
                                                color: FluTheme.fontSecondaryColor
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: friendMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.currentContact = modelData
                                        }
                                    }
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

        // 右侧详情区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: FluTheme.dark ? Qt.rgba(0.05, 0.05, 0.05, 1) : Qt.rgba(0.98, 0.98, 0.98, 1)

            // 联系人详情
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20
                visible: currentContact !== null

                // 头像
                Rectangle {
                    width: 100
                    height: 100
                    radius: 8
                    color: currentContact && currentContact.online ? FluTheme.primaryColor : "#9E9E9E"
                    Layout.alignment: Qt.AlignHCenter

                    FluText {
                        anchors.centerIn: parent
                        text: currentContact ? currentContact.name.charAt(0) : ""
                        color: "white"
                        font.pixelSize: 40
                    }
                }

                // 名称
                FluText {
                    text: currentContact ? currentContact.name : ""
                    font: FluTextStyle.Title
                    Layout.alignment: Qt.AlignHCenter
                }

                // 签名
                FluText {
                    text: currentContact && currentContact.signature ? currentContact.signature : qsTr("这个人很懒，什么都没写")
                    font: FluTextStyle.Body
                    color: FluTheme.fontSecondaryColor
                    Layout.alignment: Qt.AlignHCenter
                }

                // 在线状态
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: currentContact && currentContact.online ? "#4CAF50" : "#9E9E9E"
                    }
                    FluText {
                        text: currentContact && currentContact.online ? qsTr("在线") : qsTr("离线")
                        font: FluTextStyle.Caption
                        color: FluTheme.fontSecondaryColor
                    }
                }

                FluText {
                    visible: currentContact && !currentContact.isMutual
                    text: qsTr("对方未添加你为好友")
                    font: FluTextStyle.Caption
                    color: "#FF9800"
                    Layout.alignment: Qt.AlignHCenter
                }

                // 好友信息
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Layout.topMargin: 10

                    FluText {
                        text: qsTr("UID: ") + (currentContact ? currentContact.id : "")
                        font: FluTextStyle.Caption
                        color: FluTheme.fontSecondaryColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    FluText {
                        text: qsTr("备注: ") + (currentContact && currentContact.remark ? currentContact.remark : qsTr("无"))
                        font: FluTextStyle.Caption
                        color: FluTheme.fontSecondaryColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    FluText {
                        text: qsTr("线索: ") + (currentContact && currentContact.note ? currentContact.note : qsTr("无"))
                        font: FluTextStyle.Caption
                        color: FluTheme.fontSecondaryColor
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // 操作按钮
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 15
                    Layout.topMargin: 20

                    FluFilledButton {
                        text: qsTr("发消息")
                        onClicked: {
                            showSuccess(qsTr("即将打开与 ") + currentContact.name + qsTr(" 的聊天"))
                        }
                    }

                    FluButton {
                        text: qsTr("设置备注")
                        onClicked: {
                            remarkDialog.open()
                        }
                    }

                    FluButton {
                        text: qsTr("删除好友")
                        onClicked: {
                            deleteFriendDialog.open()
                        }
                    }
                }

                // 删除好友确认对话框
                FluContentDialog {
                    id: deleteFriendDialog
                    title: qsTr("删除好友")
                    message: qsTr("确定要删除好友 ") + (currentContact ? currentContact.name : "") + qsTr(" 吗？")
                    buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
                    negativeText: qsTr("取消")
                    positiveText: qsTr("删除")
                    onPositiveClicked: {
                        if (currentContact) {
                            NetworkManager.deleteFriend(currentContact.id)
                            currentContact = null
                        }
                    }
                }

                // 设置备注对话框
                FluContentDialog {
                    id: remarkDialog
                    title: qsTr("设置备注")
                    buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
                    negativeText: qsTr("取消")
                    positiveText: qsTr("确定")

                    FluTextBox {
                        id: remarkInput
                        width: parent.width
                        placeholderText: qsTr("输入备注（最长32字符）")
                        text: currentContact ? currentContact.remark : ""
                        maximumLength: 32
                    }

                    onPositiveClicked: {
                        if (currentContact) {
                            NetworkManager.updateFriendRemark(currentContact.id, remarkInput.text)
                            loadFriends()
                        }
                    }
                }
            }

            // 未选择联系人时的提示
            FluText {
                anchors.centerIn: parent
                text: qsTr("选择一个联系人查看详情")
                font: FluTextStyle.Title
                color: FluTheme.fontSecondaryColor
                visible: currentContact === null
            }
        }
    }

}
