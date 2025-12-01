# WebSocket 连接问题调试

## 问题描述
- 第一个登录的用户可以正常发送消息
- 后续登录的用户无法发送消息
- 重启客户端后问题依然存在

## 可能的原因

### 1. WebSocket 连接未正确建立
- 后续用户的 WebSocket 连接可能失败
- 连接建立了但未正确注册到 Hub

### 2. 消息发送通道阻塞
- `client.Send` 通道可能被阻塞
- 使用 `select` 和 `default` 避免阻塞

### 3. 锁的问题
- `SendToUser` 中持有读锁时发送消息可能导致死锁
- 修改为先释放锁再发送

## 修复方案

### 1. 改进 SendToUser 函数
```go
func (h *Hub) SendToUser(userID string, message []byte) {
    h.mu.RLock()
    client, ok := h.clients[userID]
    h.mu.RUnlock()  // 先释放锁

    if ok {
        select {
        case client.Send <- message:
            log.Printf("Message sent to user %s", userID)
        default:
            log.Printf("Failed to send message to user %s, channel full or closed", userID)
        }
    } else {
        log.Printf("User %s not connected", userID)
    }
}
```

### 2. 添加详细日志
在关键位置添加日志：
- WebSocket 连接请求
- 用户注册到 Hub
- 消息接收和发送
- 临时会话计数检查

## 调试步骤

### 1. 启动服务器并观察日志
```bash
cd server
go run cmd/server/main.go
```

### 2. 登录第一个用户（test）
观察日志输出：
```
WebSocket connection request from user: xxx
User xxx registered to hub
User xxx connected
```

### 3. 登录第二个用户（lisi）
观察日志输出：
```
WebSocket connection request from user: yyy
User yyy registered to hub
User yyy connected
```

### 4. test 发送消息给 lisi
观察日志：
```
Message from xxx to yyy: hello
Temp message count from xxx to yyy: 0
Saved temp message from xxx to yyy
Sending message to yyy and xxx
Message sent to user yyy
Message sent to user xxx
```

### 5. lisi 发送消息给 test
观察日志：
```
Message from yyy to xxx: hi
Temp message count from yyy to xxx: 0
Saved temp message from yyy to xxx
Sending message to xxx and yyy
Message sent to user xxx
Message sent to user yyy
```

## 预期日志输出

### 正常情况
```
[GIN] GET /ws?user_id=xxx
WebSocket connection request from user: xxx
User xxx registered to hub
User xxx connected

[GIN] GET /ws?user_id=yyy
WebSocket connection request from user: yyy
User yyy registered to hub
User yyy connected

Message from xxx to yyy: hello
Temp message count from xxx to yyy: 0
Saved temp message from xxx to yyy
Sending message to yyy and xxx
Message sent to user yyy
Message sent to user xxx
```

### 异常情况
如果看到：
```
User yyy not connected
```
说明 WebSocket 连接未建立或注册失败

如果看到：
```
Failed to send message to user yyy, channel full or closed
```
说明发送通道有问题

## 客户端检查

### 检查 WebSocket 连接状态
在客户端日志中查找：
```
WebSocket connected for user: xxx
Sending message: {"action":"message","data":{...}}
WebSocket received: {"action":"message","data":{...}}
```

### 检查连接是否断开
```
WebSocket disconnected
WebSocket error: ...
```

## 修改的文件
1. `server/internal/ws/hub.go` - 改进 SendToUser 函数
2. `server/internal/handler/handler_db.go` - 添加详细日志

## 测试方法

1. 重启服务器
2. 打开客户端1，登录 test
3. 打开客户端2，登录 lisi
4. test 发送消息给 lisi
5. 检查服务器日志和客户端日志
6. lisi 发送消息给 test
7. 检查服务器日志和客户端日志

如果问题依然存在，请提供完整的服务器日志输出。
