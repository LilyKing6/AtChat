# WebSocket 连接问题测试计划

## 已实施的修复

### 客户端修复 (src/NetworkManager.cpp)
1. ✅ 登录成功后延迟 500ms 连接 WebSocket (第 76-78 行)
2. ✅ 连接前先断开旧连接 (第 68-70 行)
3. ✅ connectWebSocket() 检查已连接状态 (第 113-118 行)
4. ✅ 添加详细日志输出 (第 108, 114, 123 行)

### 服务端修复 (server/internal/ws/hub.go)
1. ✅ SendToUser 先释放读锁再发送 (第 73-75 行)
2. ✅ 使用 select 防止阻塞 (第 78-83 行)
3. ✅ 添加详细日志输出 (第 80, 82, 85 行)

## 测试步骤

### 准备工作
```bash
# 1. 重新编译客户端
cd D:\Projects\Chat\AtChat
cmake --build build --config Release

# 2. 启动服务器
cd server
go run cmd/server/main.go
```

### 测试场景 1：zhangsan 先登录，test 后登录

#### 步骤 1：启动第一个客户端（zhangsan）
1. 运行客户端
2. 登录账号：`zhangsan` / `123456`
3. **检查客户端控制台**，应该看到：
   ```
   Connecting WebSocket to: ws://localhost:8080/ws?user_id=xxx
   WebSocket connected for user: xxx
   ```
4. **检查服务器控制台**，应该看到：
   ```
   User xxx connected
   ```

#### 步骤 2：启动第二个客户端（test）
1. 运行第二个客户端实例
2. 登录账号：`test` / `test`
3. **检查客户端控制台**，应该看到：
   ```
   Connecting WebSocket to: ws://localhost:8080/ws?user_id=yyy
   WebSocket connected for user: yyy
   ```
4. **检查服务器控制台**，应该看到：
   ```
   User yyy connected
   ```

#### 步骤 3：zhangsan 发送消息给 test
1. 在 zhangsan 客户端，打开与 test 的聊天
2. 发送消息："你好"
3. **检查服务器控制台**，应该看到：
   ```
   Message sent to user yyy
   Message sent to user xxx
   ```
4. **不应该看到**：`User yyy not connected`
5. **检查 test 客户端**，应该收到消息

#### 步骤 4：test 发送消息给 zhangsan
1. 在 test 客户端，回复消息："你好"
2. **检查服务器控制台**，应该看到：
   ```
   Message sent to user xxx
   Message sent to user yyy
   ```
3. **检查 zhangsan 客户端**，应该收到消息

### 测试场景 2：test 先登录，zhangsan 后登录

重复场景 1 的步骤，但交换登录顺序。

### 测试场景 3：三个用户同时在线

#### 步骤 1：依次登录三个用户
1. 客户端 1：登录 `zhangsan` / `123456`
2. 客户端 2：登录 `test` / `test`
3. 客户端 3：登录 `lisi` / `123456`

#### 步骤 2：交叉发送消息
1. zhangsan → test："消息1"
2. test → lisi："消息2"
3. lisi → zhangsan："消息3"
4. test → zhangsan："消息4"

#### 步骤 3：验证
- 所有消息都应该成功发送和接收
- 服务器不应该出现 "User xxx not connected" 错误

### 测试场景 4：断线重连

#### 步骤 1：正常登录
1. 登录 `test` / `test`
2. 确认 WebSocket 已连接

#### 步骤 2：模拟断线
1. 关闭客户端
2. 等待 5 秒
3. 重新打开客户端并登录

#### 步骤 3：验证
- 应该能够正常重新连接
- 能够正常发送和接收消息

## 预期结果

### ✅ 成功标准
- [ ] 所有用户都能成功连接 WebSocket
- [ ] 登录顺序不影响消息发送功能
- [ ] 后登录的用户能正常发送和接收消息
- [ ] 服务器日志显示所有用户已连接
- [ ] 没有 "User xxx not connected" 错误
- [ ] 客户端日志显示 "WebSocket connected"
- [ ] 多用户场景下消息正常传递

### ❌ 失败标准
- 后登录的用户无法发送消息
- 服务器显示 "User xxx not connected"
- 客户端没有 "WebSocket connected" 日志
- 消息发送后对方收不到

## 如果测试失败

### 检查客户端日志
查找以下关键信息：
```
Connecting WebSocket to: ws://localhost:8080/ws?user_id=xxx
WebSocket connected for user: xxx
```

如果没有看到 "WebSocket connected"，说明连接失败。

### 检查服务器日志
查找以下关键信息：
```
User xxx connected
Message sent to user xxx
```

如果看到 "User xxx not connected"，说明服务器端没有注册该用户。

### 可能的问题

1. **端口被占用**
   ```bash
   # Windows
   netstat -ano | findstr :8080

   # 如果端口被占用，杀死进程或更换端口
   ```

2. **防火墙阻止**
   - 检查 Windows 防火墙设置
   - 临时关闭防火墙测试

3. **WebSocket 模块未正确链接**
   - 检查 CMakeLists.txt 是否包含 `Qt6::WebSockets`
   - 重新编译客户端

4. **延迟时间不够**
   - 如果 500ms 不够，可以尝试增加到 1000ms
   - 修改 NetworkManager.cpp 第 76 行

## 调试命令

### 测试服务器端口
```bash
# Windows
netstat -an | findstr :8080

# 应该看到 LISTENING 状态
```

### 使用 wscat 测试 WebSocket
```bash
# 安装 wscat
npm install -g wscat

# 测试连接
wscat -c ws://localhost:8080/ws?user_id=test123

# 如果能连接，说明服务器正常
```

### 查看客户端详细日志
在 main.cpp 中添加：
```cpp
qSetMessagePattern("[%{type}] %{file}:%{line} - %{message}");
```

## 测试记录

### 测试日期：____________________

| 测试场景 | 结果 | 备注 |
|---------|------|------|
| 场景1：zhangsan先登录 | ⬜ 通过 ⬜ 失败 | |
| 场景2：test先登录 | ⬜ 通过 ⬜ 失败 | |
| 场景3：三用户同时在线 | ⬜ 通过 ⬜ 失败 | |
| 场景4：断线重连 | ⬜ 通过 ⬜ 失败 | |

### 问题记录
```
（记录测试中发现的问题）
```

### 解决方案
```
（记录问题的解决方法）
```
