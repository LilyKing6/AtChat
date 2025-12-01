# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AtChat is a Qt6/QML desktop chat application (similar to QQ/WeChat) built with the FluentUI framework. It features:
- Modern Fluent Design interface
- Software licensing system (SPP)
- Go backend server with WebSocket real-time communication
- SQLite database for persistence
- Group chat and file sharing

## Project Structure

```
AtChat/
├── main.cpp                    # Qt application entry point
├── Main.qml                    # QML application launcher
├── CMakeLists.txt              # CMake build configuration
├── resource.qrc                # Qt resource file
├── res/                        # Icons and images
├── src/
│   ├── NetworkManager.cpp/h    # HTTP/WebSocket client
│   ├── LicenseManager.cpp/h    # License management
│   ├── SPP/                    # Serial key protection
│   └── TimeBomb/               # Evaluation period
├── qml/
│   ├── AppMainWindow.qml       # Main window with navigation
│   ├── global/                 # Singletons (GlobalModel, ItemsOriginal, ItemsFooter)
│   ├── page/                   # Pages (ChatPage, ContactsPage, NewSettings, LoginPage)
│   ├── component/              # Reusable components (LoginRequired)
│   └── window/                 # Window types
├── server/                     # Go backend server
│   ├── cmd/server/main.go      # Server entry point
│   ├── config.json             # Server configuration
│   ├── start.bat / start.sh    # Startup scripts
│   └── internal/
│       ├── db/db.go            # SQLite database
│       ├── model/              # Data models (user, message, group)
│       ├── service/            # Business logic
│       ├── handler/            # HTTP/WS handlers
│       └── ws/                 # WebSocket hub and client
└── tools/KeyGenerator/         # Serial key generator CLI
```

## Build System

### Client (Qt/C++)

- **Build tool**: CMake (minimum version 3.16)
- **Qt version**: Qt 6.8+ required
- **Language**: C++17 (with QML for UI)
- **Dependencies**: FluentUI, Qt6::Quick, Qt6::Network, Qt6::WebSockets

```bash
# Configure and build client
cmake -B build -S .
cmake --build build

# Executables: appAtChat, keygen
```

### Server (Go)

- **Go version**: 1.21+
- **Dependencies**: gin, gorilla/websocket, go-sqlite3, uuid

```bash
# Build and run server
cd server
go mod tidy
go build -o atchat-server ./cmd/server
./atchat-server -port 8080 -db atchat.db

# Or use startup script
./start.sh   # Linux/Mac
start.bat    # Windows
```

## Architecture

### Client Architecture

**Entry Point:**
- `main.cpp` - Registers singletons (LicenseManager, NetworkManager), loads QML
- `Main.qml` - Initializes FluentUI routing, navigates to AppMainWindow

**Core C++ Modules:**

1. **NetworkManager** (`src/NetworkManager.cpp/h`)
   - Singleton for all network communication
   - HTTP client for REST API calls
   - WebSocket client for real-time messaging
   - Properties: `connected`, `userId`, `username`, `nickname`
   - Methods:
     - Auth: `login()`, `registerUser()`, `logout()`
     - Users: `fetchUsers()`, `fetchHistory()`
     - Groups: `createGroup()`, `fetchGroups()`, `fetchGroupHistory()`, `sendGroupMessage()`
     - Files: `uploadFile()`
     - WebSocket: `connectWebSocket()`, `disconnectWebSocket()`, `sendMessage()`
   - Signals: `loginSuccess`, `messageReceived`, `groupMessageReceived`, `fileUploaded`, etc.

2. **LicenseManager** (`src/LicenseManager.cpp/h`)
   - Device-bound license storage with XOR encryption + SHA256 checksum
   - Properties: `isActivated`, `isTrial`, `isExpired`, `sku`, `skuId`, `serialKey`, `expireDate`, `trialEndDate`, `trialUsed`, `statusText`, `timeBombExpired`, `timeBombExpireDate`, `buildDate`
   - Methods: `activate(key, skuId, userInfo)`, `startTrial()`, `removeLicense()`, `getActivationStatus()`

3. **SPP (Software Protection Platform)** (`src/SPP/`)
   - `BigNumber.cpp/h` - Large integer arithmetic
   - `MiscUtils.cpp/h` - Hash functions, Base26 conversion
   - `GenerateKey.cpp/h` - Serial key generation
   - `ValidateKey.cpp/h` - Key validation with expiry
   - `SerialKey.cpp/h` - C API (SPPGenerateKey, SPPValidateKey)
   - `SKU.h` - SKU definitions (COMMUNITY=0x0A, PRO=0xF0, SRV=0xFF, TRIAL=0x05)

4. **TimeBomb** (`src/TimeBomb/`)
   - 60-day evaluation period based on compile-time macros

**QML Organization:**

1. **Singletons** (`qml/global/`)
   - `GlobalModel.qml` - Global state (navigation display mode)
   - `ItemsOriginal.qml` - Main navigation items (消息, 通讯录, 动态, 收藏, 文件)
   - `ItemsFooter.qml` - Footer items (设置)

2. **Pages** (`qml/page/`)
   - `ChatPage.qml` - Main chat interface
     - Left: Conversation list with search, avatars, unread badges, online status
     - Right: Chat area with message bubbles, toolbar, input box
     - Integrates with NetworkManager for real-time messaging
   - `ContactsPage.qml` - Contacts/friends list
     - Collapsible friend groups
     - Function entries (新朋友, 群聊, 标签)
     - Contact detail card with actions
   - `NewSettings.qml` - Settings with tabs
     - 外观: Theme color, dark mode, animations, window effects
     - 通用: Navigation mode, title bar options
     - 激活: License activation with serial key input
     - 关于: App info, TimeBomb status
   - `LoginPage.qml` - Login/register page

3. **Components** (`qml/component/`)
   - `LoginRequired.qml` - Login overlay for protected pages
     - Shows login dialog when user not authenticated
     - Used in ChatPage and ContactsPage

4. **Main Window** (`qml/AppMainWindow.qml`)
   - FluNavigationView with NoStack mode (memory efficient)
   - Navigation items from ItemsOriginal/ItemsFooter singletons

### Server Architecture

**Entry Point** (`cmd/server/main.go`):
- Initializes database, services, handlers
- Sets up Gin router with CORS
- Starts WebSocket hub
- Creates test accounts on startup

**Database** (`internal/db/db.go`):
- SQLite with tables: `users`, `messages`, `groups`, `group_members`
- Indexes on messages for performance
- Easy to migrate to PostgreSQL for production

**Models** (`internal/model/`):
- `user.go` - User, Message, WSMessage, LoginRequest/Response
- `group.go` - Group, GroupMember, GroupMessage, FileMessage

**Services** (`internal/service/`):
- `user_db.go` - User registration, login, password hashing
- `message_db.go` - Message storage and history retrieval
- `group.go` - Group CRUD, member management, group messages
- `file.go` - File upload and storage

**Handlers** (`internal/handler/`):
- `handler_db.go` - User/message HTTP handlers, WebSocket handler
- `group.go` - Group and file upload handlers

**WebSocket** (`internal/ws/`):
- `hub.go` - Connection management, broadcast, online status
- `client.go` - Read/write pumps, ping/pong

## API Reference

### REST API

**Authentication:**
```
POST /api/register     - Register new user
  Body: { "username": "", "password": "", "nickname": "" }
  Response: { "success": true, "user": {...} }

POST /api/login        - Login
  Body: { "username": "", "password": "" }
  Response: { "success": true, "token": "user_id", "user": {...} }
```

**Users:**
```
GET /api/users         - Get all users with online status
  Response: [{ "id": "", "username": "", "nickname": "", "online": true }, ...]

GET /api/history       - Get chat history between two users
  Query: ?user1=xxx&user2=xxx
  Response: [{ "id": "", "from": "", "to": "", "content": "", "timestamp": "" }, ...]
```

**Groups:**
```
POST /api/groups       - Create group
  Query: ?user_id=xxx
  Body: { "name": "", "members": ["user_id1", "user_id2"] }
  Response: { "success": true, "group": {...} }

GET /api/groups        - Get user's groups
  Query: ?user_id=xxx
  Response: [{ "id": "", "name": "", "owner_id": "" }, ...]

GET /api/groups/:id    - Get group info with members
  Response: { "id": "", "name": "", "members": [...] }

GET /api/groups/history - Get group chat history
  Query: ?group_id=xxx
  Response: [{ "id": "", "group_id": "", "from": "", "content": "" }, ...]

POST /api/groups/:id/members - Add member to group
  Query: ?user_id=xxx
```

**Files:**
```
POST /api/upload       - Upload file
  Body: multipart/form-data with "file" field
  Response: { "success": true, "file_name": "", "file_url": "/files/xxx", "mime_type": "" }

GET /files/:filename   - Access uploaded file (static)
```

### WebSocket

**Connection:**
```
ws://localhost:8080/ws?user_id=xxx
```

**Message Format:**
```json
{
  "action": "message|group_message|status|ping|pong",
  "data": { ... }
}
```

**Actions:**
- `message` - Private message: `{ "to": "user_id", "content": "", "type": "text" }`
- `group_message` - Group message: `{ "group_id": "", "content": "", "type": "text" }`
- `status` - User online/offline: `{ "user_id": "", "online": true }`
- `ping/pong` - Keep-alive

## Key Features

### 1. Real-time Messaging
- WebSocket connection for instant message delivery
- Online status tracking and broadcast
- Message history persistence in SQLite

### 2. Group Chat
- Create groups with multiple members
- Group message broadcast to all members
- Group history retrieval

### 3. File Sharing
- File upload via multipart form
- Unique filename generation
- Static file serving

### 4. License System
- Serial key format: XXXXX-XXXXX-XXXXX-XXXXX (Base26)
- SKU types: Community, Professional, Server, Trial
- Device-bound activation (prevents license copying)
- Optional user info binding (email)
- 7-day trial period
- 60-day TimeBomb evaluation

### 5. Login Protection
- LoginRequired component overlays protected pages
- Login dialog with register option
- Test account: test / test

## FluentUI Components Used

- **Layout**: FluWindow, FluAppBar, FluNavigationView, FluFrame, FluPivot, FluScrollablePage
- **Input**: FluTextBox, FluPasswordBox, FluComboBox, FluSlider, FluToggleSwitch, FluRadioButton, FluMultilineTextBox
- **Display**: FluText, FluIcon, FluImage
- **Buttons**: FluButton, FluFilledButton, FluIconButton, FluTextButton
- **Dialogs**: FluContentDialog
- **Other**: FluColorPicker, FluMenu, FluMenuItem

## Database Schema

```sql
-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    nickname TEXT,
    avatar TEXT,
    signature TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Messages table (private and group)
CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    from_user TEXT NOT NULL,
    to_user TEXT NOT NULL,  -- "group:xxx" for group messages
    content TEXT,
    type TEXT DEFAULT 'text',
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Groups table
CREATE TABLE groups (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    avatar TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Group members table
CREATE TABLE group_members (
    group_id TEXT,
    user_id TEXT,
    role TEXT DEFAULT 'member',  -- owner, admin, member
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id)
);
```

## Configuration

### Server Config (`server/config.json`)
```json
{
    "host": "0.0.0.0",
    "port": 8080,
    "database": {
        "driver": "sqlite",
        "path": "atchat.db"
    },
    "jwt_secret": "change_in_production"
}
```

### Command Line Arguments
```bash
./atchat-server -port 8080 -db atchat.db
```

## Known Issues & Solutions

1. **FluSlider Binding Loop**
   - Problem: `value: window.property` causes binding loop
   - Solution: Use `Component.onCompleted: value = window.property` + `onMoved: window.property = value`

2. **Clipboard Paste in QML**
   - Problem: No direct clipboard access in QML
   - Solution: Use hidden TextEdit helper with `paste()` method

3. **ComboBox Text Not Showing**
   - Problem: JS array model doesn't show text in dropdown
   - Solution: Use ListModel with `textRole: "text"`

4. **SQLite CGO on Windows**
   - Problem: go-sqlite3 requires CGO
   - Solution: Install MinGW-w64, set `CGO_ENABLED=1`

## Future Improvements

1. **Security**
   - JWT token authentication
   - HTTPS/WSS support
   - Password strength validation
   - Rate limiting

2. **Features**
   - Voice/video calls (WebRTC)
   - Message read receipts
   - Message reactions
   - User profiles and avatars
   - Push notifications
   - Message search

3. **Scalability**
   - PostgreSQL for production
   - Redis for session/cache
   - Message queue for async processing
   - Horizontal scaling with load balancer

4. **Client**
   - Offline message queue
   - Local message cache
   - Image preview and compression
   - Emoji picker
   - Message formatting (markdown)

## Test Accounts

Pre-created accounts for testing:
- `test` / `test` - 测试用户
- `zhangsan` / `123456` - 张三
- `lisi` / `123456` - 李四
