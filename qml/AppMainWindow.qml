import QtQuick 2.15
import FluentUI

import "global"

FluWindow {
    id: window

    visible: true
    // title: "AtChat"
    width: 1000
    height: 668
    minimumWidth: 668
    minimumHeight: 320
    launchMode: FluWindowType.SingleTask
    fitsAppBarWindows: true

    // 标题栏
    appBar: FluAppBar {
        height: 30
        showDark: true
        darkClickListener: (button)=>handleDarkChanged(button)
        closeClickListener: ()=>{dialog_close.open()}
        z:7
    }

    closeListener: function (event) {
        dialog_close.open()
        // 取消窗口关闭
        event.accepted = false
    }

    // 窗口标题栏
    FluAppBar {
        id: title_bar
        title: window.title
        // 可以在resource.qrc中添加ico，把url复制过来，程序左上角就有图标了
        // icon: "qrc:/res/favicon.ico"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        showDark: true
        darkText: "深色"
    }

    Component{
        id: nav_item_right_menu
        FluMenu{
            width: 186
            FluMenuItem{
                text: qsTr("Open in Separate Window")
                font: FluTextStyle.Caption
                onClicked: {
                    FluRouter.navigate("/pageWindow",{title:modelData.title,url:modelData.url})
                }
            }
        }
    }

    Flipable{
        id: flipable
        anchors.fill: parent
        property bool flipped: false
        property real flipAngle: 0
        transform: Rotation {
            id: rotation
            origin.x: flipable.width/2
            origin.y: flipable.height/2
            axis { x: 0; y: 1; z: 0 }
            angle: flipable.flipAngle

        }
        states: State {
            PropertyChanges { target: flipable; flipAngle: 180 }
            when: flipable.flipped
        }
        transitions: Transition {
            NumberAnimation { target: flipable; property: "flipAngle"; duration: 1000 ; easing.type: Easing.OutCubic}
        }
        back: Item{
            anchors.fill: flipable
            visible: flipable.flipAngle !== 0
            Row{
                id:layout_back_buttons
                z:8
                anchors{
                    top: parent.top
                    left: parent.left
                    topMargin: FluTools.isMacos() ? 20 : 5
                    leftMargin: 5
                }
                FluIconButton{
                    iconSource: FluentIcons.ChromeBack
                    width: 30
                    height: 30
                    iconSize: 13
                    onClicked: {
                        flipable.flipped = false
                    }
                }
                FluIconButton{
                    iconSource: FluentIcons.Sync
                    width: 30
                    height: 30
                    iconSize: 13
                    onClicked: {
                        loader.reload()
                    }
                }
                Component.onCompleted: {
                    window.setHitTestVisible(layout_back_buttons)
                }
            }
            FluRemoteLoader{
                id:loader
                lazy: true
                anchors.fill: parent
                // source: "https://zhu-zichu.gitee.io/Qt_174_LieflatPage.qml"
                source: "qrc:/qml/page/LoginPage.qml"
            }
        }
        front: Item{
            id:page_front
            visible: flipable.flipAngle !== 180
            anchors.fill: flipable
            FluNavigationView{
                property int clickCount: 0
                id:nav_view
                width: parent.width
                height: parent.height
                z:999
                //Stack模式，每次切换都会将页面压入栈中，随着栈的页面增多，消耗的内存也越多，内存消耗多就会卡顿，这时候就需要按返回将页面pop掉，释放内存。该模式可以配合FluPage中的launchMode属性，设置页面的启动模式
                //                pageMode: FluNavigationViewType.Stack
                //NoStack模式，每次切换都会销毁之前的页面然后创建一个新的页面，只需消耗少量内存
                pageMode: FluNavigationViewType.NoStack
                items: ItemsOriginal
                footerItems:ItemsFooter
                topPadding:{
                    if(window.useSystemAppBar){
                        return 0
                    }
                    return FluTools.isMacos() ? 20 : 0
                }
                displayMode: GlobalModel.displayMode
                logo: "qrc:/res/favicon.ico"
                title: "AtChat"
                onLogoClicked:{
                    clickCount += 1
                    showSuccess("%1:%2".arg(qsTr("Click Time")).arg(clickCount))
                    if(clickCount === 5){
                        loader.reload()
                        flipable.flipped = true
                        clickCount = 0
                    }
                }
                // autoSuggestBox:FluAutoSuggestBox{
                //     iconSource: FluentIcons.Search
                //     items: ItemsOriginal.getSearchData()
                //     placeholderText: qsTr("Search")
                //     filter: (item) => item[textRole].toLowerCase().includes(text.toLowerCase())
                //     onItemClicked:
                //         (data)=>{
                //             ItemsOriginal.startPageByItem(data)
                //         }
                // }
                Component.onCompleted: {
                    ItemsOriginal.navigationView = nav_view
                    ItemsOriginal.paneItemMenu = nav_item_right_menu
                    ItemsFooter.navigationView = nav_view
                    ItemsFooter.paneItemMenu = nav_item_right_menu
                    window.setHitTestVisible(nav_view.buttonMenu)
                    window.setHitTestVisible(nav_view.buttonBack)
                    window.setHitTestVisible(nav_view.imageLogo)
                    setCurrentIndex(0)
                }
            }
        }
    }

    FluLoader{
        id: loader_reveal
        anchors.fill: parent
    }

    function distance(x1,y1,x2,y2){
        return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
    }

    function changeDark(){
        if(FluTheme.dark){
            FluTheme.darkMode = FluThemeType.Light
        }else{
            FluTheme.darkMode = FluThemeType.Dark
        }
    }


    // 退出软件确认提示框
    FluContentDialog {
        id: dialog_close
        title: "退出"
        message: "您确定要退出吗？"
        // negativeText: "最小化"
        // buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.NeutralButton
        //              | FluContentDialogType.PositiveButton
        neutralText: "取消"
        buttonFlags: FluContentDialogType.NeutralButton
                     | FluContentDialogType.PositiveButton
        // onNegativeClicked: {
        //     // window.hide()
        //     window.visibility = Window.Minimized
        // }
        positiveText: "确认"
        onPositiveClicked: {
            FluRouter.exit()
        }
    }

}
