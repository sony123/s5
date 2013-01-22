///*
//  Access Harmattan's account-qt & signon framework.


//*/
//#include "accounthandler.h"

//AccountHandler::AccountHandler(QObject *parent) :
//    QObject(parent),
//#ifndef QT_SIMULATOR
//    m_account(0),
//    //m_accountSetup(0),
//    m_identity(0)
//#endif
//{
//}

//#ifndef QT_SIMULATOR
//void AccountHandler::onSignOnError(const SignOn::Error& error)
//{
//    qDebug() << "SignOn Error:" << error.message();
//}

//void AccountHandler::onSignOnIdentityInfo(const SignOn::IdentityInfo& info)
//{
//    qDebug() << "SignOn: Received identity information" << info.id();

//    if (!info.isStoringSecret()) {
//        qDebug() << "SignOn: No secret stored";
//    }

//    SignOn::AuthSession* session;
//    SignOn::SessionData data;
//    data.setUserName(info.userName());

//    // Create a new SignOn::AuthSession to request the password
//    session = m_identity->createSession(QString("password"));

//    connect(session, SIGNAL(response(const SignOn::SessionData&)),
//            this, SLOT(onSignOnResponse(const SignOn::SessionData&)));
//    connect(session, SIGNAL(error(const SignOn::Error &)),
//            this, SLOT(onSignOnError(const SignOn::Error &)));
//    session->process(data, QLatin1String("password"));
//}

//void AccountHandler::onSignOnResponse(const SignOn::SessionData& data)
//{
//    QString secret = data.getProperty("Secret").toString();
//    QString userName = data.getProperty("UserName").toString();

//    if (secret.isEmpty() || userName.isEmpty()) {
//        qDebug() << "SignOn: Empty credentials!";
//        //setMissingCredentials(true);
//    } else {
//        qDebug() << "SignOn: Received credentials, logging in";
//        //setUserName(userName);
//        //setPassword(secret);
//        //setMissingCredentials(false);
//        //login();
//    }
//}
//#endif // !defined(QT_SIMULATOR)

//void AccountHandler::querySignOnCredentials(void)
//{
//    qDebug() << "AccountHandler::querySignOnCredentials()";
//    if (m_provider.isEmpty()) {
//        qDebug() << "Error: provider is empty";
//        return;
//    }

//#ifndef QT_SIMULATOR
//    if (m_account) {
//        delete m_account;
//        m_account = 0;
//    }

//    // Find an account for provider, enabled or otherwise
//    Accounts::Manager m_manager;
//    Accounts::AccountIdList accounts = m_manager.accountList();
//    foreach (Accounts::AccountId id, accounts) {
//        Accounts::Account* account = m_manager.account(id);
//        if (account->providerName() == m_provider) {
//            m_account = account;
//            break;
//        }
//    }

//    int credentialsId = 0;
//    if (m_account) {
//        if (m_account->enabled()) {
//            // If there is an enabled tmo account, get corresponding SignOn credentials
//            qDebug() << "Accounts: Found account" << m_account->displayName();
//            credentialsId = m_account->valueAsInt("CredentialsId");
////            credentialsId = m_account->credentialsId;

//            qDebug() << "    " << m_account->allKeys();
//            qDebug() << "    username =" << m_account->valueAsString("username");
//            qDebug() << "    CredentialsId =" << credentialsId;
//            qDebug() << "    name =" << m_account->valueAsString("name");
//            Accounts::ServiceList services = m_account->services();
//            foreach (Accounts::Service* service, services) {
//                qDebug() << "    service:" << service->name();
//            }
//        } else {
//            qDebug() << "Accounts: Found disabled account" << m_account->displayName();
//        }
//    }

//    if (credentialsId > 0) {
//        // Query SignOn credentials corresponding to m_account
//        qDebug() << "Querying identity #" << credentialsId;

//        m_identity = SignOn::Identity::existingIdentity(credentialsId);
//        connect(m_identity, SIGNAL(info(const SignOn::IdentityInfo&)),
//                this, SLOT(onSignOnIdentityInfo(const SignOn::IdentityInfo&)));
//        m_identity->queryInfo();

//        //setMissingCredentials(false);

//        return;
//    }
//#endif // !defined(QT_SIMULATOR)

//    //setMissingCredentials(true);
//}

//void AccountHandler::setUserName(const QString userName)
//{
//    if (m_userName != userName) {
//        m_userName = userName;
//        emit userNameChanged();
//    }
//}

//void AccountHandler::setPassword(const QString password)
//{
//    if (m_password != password) {
//        m_password = password;
//    }
//}

//void AccountHandler::setProvider(const QString provider)
//{
//    if (m_provider != provider) {
//        m_provider = provider;
//        emit providerChanged();
//    }
//}

//bool AccountHandler::canSignOn(void) const
//{
//#ifdef QT_SIMULATOR
//    return false;
//#else
//    return true;
//#endif
//}
