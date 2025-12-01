import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import FluentUI
import AtChat 1.0
import "../global"

FluPage {
    id: root
    title: qsTr("设置")

    property var colorData: [FluColors.Yellow, FluColors.Orange, FluColors.Red, FluColors.Magenta, FluColors.Purple, FluColors.Blue, FluColors.Teal, FluColors.Green]

    // SerialKeyInputBox 组件
    component SerialKeyInputBox: FluTextBox {
        id: serialKeyInputBox
        property int maxLength: 5
        property color textColor: FluTheme.fontPrimaryColor
        readonly property string allowedChars: "ABCDFGHJKMPQRTVWXYZ2346789"
        property var nextInput: null
        property var prevInput: null

        width: 110
        height: 40
        font.pixelSize: 14
        color: textColor
        horizontalAlignment: Text.AlignHCenter
        cleanEnabled: false

        onTextEdited: {
            var upperText = text.toUpperCase()
            var filtered = ""

            for (var i = 0; i < upperText.length && filtered.length < maxLength; i++) {
                if (allowedChars.indexOf(upperText[i]) !== -1) {
                    filtered += upperText[i]
                }
            }

            if (text !== filtered) {
                text = filtered
            }

            // 输满后自动跳转
            if (filtered.length === maxLength && nextInput) {
                nextInput.forceActiveFocus()
                nextInput.cursorPosition = 0
            }
        }

        Keys.onPressed: function(event) {
            // 左键
            if (event.key === Qt.Key_Left) {
                if (cursorPosition === 0 && prevInput) {
                    event.accepted = true
                    prevInput.forceActiveFocus()
                    prevInput.cursorPosition = prevInput.text.length
                }
                return
            }
            // 右键
            if (event.key === Qt.Key_Right) {
                if (cursorPosition === text.length && nextInput) {
                    event.accepted = true
                    nextInput.forceActiveFocus()
                    nextInput.cursorPosition = 0
                }
                return
            }
            // 退格键
            if (event.key === Qt.Key_Backspace && text.length === 0 && prevInput) {
                event.accepted = true
                prevInput.forceActiveFocus()
                prevInput.cursorPosition = prevInput.text.length
                return
            }
            // Ctrl+V 粘贴
            if (event.key === Qt.Key_V && (event.modifiers & Qt.ControlModifier)) {
                event.accepted = true
                serialKeyInputBox.pasteFullKey()
                return
            }
            // 字符输入溢出
            if (event.text.length > 0 && event.key !== Qt.Key_Backspace && event.key !== Qt.Key_Delete) {
                var chars = event.text.toUpperCase()
                if (allowedChars.indexOf(chars) !== -1) {
                    if (text.length >= maxLength && nextInput) {
                        event.accepted = true
                        nextInput.text = chars
                        nextInput.forceActiveFocus()
                        nextInput.cursorPosition = 1
                    }
                } else if (event.text.length > 0) {
                    event.accepted = true
                }
            }
        }

        function pasteFullKey() {
            clipboardHelper.refresh()
            var clipText = clipboardHelper.text
            if (clipText.length > 5) {
                root.distributeSerialKey(clipText, serialKeyInputBox)
            } else {
                serialKeyInputBox.paste()
            }
        }
    }

    // 获取剪贴板文本
    function getClipboardText() {
        return clipboardHelper.text
    }

    // 分配序列码到对应的4个输入框
    function distributeSerialKey(fullKey, sourceBox) {
        var cleaned = fullKey.toUpperCase().replace(/-/g, "")
        var allowedChars = "ABCDFGHJKMPQRTVWXYZ2346789"
        var filtered = ""
        for (var i = 0; i < cleaned.length && filtered.length < 20; i++) {
            if (allowedChars.indexOf(cleaned[i]) !== -1) {
                filtered += cleaned[i]
            }
        }
        // 找到第一个输入框
        var firstBox = sourceBox
        while (firstBox.prevInput) firstBox = firstBox.prevInput

        firstBox.text = filtered.substring(0, 5)
        if (firstBox.nextInput) {
            firstBox.nextInput.text = filtered.substring(5, 10)
            if (firstBox.nextInput.nextInput) {
                firstBox.nextInput.nextInput.text = filtered.substring(10, 15)
                if (firstBox.nextInput.nextInput.nextInput) {
                    firstBox.nextInput.nextInput.nextInput.text = filtered.substring(15, 20)
                }
            }
        }
    }

    // 剪贴板辅助
    TextEdit {
        id: clipboardHelper
        visible: false
        onTextChanged: { }
        Component.onCompleted: {
            selectAll()
        }
        function refresh() {
            text = ""
            paste()
        }
    }

    // 刷新剪贴板内容的定时器
    Timer {
        id: clipboardTimer
        interval: 50
        onTriggered: {
            clipboardHelper.refresh()
        }
    }

    Component.onCompleted: {
        clipboardHelper.refresh()
    }

    FluPivot {
        anchors {
            fill: parent
            topMargin: 10
            leftMargin: 10
            rightMargin: 10
        }

        // 外观设置
        FluPivotItem {
            title: qsTr("外观")
            contentItem: FluScrollablePage {
                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // 主题颜色
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        height: 160
                        padding: 10

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            FluText {
                                text: qsTr("主题颜色")
                                font: FluTextStyle.BodyStrong
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: root.colorData
                                    delegate: Rectangle {
                                        width: 42
                                        height: 42
                                        radius: 4
                                        color: mouse_item.containsMouse ? Qt.lighter(modelData.normal, 1.1) : modelData.normal
                                        border.color: modelData.darker
                                        border.width: 2

                                        FluIcon {
                                            anchors.centerIn: parent
                                            iconSource: FluentIcons.AcceptMedium
                                            iconSize: 15
                                            visible: modelData === FluTheme.accentColor
                                            color: FluTheme.dark ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1)
                                        }

                                        MouseArea {
                                            id: mouse_item
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                FluTheme.accentColor = modelData
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 10
                                FluText {
                                    text: qsTr("自定义颜色")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluColorPicker {
                                    id: color_picker
                                    current: FluTheme.accentColor.normal
                                    onAccepted: {
                                        FluTheme.accentColor = FluColors.createAccentColor(current)
                                    }
                                    FluIcon {
                                        anchors.centerIn: parent
                                        iconSource: FluentIcons.AcceptMedium
                                        iconSize: 15
                                        visible: {
                                            for (var i = 0; i < root.colorData.length; i++) {
                                                if (root.colorData[i] === FluTheme.accentColor) {
                                                    return false
                                                }
                                            }
                                            return true
                                        }
                                        color: FluTheme.dark ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1)
                                    }
                                }
                            }
                        }
                    }

                    // 深色模式
                    FluFrame {
                        Layout.fillWidth: true
                        height: 128
                        padding: 10

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            FluText {
                                text: qsTr("深色模式")
                                font: FluTextStyle.BodyStrong
                            }

                            Repeater {
                                model: [
                                    {title: qsTr("跟随系统"), mode: FluThemeType.System},
                                    {title: qsTr("浅色"), mode: FluThemeType.Light},
                                    {title: qsTr("深色"), mode: FluThemeType.Dark}
                                ]
                                delegate: FluRadioButton {
                                    checked: FluTheme.darkMode === modelData.mode
                                    text: modelData.title
                                    clickListener: function() {
                                        FluTheme.darkMode = modelData.mode
                                    }
                                }
                            }
                        }
                    }

                    // 其他外观选项
                    FluFrame {
                        Layout.fillWidth: true
                        height: 200
                        padding: 10

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15

                            Row {
                                width: parent.width
                                spacing: 10
                                FluText {
                                    text: qsTr("原生文本渲染")
                                    width: 150
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluToggleSwitch {
                                    checked: FluTheme.nativeText
                                    onClicked: {
                                        FluTheme.nativeText = !FluTheme.nativeText
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 10
                                FluText {
                                    text: qsTr("启用动画")
                                    width: 150
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluToggleSwitch {
                                    checked: FluTheme.animationEnabled
                                    onClicked: {
                                        FluTheme.animationEnabled = !FluTheme.animationEnabled
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 10
                                FluText {
                                    text: qsTr("窗口模糊效果")
                                    width: 150
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluToggleSwitch {
                                    id: toggle_blur
                                    checked: FluTheme.blurBehindWindowEnabled
                                    onClicked: {
                                        FluTheme.blurBehindWindowEnabled = !FluTheme.blurBehindWindowEnabled
                                    }
                                }
                            }
                        }
                    }

                    // 窗口效果
                    FluFrame {
                        Layout.fillWidth: true
                        padding: 10

                        ColumnLayout {
                            width: parent.width
                            spacing: 10

                            FluText {
                                text: qsTr("窗口效果")
                                font: FluTextStyle.BodyStrong
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 10
                                Repeater {
                                    model: window.availableEffects
                                    delegate: FluRadioButton {
                                        checked: window.effect === modelData
                                        text: modelData
                                        clickListener: function() {
                                            window.effect = modelData
                                            if (window.effective) {
                                                FluTheme.blurBehindWindowEnabled = false
                                            }
                                        }
                                    }
                                }
                            }

                            Row {
                                visible: FluTheme.blurBehindWindowEnabled || window.effect === "dwm-blur"
                                spacing: 10
                                FluText {
                                    text: qsTr("窗口透明度")
                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluSlider {
                                    width: 200
                                    to: 1
                                    stepSize: 0.1
                                    Component.onCompleted: value = window.tintOpacity
                                    onMoved: window.tintOpacity = value
                                }
                            }

                            Row {
                                visible: FluTheme.blurBehindWindowEnabled
                                spacing: 10
                                FluText {
                                    text: qsTr("模糊半径")
                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluSlider {
                                    width: 200
                                    to: 100
                                    stepSize: 1
                                    Component.onCompleted: value = window.blurRadius
                                    onMoved: window.blurRadius = value
                                }
                            }
                        }
                    }
                }
            }
        }

        // 通用设置
        FluPivotItem {
            title: qsTr("通用")
            contentItem: FluScrollablePage {
                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // 导航视图模式
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        height: 160
                        padding: 10

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            FluText {
                                text: qsTr("导航视图显示模式")
                                font: FluTextStyle.BodyStrong
                            }

                            Repeater {
                                model: [
                                    {title: qsTr("开放"), mode: FluNavigationViewType.Open},
                                    {title: qsTr("紧凑"), mode: FluNavigationViewType.Compact},
                                    {title: qsTr("极简"), mode: FluNavigationViewType.Minimal},
                                    {title: qsTr("自动"), mode: FluNavigationViewType.Auto}
                                ]
                                delegate: FluRadioButton {
                                    text: modelData.title
                                    checked: GlobalModel.displayMode === modelData.mode
                                    clickListener: function() {
                                        GlobalModel.displayMode = modelData.mode
                                    }
                                }
                            }
                        }
                    }

                    // 窗口设置
                    FluFrame {
                        Layout.fillWidth: true
                        height: 120
                        padding: 10

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15

                            Row {
                                width: parent.width
                                spacing: 10
                                FluText {
                                    text: qsTr("使用系统标题栏")
                                    width: 150
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluToggleSwitch {
                                    checked: FluApp.useSystemAppBar
                                    onClicked: {
                                        FluApp.useSystemAppBar = !FluApp.useSystemAppBar
                                        dialog_restart.open()
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 10
                                FluText {
                                    text: qsTr("沉浸式标题栏")
                                    width: 150
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluToggleSwitch {
                                    checked: window.fitsAppBarWindows
                                    onClicked: {
                                        window.fitsAppBarWindows = !window.fitsAppBarWindows
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 产品激活
        FluPivotItem {
            title: qsTr("激活")
            contentItem: FluScrollablePage {
                ColumnLayout {
                    width: parent.width
                    spacing: 20

                    // 激活状态显示
                    FluFrame {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        padding: 20

                        ColumnLayout {
                            width: parent.width
                            spacing: 15

                            FluText {
                                text: qsTr("许可证状态")
                                font: FluTextStyle.BodyStrong
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 20
                                rowSpacing: 10

                                FluText { text: qsTr("状态：") }
                                FluText {
                                    text: LicenseManager.statusText
                                    color: LicenseManager.isActivated ?
                                            (LicenseManager.isExpired ? "red" : "green")
                                                :
                                            (LicenseManager.isTrial ? "orange" : "red")
                                    font: FluTextStyle.BodyStrong
                                }

                                FluText { text: qsTr("版本：") }
                                FluText { text: LicenseManager.sku }

                                FluText {
                                    text: qsTr("到期时间：")
                                    visible: LicenseManager.isActivated || LicenseManager.isTrial
                                }
                                FluText {
                                    text: LicenseManager.isActivated ? LicenseManager.expireDate : LicenseManager.trialEndDate
                                    visible: LicenseManager.isActivated || LicenseManager.isTrial
                                }

                                FluText {
                                    text: qsTr("序列码：")
                                    visible: LicenseManager.isActivated
                                }
                                FluText {
                                    text: {
                                        var key = LicenseManager.serialKey
                                        if (key.length >= 23) {
                                            return key.substring(0, 2) + "***-" +
                                                   key.substring(6, 8) + "***-" +
                                                   key.substring(12, 14) + "***-" +
                                                   key.substring(18, 20) + "***"
                                        }
                                        return key
                                    }
                                    visible: LicenseManager.isActivated
                                }
                            }
                        }
                    }

                    // 激活输入区域
                    FluFrame {
                        Layout.fillWidth: true
                        padding: 20
                        visible: !LicenseManager.isActivated

                        ColumnLayout {
                            width: parent.width
                            spacing: 20

                            FluText {
                                text: qsTr("产品激活")
                                font: FluTextStyle.BodyStrong
                            }

                            Row {
                                spacing: 10
                                FluText {
                                    text: qsTr("版本类型：")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluComboBox {
                                    id: sku_combo
                                    width: 180
                                    model: ListModel {
                                        ListElement { text: "Community Edition"; skuId: 10 }
                                        ListElement { text: "Professional Edition"; skuId: 240 }
                                        ListElement { text: "Server Edition"; skuId: 255 }
                                    }
                                    textRole: "text"
                                    currentIndex: 0
                                }
                            }

                            ColumnLayout {
                                spacing: 10

                                FluText { text: qsTr("请输入序列码：") }

                                Row {
                                    spacing: 5

                                    SerialKeyInputBox {
                                        id: keyInput1
                                        nextInput: keyInput2
                                    }
                                    FluText { text: "-"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }

                                    SerialKeyInputBox {
                                        id: keyInput2
                                        prevInput: keyInput1
                                        nextInput: keyInput3
                                    }
                                    FluText { text: "-"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }

                                    SerialKeyInputBox {
                                        id: keyInput3
                                        prevInput: keyInput2
                                        nextInput: keyInput4
                                    }
                                    FluText { text: "-"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }

                                    SerialKeyInputBox {
                                        id: keyInput4
                                        prevInput: keyInput3
                                    }
                                }

                                FluText {
                                    text: qsTr("允许的字符: ") + keyInput1.allowedChars
                                    font.pixelSize: 10
                                    color: FluTheme.fontSecondaryColor
                                }

                                FluText {
                                    text: qsTr("提示：可以直接粘贴完整序列码到第一个输入框")
                                    font.pixelSize: 10
                                    color: FluTheme.fontSecondaryColor
                                }
                            }

                            Row {
                                spacing: 10
                                FluText {
                                    text: qsTr("用户信息（可选）：")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                FluTextBox {
                                    id: userInfoInput
                                    width: 250
                                    placeholderText: qsTr("邮箱或其他标识")
                                }
                            }

                            Row {
                                spacing: 10

                                FluFilledButton {
                                    text: qsTr("激活")
                                    onClicked: {
                                        // 验证输入完整性
                                        if (keyInput1.text.length !== 5 || keyInput2.text.length !== 5 ||
                                            keyInput3.text.length !== 5 || keyInput4.text.length !== 5) {
                                            dialog_activation.title = qsTr("输入错误")
                                            dialog_activation.message = qsTr("请输入完整的序列码（每段5个字符）")
                                            dialog_activation.open()
                                            return
                                        }

                                        var fullKey = keyInput1.text + "-" + keyInput2.text + "-" + keyInput3.text + "-" + keyInput4.text
                                        var skuId = sku_combo.model.get(sku_combo.currentIndex).skuId
                                        var userInfo = userInfoInput.text.trim()

                                        if (LicenseManager.activate(fullKey, skuId, userInfo)) {
                                            keyInput1.textColor = "green"
                                            keyInput2.textColor = "green"
                                            keyInput3.textColor = "green"
                                            keyInput4.textColor = "green"
                                            dialog_activation.title = qsTr("激活成功")
                                            dialog_activation.message = qsTr("产品已成功激活！")
                                            dialog_activation.open()
                                        } else {
                                            keyInput1.textColor = "red"
                                            keyInput2.textColor = "red"
                                            keyInput3.textColor = "red"
                                            keyInput4.textColor = "red"
                                            dialog_activation.title = qsTr("激活失败")
                                            dialog_activation.message = qsTr("序列码无效，请检查后重试。")
                                            dialog_activation.open()
                                        }
                                    }
                                }

                                FluButton {
                                    text: qsTr("开始试用")
                                    visible: !LicenseManager.isTrial && !LicenseManager.trialUsed
                                    onClicked: {
                                        if (LicenseManager.startTrial()) {
                                            showSuccess(qsTr("试用已开始，有效期7天"))
                                        } else {
                                            showError(qsTr("试用已过期或已使用"))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 已激活时显示许可证管理
                    FluFrame {
                        Layout.fillWidth: true
                        padding: 20
                        visible: LicenseManager.isActivated

                        ColumnLayout {
                            width: parent.width
                            spacing: 15

                            FluText {
                                text: qsTr("许可证管理")
                                font: FluTextStyle.BodyStrong
                            }

                            Row {
                                spacing: 10

                                FluButton {
                                    text: qsTr("更改许可证")
                                    onClicked: {
                                        changeLicensePanel.visible = !changeLicensePanel.visible
                                    }
                                }

                                FluButton {
                                    text: qsTr("删除许可证")
                                    onClicked: {
                                        dialog_remove_license.open()
                                    }
                                }
                            }

                            // 可折叠的更改许可证面板
                            ColumnLayout {
                                id: changeLicensePanel
                                visible: false
                                spacing: 10
                                Layout.fillWidth: true

                                Row {
                                    spacing: 10
                                    FluText {
                                        text: qsTr("版本类型：")
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    FluComboBox {
                                        id: change_sku_combo
                                        width: 180
                                        model: ListModel {
                                            ListElement { text: "Community Edition"; skuId: 10 }
                                            ListElement { text: "Professional Edition"; skuId: 240 }
                                            ListElement { text: "Server Edition"; skuId: 255 }
                                        }
                                        textRole: "text"
                                        currentIndex: 0
                                    }
                                }

                                FluText { text: qsTr("新序列码：") }
                                Row {
                                    spacing: 5
                                    SerialKeyInputBox {
                                        id: changeKeyInput1
                                        nextInput: changeKeyInput2
                                    }
                                    FluText { text: "-"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                                    SerialKeyInputBox {
                                        id: changeKeyInput2
                                        prevInput: changeKeyInput1
                                        nextInput: changeKeyInput3
                                    }
                                    FluText { text: "-"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                                    SerialKeyInputBox {
                                        id: changeKeyInput3
                                        prevInput: changeKeyInput2
                                        nextInput: changeKeyInput4
                                    }
                                    FluText { text: "-"; font.pixelSize: 20; anchors.verticalCenter: parent.verticalCenter }
                                    SerialKeyInputBox {
                                        id: changeKeyInput4
                                        prevInput: changeKeyInput3
                                    }
                                }

                                Row {
                                    spacing: 10
                                    FluText {
                                        text: qsTr("用户信息（可选）：")
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    FluTextBox {
                                        id: changeUserInfoInput
                                        width: 250
                                        placeholderText: qsTr("邮箱或其他标识")
                                    }
                                }

                                FluFilledButton {
                                    text: qsTr("确认更改")
                                    onClicked: {
                                        // 验证输入完整性
                                        if (changeKeyInput1.text.length !== 5 || changeKeyInput2.text.length !== 5 ||
                                            changeKeyInput3.text.length !== 5 || changeKeyInput4.text.length !== 5) {
                                            dialog_activation.title = qsTr("输入错误")
                                            dialog_activation.message = qsTr("请输入完整的序列码（每段5个字符）")
                                            dialog_activation.open()
                                            return
                                        }

                                        var fullKey = changeKeyInput1.text + "-" + changeKeyInput2.text + "-" + changeKeyInput3.text + "-" + changeKeyInput4.text
                                        var skuId = change_sku_combo.model.get(change_sku_combo.currentIndex).skuId
                                        var userInfo = changeUserInfoInput.text.trim()

                                        if (LicenseManager.activate(fullKey, skuId, userInfo)) {
                                            changeKeyInput1.text = ""
                                            changeKeyInput2.text = ""
                                            changeKeyInput3.text = ""
                                            changeKeyInput4.text = ""
                                            changeUserInfoInput.text = ""
                                            changeLicensePanel.visible = false
                                            dialog_activation.title = qsTr("更改成功")
                                            dialog_activation.message = qsTr("许可证已成功更改！")
                                            dialog_activation.open()
                                        } else {
                                            dialog_activation.title = qsTr("更改失败")
                                            dialog_activation.message = qsTr("序列码无效，请检查后重试。")
                                            dialog_activation.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 关于
        FluPivotItem {
            title: qsTr("关于")
            contentItem: FluScrollablePage {
                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    FluFrame {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        padding: 20

                        ColumnLayout {
                            width: parent.width
                            spacing: 15

                            // Logo 和标题
                            Row {
                                spacing: 15
                                FluImage {
                                    width: 64
                                    height: 64
                                    source: "qrc:/res/fav.png"
                                }
                                Column {
                                    spacing: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    FluText {
                                        text: "AtChat"
                                        font: FluTextStyle.Title
                                    }
                                    FluText {
                                        text: qsTr("版本 %1").arg(AppInfo.version)
                                        font: FluTextStyle.Caption
                                        color: FluTheme.fontSecondaryColor
                                    }
                                }
                            }

                            // 信息列表
                            GridLayout {
                                columns: 2
                                columnSpacing: 10
                                rowSpacing: 10
                                Layout.topMargin: 10

                                FluText { text: qsTr("作者："); Layout.preferredWidth: 60 }
                                FluText { text: "Lily King" }

                                FluText { text: "QQ："; Layout.preferredWidth: 60 }
                                FluText { text: "1921033794" }

                                FluText { text: "GitHub："; Layout.preferredWidth: 60 }
                                FluTextButton {
                                    text: "https://github.com/LilyKing6"
                                    onClicked: Qt.openUrlExternally(text)
                                }

                                FluText { text: qsTr("邮箱："); Layout.preferredWidth: 60 }
                                FluTextButton {
                                    text: "lilyking0504@gmail.com"
                                    onClicked: Qt.openUrlExternally("mailto:" + text)
                                }
                            }

                            FluText {
                                id: text_developing
                                text: qsTr("项目开发中......")
                                Layout.topMargin: 10
                                ColorAnimation {
                                    target: text_developing
                                    property: "textColor"
                                    from: "red"
                                    to: "blue"
                                    duration: 1000
                                    running: true
                                    loops: Animation.Infinite
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            // FluText {
                            //     text: qsTr("个人开发，维护不易，你们的捐赠就是我继续更新的动力！")
                            //     Layout.topMargin: 10
                            //     wrapMode: Text.WordWrap
                            //     Layout.fillWidth: true
                            // }
                        }
                    }

                    // TimeBomb 信息
                    FluFrame {
                        Layout.fillWidth: true
                        padding: 20

                        ColumnLayout {
                            width: parent.width
                            spacing: 15

                            FluText {
                                text: qsTr("版本信息")
                                font: FluTextStyle.BodyStrong
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 30
                                rowSpacing: 10

                                // FluText {
                                //     text: qsTr("版本：%1 \n(Build %2.%3.%4)")
                                //         .arg(AppInfo.core_version)
                                //         .arg(AppInfo.build_num)
                                //         .arg(AppInfo.build_type)
                                //         .arg(AppInfo.build_time)
                                // }
                                    // FluText {
                                    //     text: qsTr("版本：%1")
                                    //         .arg(AppInfo.core_version)
                                    // }
                                FluText { text: qsTr("版本：")}
                                FluText {
                                    text: qsTr("%1 (Build %2)")
                                        .arg(AppInfo.core_version)
                                        .arg(AppInfo.build_num)
                                    font: FluTextStyle.BodyStrong
                                }
                                FluText { text: qsTr("Full Version:")}
                                FluText {
                                    text: qsTr("%1.%2.%3")
                                    .arg(AppInfo.version)
                                    .arg(AppInfo.build_type)
                                    .arg(AppInfo.build_time)
                                }



                                FluText { text: qsTr("构建日期：") }
                                FluText { text: LicenseManager.buildDate }

                                FluText { text: qsTr("评估版到期：") }
                                FluText {
                                    text: LicenseManager.timeBombExpireDate
                                    color: LicenseManager.timeBombExpired ? "red" : FluTheme.fontPrimaryColor
                                }

                                FluText { text: qsTr("评估期状态：") }
                                FluText {
                                    text: LicenseManager.timeBombExpired ? qsTr("已过期") : qsTr("有效")
                                    color: LicenseManager.timeBombExpired ? "red" : "green"
                                    font: FluTextStyle.BodyStrong
                                }
                            }

                            FluText {
                                visible: LicenseManager.timeBombExpired
                                text: qsTr("评估版本已过期，请激活正式版本以继续使用。")
                                color: "red"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }

    // 重启确认对话框
    FluContentDialog {
        id: dialog_restart
        title: qsTr("需要重启")
        message: qsTr("此设置需要重启应用才能生效，是否立即重启？")
        buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
        negativeText: qsTr("取消")
        positiveText: qsTr("重启")
        onPositiveClicked: {
            FluRouter.exit(931)
        }
    }

    // 激活结果对话框
    FluContentDialog {
        id: dialog_activation
        buttonFlags: FluContentDialogType.PositiveButton
        positiveText: qsTr("确定")
    }

    // 删除许可证确认对话框
    FluContentDialog {
        id: dialog_remove_license
        title: qsTr("确认更改许可证")
        message: qsTr("确定要删除当前许可证吗？删除后需要重新激活。")
        buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
        negativeText: qsTr("取消")
        positiveText: qsTr("确定")
        onPositiveClicked: {
            LicenseManager.removeLicense()
        }
    }
}
