//#ifndef ACCOUNTHANDLER_H
//#define ACCOUNTHANDLER_H
//#include <QObject>
//#include <QDebug>

//#ifndef QT_SIMULATOR
//#include <manager.h>
//#include <account.h>
//#include <AccountSetup/ProviderPluginProxy>
//#include <SignOn/Identity>
//#endif

//class AccountHandler : public QObject {
//    Q_OBJECT

//    // Expose variables to QML
//    Q_PROPERTY(QString password READ password WRITE setPassword)
//    Q_PROPERTY(QString userName READ userName WRITE setUserName NOTIFY userNameChanged)

//public:
//    explicit AccountHandler(QObject *parent = 0);
//    // Expose functions to QML
//    QString password() const { return m_password; }
//    QString userName() const { return m_userName; }
//    QString provider() const { return m_provider; }
//    void onSignOnError(const SignOn::Error& error);
//    void onSignOnIdentityInfo(const SignOn::IdentityInfo& info);
//    void onSignOnResponse(const SignOn::SessionData& data);
//    void querySignOnCredentials(void);
//    void setUserName(const QString);
//    void setPassword(const QString);
//    void setProvider(const QString);
//    bool canSignOn(void) const;

//private:
//#ifndef QT_SIMULATOR
//    Accounts::Account* m_account;
//    //AccountSetup::ProviderPluginProxy* m_accountSetup;
//    SignOn::Identity* m_identity;
//#endif

//    QString m_securityToken;
//    QString m_provider;
//    QString m_userName;
//    QString m_password;
//    qint32 m_credentialsId;

//signals:
//    void userNameChanged(void);
//    void providerChanged(void);
//};

//#endif // ACCOUNTHANDLER_H
