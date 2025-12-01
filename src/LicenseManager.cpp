#include "LicenseManager.h"
#include "SPP/SerialKey.h"
#include "SPP/SKU.h"
#include "Version.h"
#include "TimeBomb/TimeBomb.h"

#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QDataStream>
#include <QDateTime>
#include <QNetworkInterface>

const char* LicenseManager::SECRET_KEY = VER_FLAGS;

LicenseManager::LicenseManager(QObject *parent)
    : QObject(parent)
    , m_sku(SKU_UNKNOWN_STR)
    , m_skuId(SKU_UNKNOWN)
    , m_serialKey(KEY_UNKNOWN)
    , m_isActivated(false)
    , m_expireDate(EXPIRED_DATE_UNKNOWN)
    , m_isTrial(false)
    , m_trialStartDate(DATE_UNKNOWN)
    , m_trialEndDate(DATE_UNKNOWN)
    , m_trialRecord(0)
{
    m_deviceId = generateDeviceId();
    loadLicenseData();
}

LicenseManager* LicenseManager::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    return new LicenseManager();
}

QString LicenseManager::generateDeviceId()
{
    QString hwInfo;
    hwInfo += QSysInfo::machineUniqueId();
    hwInfo += QSysInfo::productType();
    hwInfo += QSysInfo::currentCpuArchitecture();

    for (const QNetworkInterface &iface : QNetworkInterface::allInterfaces()) {
        if (!(iface.flags() & QNetworkInterface::IsLoopBack)) {
            hwInfo += iface.hardwareAddress();
            break;
        }
    }

    QByteArray hash = QCryptographicHash::hash(hwInfo.toUtf8(), QCryptographicHash::Sha256);
    return QString(hash.toHex()).left(40);
}

QString LicenseManager::calculateChecksum(const QByteArray &data)
{
    QByteArray combined = data + m_deviceId.toUtf8();
    return QString(QCryptographicHash::hash(combined, QCryptographicHash::Sha256).toHex());
}

void LicenseManager::loadLicenseData()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    QString filePath = dataPath + "/atchat.lic";

    QFile file(filePath);
    if (!file.exists()) {
        saveLicenseData();
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) return;

    QDataStream in(&file);
    in.setVersion(QDataStream::Qt_6_0);

    QString storedChecksum, storedDeviceId;
    QByteArray encryptedData;

    in >> storedChecksum >> storedDeviceId >> encryptedData;
    file.close();

    if (storedDeviceId != m_deviceId) {
        m_isActivated = false;
        m_isTrial = false;
        saveLicenseData();
        return;
    }

    QByteArray key = QCryptographicHash::hash(m_deviceId.toUtf8(), QCryptographicHash::Md5);
    QByteArray decrypted;
    for (int i = 0; i < encryptedData.size(); ++i) {
        decrypted.append(encryptedData[i] ^ key[i % key.size()]);
    }

    if (calculateChecksum(decrypted) != storedChecksum) {
        m_isActivated = false;
        saveLicenseData();
        return;
    }

    QDataStream dataIn(&decrypted, QIODevice::ReadOnly);
    dataIn >> m_sku >> m_skuId >> m_serialKey >> m_isActivated
           >> m_expireDate >> m_isTrial >> m_trialStartDate
           >> m_trialEndDate >> m_trialRecord;

    emit licenseChanged();
}

void LicenseManager::saveLicenseData()
{
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataPath);
    QString filePath = dataPath + "/atchat.lic";

    QByteArray data;
    QDataStream dataOut(&data, QIODevice::WriteOnly);
    dataOut << m_sku << m_skuId << m_serialKey << m_isActivated
            << m_expireDate << m_isTrial << m_trialStartDate
            << m_trialEndDate << m_trialRecord;

    QByteArray key = QCryptographicHash::hash(m_deviceId.toUtf8(), QCryptographicHash::Md5);
    QByteArray encrypted;
    for (int i = 0; i < data.size(); ++i) {
        encrypted.append(data[i] ^ key[i % key.size()]);
    }

    QString checksum = calculateChecksum(data);

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) return;

    QDataStream out(&file);
    out.setVersion(QDataStream::Qt_6_0);
    out << checksum << m_deviceId << encrypted;
    file.close();
}

bool LicenseManager::activate(const QString &key, int skuId, const QString &userInfo)
{
    int days = 0;
    char expireDate[32] = {0};

    int result = SPPValidateKey(
        key.toStdString().c_str(),
        SECRET_KEY,
        (unsigned char)skuId,
        &days,
        expireDate,
        userInfo.isEmpty() ? nullptr : userInfo.toStdString().c_str()
    );

    if (result != 0) {
        emit activationFailed(tr("Invalid serial key"));
        return false;
    }

    m_serialKey = key;
    m_skuId = skuId;
    m_isActivated = true;
    m_isTrial = false;
    m_expireDate = QString(expireDate);

    switch (skuId) {
        case SKU_COMMUNITY: m_sku = SKU_COMMUNITY_STR; break;
        case SKU_PRO: m_sku = SKU_PRO_STR; break;
        case SKU_SRV: m_sku = SKU_SRV_STR; break;
        default: m_sku = SKU_UNKNOWN_STR; break;
    }

    saveLicenseData();
    emit licenseChanged();
    emit activationSuccess();
    return true;
}

bool LicenseManager::startTrial()
{
    if (m_trialRecord > 0) return false;

    QDate today = QDate::currentDate();
    QDate endDate = today.addDays(TRIAL_DAYS);

    m_isTrial = true;
    m_trialRecord = 1;
    m_trialStartDate = today.toString("yyyy-MM-dd");
    m_trialEndDate = endDate.toString("yyyy-MM-dd");
    m_sku = SKU_TRIAL_STR;
    m_skuId = SKU_TRIAL;
    m_serialKey = "TRIAL-TRIAL-TRIAL-TRIAL";
    m_isActivated = false;

    saveLicenseData();
    emit licenseChanged();
    return true;
}

void LicenseManager::removeLicense()
{
    m_sku = SKU_UNKNOWN_STR;
    m_skuId = SKU_UNKNOWN;
    m_serialKey = KEY_UNKNOWN;
    m_isActivated = false;
    m_expireDate = EXPIRED_DATE_UNKNOWN;
    m_isTrial = false;

    saveLicenseData();
    emit licenseChanged();
}

int LicenseManager::getActivationStatus()
{
    return checkActivationStatus();
}

int LicenseManager::checkActivationStatus()
{
    if (m_isTrial && m_trialRecord > 0) {
        QDate endDate = QDate::fromString(m_trialEndDate, "yyyy-MM-dd");
        if (QDate::currentDate() > endDate)
            return TrialExpired;
        return Trial;
    }

    if (m_isActivated && m_skuId >= SKU_TRIAL) {
        int days = 0;
        char expDate[32] = {0};
        int result = SPPValidateKey(
            m_serialKey.toStdString().c_str(),
            SECRET_KEY,
            (unsigned char)m_skuId,
            &days,
            expDate,
            nullptr
        );

        if (result == 0) return Activated;
        return Expired;
    }

    if (m_sku == SKU_UNKNOWN_STR && m_skuId == SKU_UNKNOWN)
        return NotActivated;

    return DataError;
}

bool LicenseManager::isActivated() const { return m_isActivated; }
bool LicenseManager::isTrial() const { return m_isTrial; }
bool LicenseManager::isExpired() const {
    int status = const_cast<LicenseManager*>(this)->checkActivationStatus();
    return status == Expired || status == TrialExpired;
}
QString LicenseManager::sku() const { return m_sku; }
int LicenseManager::skuId() const { return m_skuId; }
QString LicenseManager::serialKey() const { return m_serialKey; }
QString LicenseManager::expireDate() const { return m_expireDate; }
QString LicenseManager::trialEndDate() const { return m_trialEndDate; }

QString LicenseManager::statusText() const
{
    int status = const_cast<LicenseManager*>(this)->checkActivationStatus();
    switch (status) {
        case Activated: return tr("Activated");
        case Trial: return tr("Trial");
        case Expired: return tr("Expired");
        case TrialExpired: return tr("Trial Expired");
        case NotActivated: return tr("Not Activated");
        default: return tr("Unknown");
    }
}

bool LicenseManager::timeBombExpired() const
{
    TimeBomb tb;
    return tb.IsExpired();
}

QString LicenseManager::timeBombExpireDate() const
{
    TimeBomb tb;
    return QString("%1/%2/%3 %4:%5")
        .arg(tb.GetExpireYear())
        .arg(tb.GetExpireMonth(), 2, 10, QChar('0'))
        .arg(tb.GetExpireDay(), 2, 10, QChar('0'))
        .arg(tb.GetExpireHour(), 2, 10, QChar('0'))
        .arg(tb.GetExpireMinute(), 2, 10, QChar('0'));
}

QString LicenseManager::buildDate() const
{
    TimeBomb tb;
    return QString("%1/%2/%3")
        .arg(tb.GetBuildYear())
        .arg(tb.GetBuildMonth(), 2, 10, QChar('0'))
        .arg(tb.GetBuildDay(), 2, 10, QChar('0'));
}

bool LicenseManager::trialUsed() const
{
    return m_trialRecord > 0;
}
