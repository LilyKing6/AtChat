#ifndef APPINFO_H
#define APPINFO_H

#include <QObject>
#include <QQmlApplicationEngine>
#include <QString>
#include <QQmlEngine>
#include <QCryptographicHash>
#include <QSettings>
#include <QSysInfo>


class AppInfo : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString core_version READ core_version CONSTANT)
    Q_PROPERTY(int build_num READ build_num CONSTANT)
    Q_PROPERTY(QString build_type READ build_type CONSTANT)
    Q_PROPERTY(QString sys_name READ sys_name CONSTANT)

    Q_PROPERTY(int build_year READ build_year CONSTANT)
    Q_PROPERTY(int build_month READ build_month CONSTANT)
    Q_PROPERTY(int build_day READ build_day CONSTANT)
    Q_PROPERTY(int build_hour READ build_hour CONSTANT)
    Q_PROPERTY(int build_minute READ build_minute CONSTANT)

    Q_PROPERTY(QString build_time READ build_time CONSTANT)

public:
    explicit AppInfo(QObject *parent = nullptr);

    static AppInfo* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    QString version() const;
    QString core_version() const;
    int build_num() const;
    QString build_type() const;
    QString sys_name() const;

    int build_year() const;
    int build_month() const;
    int build_day() const;
    int build_hour() const;
    int build_minute() const;

    QString build_time() const;

};


#endif // APPINFO_H
