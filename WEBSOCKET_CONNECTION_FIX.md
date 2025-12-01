# WebSocket 连接问题最终修复

## 问题根源

### 日志分析
```
User 9c7f965c-0eea-4b0d-9e93-23ea530337bf not connected
```

**说明：** test 用户的 WebSocket 根本没有连接到服务器！

### 原因
1. **登录后立即连接 WebSocket**：可能在网络请求还未完全完成时就尝试连接
2. **没有检查旧连接**：如果之前有连接，没有先断开
3. **缺少连接日志**：无法追踪连接是否成功建立

## 修复方案

### 1. 延迟连接 WebSocket
```cpp
void NetworkManager::login(...) {
    // ...登录成功后

    // 先断开旧连接
    if (m_ws->state() == QAbstractSocket::ConnectedState) {
        m_ws->close();
    }

    emit userChanged();
    emit loginSuccess(user);

    // 延迟 500ms 连接 WebSocket
    QTimer::singleShot(500, this, [this]() {
        connectWebSocket();
    });
}
```

### 2. 改进 connectWebSocket
```cpp
void NetworkManager::connectWebSocket()
{
    if (m_userId.isEmpty()) {
        qDebug() << "Cannot connect WebSocket: userId is empty";
        return;
    }

    // 如果已连接，先断开
    if (m_ws->state() == QAbstractSocket::ConnectedState) {
        qDebug() << "WebSocket already connected, closing first";
        m_ws->close();
        QTimer::singleShot(100, this, &NetworkManager::connectWebSocket);
        return;
    }

    QString wsUrl = m_serverUrl;
    wsUrl.replace("http://", "ws://").replace("https://", "wss://");
    QString fullUrl = wsUrl + "/ws?user_id=" + m_userId;
    qDebug() << "Connecting WebSocket to:" << fullUrl;
    m_ws->open(QUrl(fullUrl));
}
```

### 3. 修复 ContactsPage 绑定循环
```qml
// 修复前
Column {
    property var friendsList: getFriendsByGroup(groupName)
    Repeater {
        model: parent.friendsList

// 修复后
Repeater {
    model: model.expanded ? getFriendsByGroup(groupName) : []
```

## 修改的文件

1. `src/NetworkManager.h` - 添加 QTimer 头文件
2. `src/NetworkManager.cpp` - 延迟连接 WebSocket，添加日志
3. `qml/page/ContactsPage.qml` - 修复绑定循环

## 测试步骤

### 1. 重新编译客户端
```bash
cmake --build build
```

### 2. 启动服务器
```bash
cd server
go run cmd/server/main.go
```

### 3. 测试连接顺序

#### 场景1：zhangsan 先登录，test 后登录
1. 启动客户端1，登录 zhangsan
   - **客户端日志应显示：**
   ```
   Connecting WebSocket to: ws://localhost:8080/ws?user_id=xxx
   WebSocket connected for user: xxx
   ```
   - **服务器日志应显示：**
   ```
   WebSocket connection request from user: xxx
   User xxx registered to hub
   User xxx connected
   ```

2. 启动客户端2，登录 test
   - **客户端日志应显示：**
   ```
   Connecting WebSocket to: ws://localhost:8080/ws?user_id=yyy
   WebSocket connected for user: yyy
   ```
   - **服务器日志应显示：**
   ```
   WebSocket connection request from user: yyy
   User yyy registered to hub
   User yyy connected
   ```

3. zhangsan 发送消息给 test
   - **服务器日志应显示：**
   ```
   Message from xxx to yyy: hello
   Sending message to yyy and xxx
   Message sent to user yyy
   Message sent to user xxx
   ```
   - **不应该看到：** "User yyy not connected"

4. test 发送消息给 zhangsan
   - **客户端日志应显示：**
   ```
   Sending message: {"action":"message","data":{...}}
   WebSocket received: {"action":"message","data":{...}}
   ```
   - **服务器日志应显示：**
   ```
   Message from yyy to xxx: hi
   Sending message to xxx and yyy
   Message sent to user xxx
   Message sent to user yyy
   ```

#### 场景2：test 先登录，zhangsan 后登录
重复上述测试，确保顺序无关

## 预期结果

✅ 所有用户都能正常连接 WebSocket
✅ 所有用户都能发送和接收消息
✅ 登录顺序不影响功能
✅ 客户端日志显示连接成功
✅ 服务器日志显示所有用户已连接
✅ 没有 "User xxx not connected" 错误
✅ 没有 QML 绑定循环警告

## 如果问题仍然存在

### 检查客户端日志
查找：
```
Connecting WebSocket to: ws://localhost:8080/ws?user_id=xxx
WebSocket connected for user: xxx
```

如果没有看到 "WebSocket connected"，说明连接失败。

### 检查服务器日志
查找：
```
WebSocket connection request from user: xxx
User xxx registered to hub
User xxx connected
```

如果没有看到这些日志，说明服务器没有收到连接请求。

### 可能的问题
1. **防火墙阻止**：检查防火墙设置
2. **端口占用**：确保 8080 端口可用
3. **网络问题**：尝试使用 127.0.0.1 而不是 localhost
4. **Qt WebSocket 模块**：确保正确链接了 Qt6::WebSockets

## 调试命令

### 检查服务器端口
```bash
netstat -an | grep 8080
```

### 测试 WebSocket 连接（使用 wscat）
```bash
npm install -g wscat
wscat -c ws://localhost:8080/ws?user_id=test123
```

如果能连接，说明服务器正常，问题在客户端。
