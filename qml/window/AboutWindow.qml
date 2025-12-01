import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FluentUI 1.0


FluWindow {

    id: window
    title: "关于"
    width: 600
    height: 580
    fixSize: true
    launchMode: FluWindowType.SingleTask

    ColumnLayout{
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 5

        RowLayout{
            Layout.topMargin: 10
            Layout.leftMargin: 15
            spacing: 14
            FluText{
                text:"AtChat"
                font: FluTextStyle.Title
                MouseArea{
                    anchors.fill: parent
                    onClicked: {
                        FluRouter.navigate("/")
                    }
                }
            }
            // FluText{
            //     text:"v%1".arg(AppInfo.version)
            //     font: FluTextStyle.Body
            //     Layout.alignment: Qt.AlignBottom
            // }
        }

        RowLayout{
            spacing: 14
            Layout.leftMargin: 15
            FluText{
                text:"作者："
            }
            FluText{
                text:"Lily King"
                Layout.alignment: Qt.AlignBottom
            }
        }

        RowLayout{
            spacing: 14
            Layout.leftMargin: 15
            FluText{
                text:"QQ："
            }
            FluText{
                text:"1921033794"
                Layout.alignment: Qt.AlignBottom
            }
            FluText{
                text:"(有啥问题可能不会马上回，但发了红包必须立马回......)"
            }
        }

        RowLayout{
            spacing: 14
            Layout.leftMargin: 15
            FluText{
                text:"GitHub："
            }
            FluTextButton{
                id:text_hublink
                topPadding:0
                bottomPadding:0
                text: "https://github.com/LilyKing6"
                Layout.alignment: Qt.AlignBottom
                onClicked: {
                    Qt.openUrlExternally(text_hublink.text)
                }
            }
        }

        RowLayout{
            spacing: 14
            Layout.leftMargin: 15
            FluText{
                text:"邮箱："
            }
            FluTextButton{
                topPadding:0
                bottomPadding:0
                text: "mailto:lilyking0504@gmail.com"
                Layout.alignment: Qt.AlignBottom
                onClicked: {
                    Qt.openUrlExternally(text)
                }
            }
        }

        RowLayout{
            spacing: 14
            Layout.leftMargin: 15
            FluText{
                id:text_info
                text: "项目开发中......"
                ColorAnimation {
                    id: animation
                    target: text_info
                    property: "color"
                    from: "red"
                    to: "blue"
                    duration: 1000
                    running: true
                    loops: Animation.Infinite
                    easing.type: Easing.InOutQuad
                }
            }
        }

        FluExpander {
            headerHeight: 60
            contentHeight: content_layout.implicitHeight
            headerDelegate: Component {
                Item {
                    RowLayout {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 15
                        }
                        spacing: 15
                        FluImage {
                            width: 20
                            height: 20
                            sourceSize.width: 20
                            sourceSize.height: 20
                            source: "qrc:/res/favicon.ico"
                        }
                        ColumnLayout {
                            spacing: 0
                            FluText {
                                text: "AtChat"
                            }
                            FluText {
                                text: "%1".arg(AppInfo.version)
                                textColor: FluTheme.fontSecondaryColor
                                font.pixelSize: 12
                            }
                        }
                    }
                    FluLoadingButton {
                        id: btn_checkupdate
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: 15
                        }
                        text: qsTr("Check for Activated")
                        onClicked: {
                            loading = true;
                            FluEventBus.post("checkUpdate");
                        }
                    }
                    FluEvent {
                        name: "checkUpdateFinish"
                        onTriggered: {
                            btn_checkupdate.loading = false;
                        }
                    }
                }
            }
            content: ColumnLayout {
                id: content_layout
                spacing: 0
                RowLayout {
                    Layout.topMargin: 15
                    Layout.leftMargin: 15
                    spacing: 0
                    FluText {
                        text: "序列码: "
                    }
                    FluTextButton {
                        text: "XXXXX-XXXXX-XXXXX-XXXXX"
                        onClicked: {
                            Qt.openUrlExternally(text);
                        }
                    }
                }
            }
        }



        RowLayout{
            spacing: 14
            Layout.leftMargin: 15
            Layout.topMargin: 20
            FluText{
                id:text_desc
                text:"个人开发，维护不易，你们的捐赠就是我继续更新的动力！\n有什么问题提Issues，只要时间充足我就会解决的！！"
            }
        }
    }
}
