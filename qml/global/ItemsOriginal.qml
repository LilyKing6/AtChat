pragma Singleton

import QtQuick 2.15
import FluentUI

FluObject{

    property var navigationView
    property var paneItemMenu

    function rename(item, newName){
        if(newName && newName.trim().length>0){
            item.title = newName;
        }
    }

    FluPaneItem{
        id:item_chat
        title: qsTr("消息")
        menuDelegate: paneItemMenu
        icon: FluentIcons.Message
        url: "qrc:/qml/page/ChatPage.qml"
        onTap: {
            navigationView.push(url)
        }
    }

    FluPaneItem{
        id:item_contacts
        title: qsTr("通讯录")
        menuDelegate: paneItemMenu
        icon: FluentIcons.People
        url: "qrc:/qml/page/ContactsPage.qml"
        onTap: {
            navigationView.push(url)
        }
    }

    FluPaneItem{
        id:item_profile
        title: qsTr("个人中心")
        menuDelegate: paneItemMenu
        icon: FluentIcons.Contact
        url: "qrc:/qml/page/ProfilePage.qml"
        onTap: {
            navigationView.push(url)
        }
    }

    FluPaneItemSeparator{
        spacing:10
        size:1
    }

    FluPaneItem{
        title: qsTr("动态")
        menuDelegate: paneItemMenu
        icon: FluentIcons.Globe
        disabled: true
        onTap: {
            navigationView.push(url)
        }
    }

    FluPaneItem{
        title: qsTr("收藏")
        menuDelegate: paneItemMenu
        icon: FluentIcons.FavoriteStar
        disabled: true
        onTap: {
            navigationView.push(url)
        }
    }

    FluPaneItem{
        title: qsTr("文件")
        menuDelegate: paneItemMenu
        icon: FluentIcons.OpenFolderHorizontal
        disabled: true
        onTap: {
            navigationView.push(url)
        }
    }

    function getRecentlyAddedData(){
        var arr = []
        var items = navigationView.getItems();
        for(var i=0;i<items.length;i++){
            var item = items[i]
            if(item instanceof FluPaneItem && item.extra && item.extra.recentlyAdded){
                arr.push(item)
            }
        }
        arr.sort(function(o1,o2){ return o2.extra.order-o1.extra.order })
        return arr
    }

    function getRecentlyUpdatedData(){
        var arr = []
        var items = navigationView.getItems();
        for(var i=0;i<items.length;i++){
            var item = items[i]
            if(item instanceof FluPaneItem && item.extra && item.extra.recentlyUpdated){
                arr.push(item)
            }
        }
        return arr
    }

    function getSearchData(){
        if(!navigationView){
            return
        }
        var arr = []
        var items = navigationView.getItems();
        for(var i=0;i<items.length;i++){
            var item = items[i]
            if(item instanceof FluPaneItem){
                if (item.parent instanceof FluPaneItemExpander)
                {
                    arr.push({title:`${item.parent.title} -> ${item.title}`,key:item.key})
                }
                else
                    arr.push({title:item.title,key:item.key})
            }
        }
        return arr
    }

    function startPageByItem(data){
        navigationView.startPageByItem(data)
    }

}
