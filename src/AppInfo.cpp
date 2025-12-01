#include "AppInfo.h"
#include "Version.h"

#include <QQmlContext>
#include <QGuiApplication>


AppInfo::AppInfo(QObject *parent)
    : QObject{parent}
{

}

AppInfo* AppInfo::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    return new AppInfo();
}


QString AppInfo::version() const
{
    return QString(VERSION_PRODUCT);
}

QString AppInfo::core_version() const
{
    return QString(KERNEL_VERSION);
}

int AppInfo::build_num() const
{
    return VER_PRODUCTBUILD;
}


QString AppInfo::build_type() const
{
    return QString(VER_PRODUCTBUILD_TYPE);
}

QString AppInfo::sys_name() const
{
    return QString(SYSTEM_NAME);
}

int AppInfo::build_year() const
{
    return (BUILD_YEAR);
}

int AppInfo::build_month() const
{
    return (BUILD_MONTH);
}

int AppInfo::build_day() const
{
    return (BUILD_DAY);
}

int AppInfo::build_hour() const
{
    return (BUILD_HOUR);
}

int AppInfo::build_minute() const
{
    return (BUILD_MINUTE);
}

QString AppInfo::build_time() const
{
    return QString("%1%2%3-%4%5")
        .arg(BUILD_YEAR, 2, 10)
        .arg(BUILD_MONTH, 2, 10, QChar('0'))
        .arg(BUILD_DAY, 2, 10, QChar('0'))
        .arg(BUILD_HOUR, 2, 10, QChar('0'))
        .arg(BUILD_MINUTE, 2, 10, QChar('0'));
}
