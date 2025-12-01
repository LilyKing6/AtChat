#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QWebSocket>
#include <QJsonObject>
#include <QJsonArray>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QTimer>

class NetworkManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString userId READ userId NOTIFY userChanged)
    Q_PROPERTY(QString username READ username NOTIFY userChanged)
    Q_PROPERTY(QString nickname READ nickname NOTIFY userChanged)

public:
    explicit NetworkManager(QObject *parent = nullptr);
    static NetworkManager* instance();
    static NetworkManager* create(QQmlEngine*, QJSEngine*);

    bool connected() const { return m_connected; }
    QString userId() const { return m_userId; }
    QString username() const { return m_username; }
    QString nickname() const { return m_nickname; }

    Q_INVOKABLE void setServerUrl(const QString &url);
    Q_INVOKABLE void login(const QString &username, const QString &password);
    Q_INVOKABLE void registerUser(const QString &username, const QString &password, const QString &nickname);
    Q_INVOKABLE void connectWebSocket();
    Q_INVOKABLE void disconnectWebSocket();
    Q_INVOKABLE void sendMessage(const QString &to, const QString &content, const QString &type = "text");
    Q_INVOKABLE void fetchUsers();
    Q_INVOKABLE void fetchHistory(const QString &otherUserId);
    Q_INVOKABLE void logout();

    // Group APIs
    Q_INVOKABLE void createGroup(const QString &name, const QStringList &members);
    Q_INVOKABLE void fetchGroups();
    Q_INVOKABLE void fetchGroupHistory(const QString &groupId);
    Q_INVOKABLE void sendGroupMessage(const QString &groupId, const QString &content, const QString &type = "text");

    // File upload
    Q_INVOKABLE void uploadFile(const QString &filePath);

    // Profile
    Q_INVOKABLE void updateNickname(const QString &nickname);
    Q_INVOKABLE void updateSignature(const QString &signature);
    Q_INVOKABLE void updateStatus(int status);
    Q_INVOKABLE void changePassword(const QString &oldPassword, const QString &newPassword);

    // Friend APIs
    Q_INVOKABLE void sendFriendRequest(const QString &friendId, const QString &message);
    Q_INVOKABLE void fetchFriendRequests();
    Q_INVOKABLE void handleFriendRequest(const QString &requestId, bool accept, const QString &groupId = "");
    Q_INVOKABLE void fetchFriends();
    Q_INVOKABLE void deleteFriend(const QString &friendId);
    Q_INVOKABLE void updateFriendRemark(const QString &friendId, const QString &remark);
    Q_INVOKABLE void updateFriendNote(const QString &friendId, const QString &note);
    Q_INVOKABLE void updateFriendGroup(const QString &friendId, const QString &groupId);
    Q_INVOKABLE void fetchFriendGroups();
    Q_INVOKABLE void createFriendGroup(const QString &name);
    Q_INVOKABLE void deleteFriendGroup(const QString &groupId);
    Q_INVOKABLE void searchUser(const QString &userId);
    Q_INVOKABLE void deleteMessages(const QString &otherUser, bool deleteServer);

signals:
    void connectedChanged();
    void userChanged();
    void loginSuccess(const QJsonObject &user);
    void loginFailed(const QString &error);
    void registerSuccess(const QJsonObject &user);
    void registerFailed(const QString &error);
    void messageReceived(const QJsonObject &message);
    void usersReceived(const QJsonArray &users);
    void historyReceived(const QJsonArray &messages);
    void userStatusChanged(const QString &userId, bool online);
    void connectionError(const QString &error);

    // Group signals
    void groupCreated(const QJsonObject &group);
    void groupsReceived(const QJsonArray &groups);
    void groupHistoryReceived(const QJsonArray &messages);
    void groupMessageReceived(const QJsonObject &message);

    // File signals
    void fileUploaded(const QJsonObject &fileInfo);

    // Profile signals
    void passwordChanged(bool success, const QString &error);

    // Friend signals
    void friendRequestSent(bool success);
    void friendRequestsReceived(const QJsonArray &requests);
    void friendRequestHandled(bool success);
    void friendsReceived(const QJsonArray &friends);
    void friendDeleted(bool success);
    void friendGroupsReceived(const QJsonArray &groups);
    void friendGroupCreated(const QJsonObject &group);
    void userSearchResult(const QJsonObject &user);
    void messagesDeleted(bool success);

private slots:
    void onWsConnected();
    void onWsDisconnected();
    void onWsTextReceived(const QString &message);
    void onWsError(QAbstractSocket::SocketError error);

private:
    void handleWsMessage(const QJsonObject &msg);
    QNetworkRequest createRequest(const QString &path);

    static NetworkManager *s_instance;
    QNetworkAccessManager *m_http;
    QWebSocket *m_ws;
    QString m_serverUrl;
    QString m_userId;
    QString m_username;
    QString m_nickname;
    QString m_token;
    bool m_connected;
};

#endif
