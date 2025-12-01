#ifndef LICENSEMANAGER_H
#define LICENSEMANAGER_H

#include <QObject>
#include <QString>
#include <QQmlEngine>
#include <QCryptographicHash>
#include <QSettings>
#include <QSysInfo>

class LicenseManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isActivated READ isActivated NOTIFY licenseChanged)
    Q_PROPERTY(bool isTrial READ isTrial NOTIFY licenseChanged)
    Q_PROPERTY(bool isExpired READ isExpired NOTIFY licenseChanged)
    Q_PROPERTY(QString sku READ sku NOTIFY licenseChanged)
    Q_PROPERTY(int skuId READ skuId NOTIFY licenseChanged)
    Q_PROPERTY(QString serialKey READ serialKey NOTIFY licenseChanged)
    Q_PROPERTY(QString expireDate READ expireDate NOTIFY licenseChanged)
    Q_PROPERTY(QString trialEndDate READ trialEndDate NOTIFY licenseChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY licenseChanged)
    Q_PROPERTY(bool trialUsed READ trialUsed NOTIFY licenseChanged)

    // TimeBomb properties
    Q_PROPERTY(bool timeBombExpired READ timeBombExpired CONSTANT)
    Q_PROPERTY(QString timeBombExpireDate READ timeBombExpireDate CONSTANT)
    Q_PROPERTY(QString buildDate READ buildDate CONSTANT)

public:
    explicit LicenseManager(QObject *parent = nullptr);

    static LicenseManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

    bool isActivated() const;
    bool isTrial() const;
    bool isExpired() const;
    QString sku() const;
    int skuId() const;
    QString serialKey() const;
    QString expireDate() const;
    QString trialEndDate() const;
    QString statusText() const;
    bool trialUsed() const;

    bool timeBombExpired() const;
    QString timeBombExpireDate() const;
    QString buildDate() const;

    Q_INVOKABLE bool activate(const QString &key, int skuId, const QString &userInfo = QString());
    Q_INVOKABLE bool startTrial();
    Q_INVOKABLE void removeLicense();
    Q_INVOKABLE int getActivationStatus();

    // Status codes
    enum ActivationStatus {
        Activated = 0xFF,
        NotActivated = 0x01,
        Expired = 0x02,
        TrialExpired = 0x03,
        Trial = 0x0F,
        DataError = 0x00
    };
    Q_ENUM(ActivationStatus)

signals:
    void licenseChanged();
    void activationSuccess();
    void activationFailed(const QString &reason);

private:
    void loadLicenseData();
    void saveLicenseData();
    QString generateDeviceId();
    QString calculateChecksum(const QByteArray &data);
    bool verifyChecksum();
    int checkActivationStatus();

    QString m_sku;
    int m_skuId;
    QString m_serialKey;
    bool m_isActivated;
    QString m_expireDate;
    bool m_isTrial;
    QString m_trialStartDate;
    QString m_trialEndDate;
    int m_trialRecord;
    QString m_deviceId;

    static const int TRIAL_DAYS = 7;
    static const char* SECRET_KEY;
};

#endif
