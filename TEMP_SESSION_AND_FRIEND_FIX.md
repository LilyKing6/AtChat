# 临时会话和好友功能修复

## 修复的问题

### 1. ✅ 临时会话提示
**问题描述：**
- 临时会话和正式好友聊天界面完全一样
- 没有提示用户当前是临时会话
- 没有快捷添加好友的入口

**修复方案：**
- 在聊天标题栏下方添加临时会话提示条
- 显示橙色提示："你们还不是好友，可添加好友"
- 添加"添加好友"按钮快速发送好友请求
- 根据好友状态动态调整标题栏高度

**实现细节：**
```qml
// 检查好友状态
function checkFriendStatus(userId) {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", "http://localhost:8080/api/friends?user_id=" + NetworkManager.userId)
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
            var friends = JSON.parse(xhr.responseText)
            currentIsFriend = false
            for (var i = 0; i < friends.length; i++) {
                if (friends[i].friend_id === userId) {
                    currentIsFriend = true
                    break
                }
            }
        }
    }
    xhr.send()
}

// 临时会话提示条
Rectangle {
    visible: !currentIsFriend && currentChatId !== ""
    color: 橙色背景
    // 显示提示和添加好友按钮
}
```

---

### 2. ✅ 好友请求对话框无法关闭
**问题描述：**
- 点击"关闭"按钮后对话框不关闭
- 只能强制退出客户端

**原因分析：**
- 使用 `FluContentDialog` 时 `onNegativeClicked` 没有正确触发
- 可能是 FluentUI 的 bug 或版本问题

**修复方案：**
- 将 `FluContentDialog` 改为 `FluPopup`
- 添加自定义标题栏和关闭按钮
- 使用 `FluIconButton` 调用 `root.close()`

**修改前：**
```qml
FluContentDialog {
    id: root
    buttonFlags: FluContentDialogType.NegativeButton
    negativeText: qsTr("关闭")
    onNegativeClicked: close()  // 不工作
}
```

**修改后：**
```qml
FluPopup {
    id: root
    ColumnLayout {
        RowLayout {
            FluText { text: qsTr("好友请求") }
            FluIconButton {
                iconSource: FluentIcons.ChromeClose
                onClicked: root.close()  // 正常工作
            }
        }
    }
}
```

---

### 3. ✅ 添加好友后对方列表不更新
**问题描述：**
- A 添加 B 为好友，B 同意后
- A 的好友列表更新了
- B 的好友列表没有更新，需要重启客户端

**原因分析：**
1. 服务端只添加了单向好友关系（B -> A）
2. 没有自动添加反向关系（A -> B）
3. 前端没有在处理好友请求后刷新列表

**修复方案：**

#### 服务端修复（双向添加）
```go
func (s *FriendService) HandleFriendRequest(requestID, userID, groupID string, accept bool) error {
    // ...
    if accept {
        // 添加双向好友关系
        // 1. 为接受者添加好友
        db.DB.Exec("INSERT INTO friends (id, user_id, friend_id, group_id) VALUES (?, ?, ?, ?)",
            uuid.New().String(), userID, fromUser, groupID)

        // 2. 为发起者也添加好友
        fromGroupID := s.getDefaultGroup(fromUser)
        db.DB.Exec("INSERT INTO friends (id, user_id, friend_id, group_id) VALUES (?, ?, ?, ?)",
            uuid.New().String(), fromUser, userID, fromGroupID)
    }
    // ...
}
```

#### 前端修复（自动刷新）
```qml
// FriendRequestsPage.qml
function onFriendRequestHandled(success) {
    if (success) {
        showSuccess(qsTr("处理成功"))
        NetworkManager.fetchFriendRequests()
        NetworkManager.fetchFriends()  // 刷新好友列表
    }
}

// ContactsPage.qml
function onFriendRequestHandled(success) {
    if (success && !friendsLoaded) {
        loadFriends()
        friendsLoaded = true
    }
}
```

---

## 临时会话逻辑说明

### 发送限制
- **A（发起者）**：可以发送 1 条消息
- **B（接收者）**：不受限制，可以发送任意条消息
- **A 再次发送**：需要等 B 回复至少 1 条消息后才能继续

### 服务端实现
```go
func (h *HandlerDB) handleChatMessage(client *ws.Client, data interface{}) {
    // ...
    isFriend := h.hub.IsFriend(client.UserID, to)
    if !isFriend {
        // 检查已发送的未读消息数
        sentCount := h.msgSvc.GetUnreadCount(to, client.UserID)
        if sentCount >= 1 {
            client.SendMessage(&model.WSMessage{
                Action: "error",
                Data:   map[string]string{"error": "临时会话最多发送一条消息"},
            })
            return
        }
    }
    // 保存并发送消息
    // ...
}
```

### 前端显示
- 检查好友状态：`checkFriendStatus(userId)`
- 显示提示条：`visible: !currentIsFriend && currentChatId !== ""`
- 提供添加好友按钮

---

## 修改的文件

### 前端
1. `qml/page/ChatPage.qml`
   - 添加 `currentIsFriend` 属性
   - 添加 `checkFriendStatus()` 函数
   - 添加临时会话提示条
   - 添加快捷添加好友对话框

2. `qml/page/FriendRequestsPage.qml`
   - 从 `FluContentDialog` 改为 `FluPopup`
   - 添加自定义标题栏和关闭按钮
   - 处理成功后刷新好友列表

3. `qml/page/ContactsPage.qml`
   - 添加 `onFriendRequestHandled` 处理
   - 自动刷新好友列表

### 后端
1. `server/internal/service/friend.go`
   - 修改 `HandleFriendRequest()` 函数
   - 添加双向好友关系

---

## 测试步骤

### 临时会话测试
1. 登录 test/test 和 lisi/123456（确保不是好友）
2. test 给 lisi 发送消息
3. **预期结果**：
   - test 端显示临时会话提示条
   - test 可以发送 1 条消息
   - test 尝试发送第 2 条消息时被阻止
4. lisi 回复消息
5. **预期结果**：
   - lisi 端显示临时会话提示条
   - lisi 可以发送任意条消息
6. lisi 回复后，test 再次发送
7. **预期结果**：
   - test 可以继续发送消息

### 好友请求对话框测试
1. 打开"新朋友"对话框
2. 点击右上角关闭按钮
3. **预期结果**：对话框正常关闭

### 双向好友添加测试
1. test 添加 lisi 为好友
2. lisi 同意好友请求
3. **预期结果**：
   - test 的好友列表自动更新，显示 lisi
   - lisi 的好友列表自动更新，显示 test
   - 双方聊天界面不再显示临时会话提示

---

## 已知限制

1. **好友状态检查**：每次打开聊天时都会发送 HTTP 请求检查好友状态，可以优化为缓存
2. **临时会话计数**：基于未读消息数判断，如果对方已读消息，计数会重置
3. **实时更新**：添加好友后需要手动刷新或重新打开页面才能看到更新

---

## 后续改进建议

1. **WebSocket 通知**：添加好友后通过 WebSocket 通知对方刷新列表
2. **好友状态缓存**：缓存好友关系，减少 HTTP 请求
3. **临时会话计数优化**：使用专门的字段记录临时会话发送次数
4. **UI 优化**：临时会话提示可以更醒目，添加动画效果
