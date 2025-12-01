# FluentUI 框架组件参考

本文档记录了 FluentUI 框架（位于 D:\Projects\Chat\FluentUI）的组件结构和使用方法，用于 AtChat 聊天客户端开发。

## 框架概览

- **组件总数**: 98 个 QML 组件
- **示例页面**: 50+ 个
- **Qt 版本**: Qt 6 (主分支) / Qt 5 (Qt5分支)
- **许可证**: MIT
- **源码位置**: `D:\Projects\Chat\FluentUI\src\Qt6\imports\FluentUI\Controls\`
- **示例位置**: `D:\Projects\Chat\FluentUI\example\qml\page\`
- **编译库位置**: `D:\DevEnv\Qt\6.9.2\mingw_64\qml\FluentUI`

## 聊天客户端核心组件

### 1. 消息气泡组件
**FluBubbleBox** - 聊天气泡核心组件
```qml
FluBubbleBox {
    attachTarget: messageButton        // 附加目标
    attachDirection: "top"             // 方向: top/right/bottom/left
    targetAlignRatio: 0.5              // 对齐比例 0-1
    triangleWidth: 30                  // 三角形宽度
    triangleHeight: 20                 // 三角形高度
    triangleOffsetRatio: 0.5           // 三角形偏移比例
}
```

### 2. 文本输入组件
**FluTextBox** - 单行输入框
```qml
FluTextBox {
    placeholderText: "搜索..."
    text: ""
    onTextChanged: { }
}
```

**FluMultilineTextBox** - 多行输入框（消息输入）
```qml
FluMultilineTextBox {
    placeholderText: "输入消息..."
    isCtrlEnterForNewline: false       // Ctrl+Enter 换行
    onCommit: (text) => {              // 提交回调
        sendMessage(text)
    }
}
```

**FluPasswordBox** - 密码输入框
**FluAutoSuggestBox** - 自动建议框（搜索、@提及）

### 3. 列表和滚动组件
**FluScrollablePage** - 可滚动页面（消息列表容器）
```qml
FluScrollablePage {
    title: "聊天"
    autoResetScroll: false
    // 内容自动放入 ColumnLayout
}
```

**FluTableView** - 表格视图（会话列表、好友列表）
```qml
FluTableView {
    columnSource: [
        { title: "头像", dataIndex: "avatar", width: 60 },
        { title: "昵称", dataIndex: "name", width: 150 },
        { title: "消息", dataIndex: "lastMsg", width: 300 }
    ]
    dataSource: chatListModel
}
```

**FluTreeView** - 树形视图（分组好友列表）
**FluScrollBar** - 自定义滚动条
**FluItemDelegate** - 列表项委托

### 4. 容器和卡片组件
**FluFrame** - 框架容器（消息卡片、内容容器）
```qml
FluFrame {
    width: parent.width
    height: 100
    padding: 10
    // 内容
}
```

**FluSheet** - 底部工作表（底部菜单、操作面板）
**FluContentDialog** - 内容对话框（确认、提示）
```qml
FluContentDialog {
    title: "确认"
    message: "确定要删除这条消息吗？"
    buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
    negativeText: "取消"
    positiveText: "删除"
    onPositiveClicked: { }
}
```

### 5. 按钮组件
- **FluButton** - 标准按钮
- **FluFilledButton** - 填充按钮（主要操作，如发送）
- **FluTextButton** - 文本按钮
- **FluIconButton** - 图标按钮（表情、附件、工具栏）
- **FluToggleButton** - 切换按钮

```qml
FluFilledButton {
    text: "发送"
    onClicked: { }
}

FluIconButton {
    iconSource: FluentIcons.Emoji2
    iconSize: 20
    onClicked: { }
}
```

### 6. 图标和文本组件
**FluIcon** - 图标（使用 FluentIcons.ttf 字体）
```qml
FluIcon {
    iconSource: FluentIcons.Send
    iconSize: 20
}
```

**FluText** - 文本（自动适应主题）
```qml
FluText {
    text: "消息内容"
    font: FluTextStyle.Body
}
```

**FluCopyableText** - 可复制文本

### 7. 通知和提示组件
**FluInfoBar** - 信息提示条（系统通知、消息提示）
```qml
showSuccess("发送成功")
showError("发送失败")
showInfo("新消息")
```

**FluTooltip** - 工具提示
**FluBadge** - 徽章（未读消息计数）
```qml
FluBadge {
    count: 99
    color: Qt.rgba(255, 0, 0, 1)
}
```

**FluProgressRing** - 进度环（加载动画）

### 8. 其他实用组件
- **FluToggleSwitch** - 开关（设置项）
- **FluDivider** - 分割线
- **FluImage** - 图片（头像、图片消息）
- **FluClip** - 裁剪容器（圆形头像）
- **FluMenu** - 右键菜单
- **FluCalendarPicker** - 日历选择器
- **FluTimePicker** - 时间选择器

## 导航和窗口组件

### 窗口组件
**FluWindow** - 基础窗口
```qml
FluWindow {
    id: window
    width: 1000
    height: 668
    title: "AtChat"
    launchMode: FluWindowType.SingleTask
    fitsAppBarWindows: true
}
```

**FluAppBar** - 应用栏（标题栏）
```qml
FluAppBar {
    title: "聊天"
    showDark: true
    darkClickListener: (button) => handleDarkChanged(button)
}
```

### 导航组件
**FluNavigationView** - 导航视图（侧边栏导航）
```qml
FluNavigationView {
    width: parent.width
    height: parent.height
    pageMode: FluNavigationViewType.NoStack  // NoStack 或 Stack
    items: ItemsOriginal                      // 导航项
    footerItems: ItemsFooter                  // 底部导航项
    logo: "qrc:/res/favicon.ico"
    title: "AtChat"
}
```

**FluPaneItem** - 导航项
```qml
FluPaneItem {
    title: "首页"
    icon: FluentIcons.Home
    url: "qrc:/qml/page/T_Home.qml"
    onTap: { navigationView.push(url) }
}
```

**FluPaneItemExpander** - 可展开导航项（分组）
**FluPaneItemSeparator** - 导航分隔符

## 主题系统

### FluTheme（全局主题对象）
```qml
// 在 Main.qml 中初始化
FluTheme.darkMode = FluThemeType.Light  // 或 Dark
FluTheme.enableAnimation = true
FluTheme.nativeText = true
FluTheme.primaryColor = FluColors.Blue

// 主题属性
FluTheme.dark                    // 是否深色模式
FluTheme.primaryColor            // 主色
FluTheme.backgroundColor         // 背景色
FluTheme.fontPrimaryColor        // 主文本颜色
FluTheme.fontSecondaryColor      // 次要文本颜色
```

### FluTextStyle（文本样式）
- `FluTextStyle.Title` - 标题
- `FluTextStyle.TitleLarge` - 大标题
- `FluTextStyle.Headline` - 标题行
- `FluTextStyle.Body` - 正文
- `FluTextStyle.BodyStrong` - 加粗正文
- `FluTextStyle.Caption` - 说明文字

### FluColors（颜色）
```qml
FluColors.Blue
FluColors.Green
FluColors.Red
FluColors.Orange
// ... 更多颜色
```

## 路由系统

### FluRouter（路由管理）
```qml
// 初始化路由表
FluRouter.routes = {
    "/": "qrc:/qml/AppMainWindow.qml",
    "/chat": "qrc:/qml/page/ChatPage.qml",
    "/settings": "qrc:/qml/page/Settings.qml"
}

// 导航
FluRouter.navigate("/chat", {userId: 123})

// 退出应用
FluRouter.exit()
```

## 推荐的聊天界面架构

```qml
FluWindow {
    id: window

    FluAppBar {
        // 标题栏
    }

    Row {
        // 左侧：会话列表
        FluFrame {
            width: 300
            FluTableView {
                // 会话列表
            }
        }

        // 中间：聊天区域
        Column {
            // 消息列表
            FluScrollablePage {
                Repeater {
                    model: messageModel
                    delegate: FluFrame {
                        // 消息气泡
                        FluBubbleBox {
                            // 消息内容
                        }
                    }
                }
            }

            // 输入区域
            Row {
                FluMultilineTextBox {
                    // 消息输入
                }
                FluFilledButton {
                    text: "发送"
                }
            }
        }

        // 右侧：用户信息（可选）
        FluFrame {
            width: 250
            // 用户详情
        }
    }
}
```

## 常用 FluentIcons 图标

```qml
FluentIcons.Home           // 首页
FluentIcons.Send           // 发送
FluentIcons.Emoji2         // 表情
FluentIcons.Attach         // 附件
FluentIcons.Contact        // 联系人
FluentIcons.Message        // 消息
FluentIcons.Settings       // 设置
FluentIcons.Search         // 搜索
FluentIcons.More           // 更多
FluentIcons.Delete         // 删除
FluentIcons.Edit           // 编辑
FluentIcons.ChromeBack     // 返回
FluentIcons.ChromeClose    // 关闭
```

## 示例代码参考位置

- **文本输入示例**: `D:\Projects\Chat\FluentUI\example\qml\page\T_TextBox.qml`
- **气泡框示例**: `D:\Projects\Chat\FluentUI\example\qml\page\T_BubbleBox.qml`
- **表格视图示例**: `D:\Projects\Chat\FluentUI\example\qml\page\T_TableView.qml`
- **对话框示例**: `D:\Projects\Chat\FluentUI\example\qml\page\T_ContentDialog.qml`
- **导航视图示例**: `D:\Projects\Chat\FluentUI\example\qml\App.qml`

## 最佳实践

1. **使用 NoStack 模式**：节省内存，适合聊天应用
2. **使用单例管理状态**：如 GlobalModel.qml
3. **使用 FluRouter**：统一路由管理
4. **使用 qrc 资源**：打包资源文件
5. **使用 FluTheme**：自动适配深色/浅色主题
6. **使用 FluentIcons**：统一图标风格

## 性能优化

1. **懒加载**：使用 `FluRemoteLoader` 或 `Loader` 的 `lazy: true`
2. **虚拟化列表**：大量数据使用 ListView 而非 Repeater
3. **异步加载**：图片等资源异步加载
4. **内存管理**：及时销毁不用的页面（NoStack 模式）
