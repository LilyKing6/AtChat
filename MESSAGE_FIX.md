# 消息发送和接收问题修复

## 问题描述

1. **消息无法发送**：所有用户都无法发送消息
2. **test用户只能发送一次**：发送一条后需要切换页面才能继续发送
3. **消息不实时显示**：发送的消息不会立即显示在聊天界面
4. **未读消息计数**：没有未读消息提示和小红点

## 根本原因分析

### 1. 输入框清空问题
- `FluMultilineTextBox` 使用 `text = ""` 清空会导致组件状态异常
- 需要使用 `clear()` 方法

### 2. WebSocket 连接状态
- 没有检查 WebSocket 连接状态就发送消息
- 连接断开后没有自动重连机制

### 3. 消息接收逻辑
- 消息时间戳处理不正确
- 未读消息计数逻辑有误
- 当前聊天窗口的消息不应计入未读

### 4. 调试信息缺失
- 没有日志输出，无法追踪问题

## 修复方案

### 1. 统一消息发送函数
```qml
function sendMsg() {
    var text = inputBox.text.trim()
    if (text.length > 0 && currentChatId !== "") {
        NetworkManager.sendMessage(currentChatId, text, "text")
        inputBox.clear()
    }
}
```

### 2. 添加 WebSocket 状态检查
```cpp
void NetworkManager::sendMessage(const QString &to, const QString &content, const QString &type)
{
    if (!m_connected || m_ws->state() != QAbstractSocket::ConnectedState) {
        qDebug() << "WebSocket not connected, reconnecting...";
        connectWebSocket();
        return;
    }
    // ... 发送消息
}
```

### 3. 完善消息接收逻辑
```qml
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
            // 只有不是自己发的，且不在当前聊天窗口时才计入未读
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
```

### 4. 添加调试日志
- WebSocket 连接/断开日志
- 消息发送/接收日志
- 错误信息日志

## 修改的文件

1. `qml/page/ChatPage.qml`
   - 添加 `sendMsg()` 统一发送函数
   - 修复 `onMessageReceived()` 逻辑
   - 修复未读消息计数
   - 添加控制台日志

2. `src/NetworkManager.cpp`
   - 添加 WebSocket 状态检查
   - 添加调试日志输出
   - 添加错误处理

## 测试步骤

### 基础消息发送测试
1. 启动服务器：`cd server && go run cmd/server/main.go`
2. 启动客户端1，登录 test/test
3. 启动客户端2，登录 lisi/123456
4. 在 test 端选择 lisi 聊天
5. 输入消息点击发送
6. **预期结果**：
   - test 端立即显示发送的消息
   - lisi 端会话列表显示新消息和未读计数
   - lisi 端打开聊天后消息立即显示
   - 未读计数清零

### 连续发送测试
1. 在同一个聊天窗口连续发送多条消息
2. **预期结果**：
   - 每条消息都能成功发送
   - 不需要切换页面
   - 消息按顺序显示

### 实时接收测试
1. test 和 lisi 同时打开对方的聊天窗口
2. test 发送消息
3. **预期结果**：
   - lisi 端立即显示消息
   - 不需要刷新页面
   - 消息自动滚动到底部

### 未读消息测试
1. lisi 在其他页面（如通讯录）
2. test 发送消息给 lisi
3. lisi 切换到消息页面
4. **预期结果**：
   - 会话列表显示未读数字（红色圆圈）
   - 点击进入聊天后未读清零

### WebSocket 重连测试
1. 发送消息时重启服务器
2. **预期结果**：
   - 客户端检测到断开
   - 自动尝试重连
   - 重连后可以继续发送

## 调试方法

### 查看客户端日志
在 Qt Creator 的"应用程序输出"窗口查看：
```
WebSocket connected for user: xxx
Sending message: {"action":"message","data":{"content":"hello","to":"xxx","type":"text"}}
WebSocket received: {"action":"message","data":{...}}
Received WS message, action: message
Message received: {"from":"xxx","to":"xxx","content":"hello",...}
```

### 查看服务端日志
在服务器控制台查看：
```
[GIN] POST /api/login
[GIN] GET /ws?user_id=xxx
WebSocket client connected: xxx
```

## 已知问题和限制

1. **WebSocket 重连**：目前只在发送消息时检查连接，未实现自动心跳保活
2. **离线消息**：用户离线时的消息需要重新登录后才能看到
3. **消息顺序**：高并发时可能出现消息顺序问题

## 后续改进建议

1. **心跳机制**：实现 ping/pong 保持连接
2. **离线消息推送**：登录时主动拉取离线消息
3. **消息确认**：添加消息发送成功/失败的确认机制
4. **重试机制**：发送失败时自动重试
5. **消息队列**：本地缓存未发送成功的消息
