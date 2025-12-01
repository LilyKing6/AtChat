#include "NetworkManager.h"
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QFileInfo>
#include <QHttpMultiPart>
#include <QHttpPart>

NetworkManager* NetworkManager::s_instance = nullptr;

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
    , m_http(new QNetworkAccessManager(this))
    , m_ws(new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this))
    , m_serverUrl("http://localhost:8080")
    , m_connected(false)
{
    connect(m_ws, &QWebSocket::connected, this, &NetworkManager::onWsConnected);
    connect(m_ws, &QWebSocket::disconnected, this, &NetworkManager::onWsDisconnected);
    connect(m_ws, &QWebSocket::textMessageReceived, this, &NetworkManager::onWsTextReceived);
    connect(m_ws, &QWebSocket::errorOccurred, this, &NetworkManager::onWsError);
}

NetworkManager* NetworkManager::instance()
{
    if (!s_instance) s_instance = new NetworkManager();
    return s_instance;
}

NetworkManager* NetworkManager::create(QQmlEngine*, QJSEngine*)
{
    return instance();
}

void NetworkManager::setServerUrl(const QString &url)
{
    m_serverUrl = url;
}

QNetworkRequest NetworkManager::createRequest(const QString &path)
{
    QNetworkRequest req(QUrl(m_serverUrl + path));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    return req;
}

void NetworkManager::login(const QString &username, const QString &password)
{
    QJsonObject body;
    body["username"] = username;
    body["password"] = password;

    auto reply = m_http->post(createRequest("/api/login"), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();

        if (data["success"].toBool()) {
            m_token = data["token"].toString();
            auto user = data["user"].toObject();
            m_userId = user["id"].toString();
            m_username = user["username"].toString();
            m_nickname = user["nickname"].toString();

            // 先断开旧连接
            if (m_ws->state() == QAbstractSocket::ConnectedState) {
                m_ws->close();
            }

            emit userChanged();
            emit loginSuccess(user);

            // 延迟连接 WebSocket
            QTimer::singleShot(500, this, [this]() {
                connectWebSocket();
            });
        } else {
            emit loginFailed(data["error"].toString());
        }
    });
}

void NetworkManager::registerUser(const QString &username, const QString &password, const QString &nickname)
{
    QJsonObject body;
    body["username"] = username;
    body["password"] = password;
    body["nickname"] = nickname;

    auto reply = m_http->post(createRequest("/api/register"), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();

        if (data["success"].toBool()) {
            emit registerSuccess(data["user"].toObject());
        } else {
            emit registerFailed(data["error"].toString());
        }
    });
}

void NetworkManager::connectWebSocket()
{
    if (m_userId.isEmpty()) {
        qDebug() << "Cannot connect WebSocket: userId is empty";
        return;
    }

    // 如果已连接，先断开
    if (m_ws->state() == QAbstractSocket::ConnectedState) {
        qDebug() << "WebSocket already connected, closing first";
        m_ws->close();
        QTimer::singleShot(100, this, &NetworkManager::connectWebSocket);
        return;
    }

    QString wsUrl = m_serverUrl;
    wsUrl.replace("http://", "ws://").replace("https://", "wss://");
    QString fullUrl = wsUrl + "/ws?user_id=" + m_userId;
    qDebug() << "Connecting WebSocket to:" << fullUrl;
    m_ws->open(QUrl(fullUrl));
}

void NetworkManager::disconnectWebSocket()
{
    m_ws->close();
}

void NetworkManager::sendMessage(const QString &to, const QString &content, const QString &type)
{
    if (!m_connected || m_ws->state() != QAbstractSocket::ConnectedState) {
        qDebug() << "WebSocket not connected, reconnecting...";
        connectWebSocket();
        return;
    }

    QJsonObject data;
    data["to"] = to;
    data["content"] = content;
    data["type"] = type;

    QJsonObject msg;
    msg["action"] = "message";
    msg["data"] = data;

    QString jsonStr = QJsonDocument(msg).toJson(QJsonDocument::Compact);
    qDebug() << "Sending message:" << jsonStr;
    m_ws->sendTextMessage(jsonStr);
}

void NetworkManager::fetchUsers()
{
    auto reply = m_http->get(createRequest("/api/users"));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).array();
        reply->deleteLater();
        emit usersReceived(data);
    });
}

void NetworkManager::fetchHistory(const QString &otherUserId)
{
    QString path = QString("/api/history?user1=%1&user2=%2").arg(m_userId, otherUserId);
    auto reply = m_http->get(createRequest(path));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).array();
        reply->deleteLater();
        emit historyReceived(data);
    });
}

void NetworkManager::logout()
{
    disconnectWebSocket();
    m_userId.clear();
    m_username.clear();
    m_nickname.clear();
    m_token.clear();
    emit userChanged();
}

void NetworkManager::onWsConnected()
{
    m_connected = true;
    qDebug() << "WebSocket connected for user:" << m_userId;
    emit connectedChanged();
}

void NetworkManager::onWsDisconnected()
{
    m_connected = false;
    qDebug() << "WebSocket disconnected";
    emit connectedChanged();
}

void NetworkManager::onWsTextReceived(const QString &message)
{
    qDebug() << "WebSocket received:" << message;
    auto msg = QJsonDocument::fromJson(message.toUtf8()).object();
    handleWsMessage(msg);
}

void NetworkManager::onWsError(QAbstractSocket::SocketError error)
{
    qDebug() << "WebSocket error:" << error << m_ws->errorString();
    emit connectionError(m_ws->errorString());
}

void NetworkManager::handleWsMessage(const QJsonObject &msg)
{
    QString action = msg["action"].toString();
    qDebug() << "Received WS message, action:" << action;

    if (action == "message") {
        emit messageReceived(msg["data"].toObject());
    } else if (action == "group_message") {
        emit groupMessageReceived(msg["data"].toObject());
    } else if (action == "status") {
        auto data = msg["data"].toObject();
        emit userStatusChanged(data["user_id"].toString(), data["online"].toBool());
    } else if (action == "error") {
        auto data = msg["data"].toObject();
        QString errorMsg = data["error"].toString();
        qDebug() << "Server error:" << errorMsg;
        emit connectionError(errorMsg);
    }
}

void NetworkManager::createGroup(const QString &name, const QStringList &members)
{
    QJsonObject body;
    body["name"] = name;
    body["members"] = QJsonArray::fromStringList(members);

    QString path = QString("/api/groups?user_id=%1").arg(m_userId);
    auto reply = m_http->post(createRequest(path), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        if (data["success"].toBool()) {
            emit groupCreated(data["group"].toObject());
        }
    });
}

void NetworkManager::fetchGroups()
{
    QString path = QString("/api/groups?user_id=%1").arg(m_userId);
    auto reply = m_http->get(createRequest(path));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).array();
        reply->deleteLater();
        emit groupsReceived(data);
    });
}

void NetworkManager::fetchGroupHistory(const QString &groupId)
{
    QString path = QString("/api/groups/history?group_id=%1").arg(groupId);
    auto reply = m_http->get(createRequest(path));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).array();
        reply->deleteLater();
        emit groupHistoryReceived(data);
    });
}

void NetworkManager::sendGroupMessage(const QString &groupId, const QString &content, const QString &type)
{
    QJsonObject data;
    data["group_id"] = groupId;
    data["content"] = content;
    data["type"] = type;

    QJsonObject msg;
    msg["action"] = "group_message";
    msg["data"] = data;

    m_ws->sendTextMessage(QJsonDocument(msg).toJson(QJsonDocument::Compact));
}

void NetworkManager::uploadFile(const QString &filePath)
{
    QFile *file = new QFile(filePath);
    if (!file->open(QIODevice::ReadOnly)) {
        delete file;
        return;
    }

    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    QHttpPart filePart;
    filePart.setHeader(QNetworkRequest::ContentDispositionHeader,
        QString("form-data; name=\"file\"; filename=\"%1\"").arg(QFileInfo(filePath).fileName()));
    filePart.setBodyDevice(file);
    file->setParent(multiPart);
    multiPart->append(filePart);

    QNetworkRequest req(QUrl(m_serverUrl + "/api/upload"));
    auto reply = m_http->post(req, multiPart);
    multiPart->setParent(reply);

    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        if (data["success"].toBool()) {
            emit fileUploaded(data);
        }
    });
}

void NetworkManager::updateNickname(const QString &nickname)
{
    QJsonObject body;
    body["nickname"] = nickname;

    QString path = QString("/api/profile/nickname?user_id=%1").arg(m_userId);
    auto reply = m_http->post(createRequest(path), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        if (data["success"].toBool()) {
            m_nickname = nickname;
            emit userChanged();
        }
    });
}

void NetworkManager::updateSignature(const QString &signature)
{
    QJsonObject body;
    body["signature"] = signature;

    QString path = QString("/api/profile/signature?user_id=%1").arg(m_userId);
    m_http->post(createRequest(path), QJsonDocument(body).toJson())->deleteLater();
}

void NetworkManager::updateStatus(int status)
{
    QJsonObject body;
    body["status"] = status;

    QString path = QString("/api/profile/status?user_id=%1").arg(m_userId);
    m_http->post(createRequest(path), QJsonDocument(body).toJson())->deleteLater();
}

void NetworkManager::changePassword(const QString &oldPassword, const QString &newPassword)
{
    QJsonObject body;
    body["old_password"] = oldPassword;
    body["new_password"] = newPassword;

    QString path = QString("/api/profile/password?user_id=%1").arg(m_userId);
    auto reply = m_http->post(createRequest(path), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        emit passwordChanged(data["success"].toBool(), data["error"].toString());
    });
}

void NetworkManager::sendFriendRequest(const QString &friendId, const QString &message)
{
    QJsonObject body;
    body["friend_id"] = friendId;
    body["message"] = message;

    QString path = QString("/api/friends/request?user_id=%1").arg(m_userId);
    auto reply = m_http->post(createRequest(path), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        emit friendRequestSent(data["success"].toBool());
    });
}

void NetworkManager::fetchFriendRequests()
{
    QString path = QString("/api/friends/requests?user_id=%1").arg(m_userId);
    auto reply = m_http->get(createRequest(path));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).array();
        reply->deleteLater();
        emit friendRequestsReceived(data);
    });
}

void NetworkManager::handleFriendRequest(const QString &requestId, bool accept, const QString &groupId)
{
    QJsonObject body;
    body["request_id"] = requestId;
    body["accept"] = accept;
    if (!groupId.isEmpty()) body["group_id"] = groupId;

    QString path = QString("/api/friends/handle?user_id=%1").arg(m_userId);
    auto reply = m_http->post(createRequest(path), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        emit friendRequestHandled(data["success"].toBool());
    });
}

void NetworkManager::fetchFriends()
{
    QString path = QString("/api/friends?user_id=%1").arg(m_userId);
    auto reply = m_http->get(createRequest(path));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).array();
        reply->deleteLater();
        emit friendsReceived(data);
    });
}

void NetworkManager::deleteFriend(const QString &friendId)
{
    QString path = QString("/api/friends/%1?user_id=%2").arg(friendId, m_userId);
    QNetworkRequest req(QUrl(m_serverUrl + path));
    auto reply = m_http->deleteResource(req);
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        emit friendDeleted(data["success"].toBool());
    });
}

void NetworkManager::updateFriendRemark(const QString &friendId, const QString &remark)
{
    QJsonObject body;
    body["remark"] = remark;

    QString path = QString("/api/friends/%1/remark?user_id=%2").arg(friendId, m_userId);
    m_http->post(createRequest(path), QJsonDocument(body).toJson())->deleteLater();
}

void NetworkManager::updateFriendNote(const QString &friendId, const QString &note)
{
    QJsonObject body;
    body["note"] = note;

    QString path = QString("/api/friends/%1/note?user_id=%2").arg(friendId, m_userId);
    m_http->post(createRequest(path), QJsonDocument(body).toJson())->deleteLater();
}

void NetworkManager::updateFriendGroup(const QString &friendId, const QString &groupId)
{
    QJsonObject body;
    body["group_id"] = groupId;

    QString path = QString("/api/friends/%1/group?user_id=%2").arg(friendId, m_userId);
    m_http->post(createRequest(path), QJsonDocument(body).toJson())->deleteLater();
}

void NetworkManager::fetchFriendGroups()
{
    QString path = QString("/api/friends/groups?user_id=%1").arg(m_userId);
    auto reply = m_http->get(createRequest(path));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).array();
        reply->deleteLater();
        emit friendGroupsReceived(data);
    });
}

void NetworkManager::createFriendGroup(const QString &name)
{
    QJsonObject body;
    body["name"] = name;

    QString path = QString("/api/friends/groups?user_id=%1").arg(m_userId);
    auto reply = m_http->post(createRequest(path), QJsonDocument(body).toJson());
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        if (data["success"].toBool()) {
            emit friendGroupCreated(data["group"].toObject());
        }
    });
}

void NetworkManager::deleteFriendGroup(const QString &groupId)
{
    QString path = QString("/api/friends/groups/%1?user_id=%2").arg(groupId, m_userId);
    QNetworkRequest req(QUrl(m_serverUrl + path));
    m_http->deleteResource(req)->deleteLater();
}

void NetworkManager::searchUser(const QString &userId)
{
    QString path = QString("/api/friends/search?user_id=%1&target_id=%2").arg(m_userId, userId);
    auto reply = m_http->get(createRequest(path));
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        emit userSearchResult(data);
    });
}

void NetworkManager::deleteMessages(const QString &otherUser, bool deleteServer)
{
    QString path = QString("/api/messages?user_id=%1&other_user=%2&delete_server=%3")
        .arg(m_userId, otherUser, deleteServer ? "true" : "false");
    QNetworkRequest req(QUrl(m_serverUrl + path));
    auto reply = m_http->deleteResource(req);
    connect(reply, &QNetworkReply::finished, this, [=]() {
        auto data = QJsonDocument::fromJson(reply->readAll()).object();
        reply->deleteLater();
        emit messagesDeleted(data["success"].toBool());
    });
}
