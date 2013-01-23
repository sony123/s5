#include "key.h"
#include "filehandler.h"

FileHandler::FileHandler(QObject *parent) :
    QObject(parent)
{
    actvPos = -1;

#ifdef PLUS
    sPlus = true;
#else
    sPlus = false;
#endif

    aegis_token = enc_key;

#ifdef Q_OS_SYMBIAN
    // Use default folder
    cfgDir = ".stockona/";
#else
    cfgDir = "/home/user/.stockona/";
#endif

    // stockona db folder
    QDir dir(cfgDir);
    if (!dir.exists())
        QDir().mkdir(cfgDir);

    // Symbian
#ifdef Q_OS_SYMBIAN
    QString _a(aegis_token);
    QByteArray t = _a.toLocal8Bit();
    unsigned char key[32];
    int keyLen = 32*8;

    for (int i = 0; i < 32; i++) {
        key[i] = i;

        if (i < t.size ()) {
            key[i] = (unsigned char)t[i];
        }
    }
    //unsigned char key16[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
    //unsigned char key24[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23};
    //unsigned char key32[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31};

    // int AES_set_encrypt_key(const unsigned char *userKey, const int bits,
    // AES_KEY *key);
    AES_set_encrypt_key(key, keyLen, &aeskeyE);
    AES_set_decrypt_key(key, keyLen, &aeskeyD);
#endif

    // Move stockona_db to cfgDir
    QString dbPath = cfgDir;
    dbPath.append("stockona_db");

    QFile moveFile;
    moveFile.setFileName("stockona_db");
    if (moveFile.exists()) {
        moveFile.rename(dbPath);
    }

    // Set up portfolio table
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(dbPath);
    bool ok = db.open();

    if (!ok) {
        qDebug() << db.lastError().type();
    }
    else {
        if (!db.tables(QSql::Tables).contains("portfolio")) {
            QSqlQuery q("CREATE TABLE portfolio (id INT, name TEXT, desc TEXT, isYahoo INT, misc TEXT)", db);
        }
    }

    // DB conversion
    convertPortfolioToDB();

    // Remove *.csv files
    /*
    QDir dir(cfgDir);
    if (dir.exists()) {
        QStringList filters;
        filters << "*.csv";
        dir.setNameFilters(filters);
        QStringList fileList = dir.entryList();
        for (int i=0; i<(signed)dir.count(); i++) {
            QString filename = cfgDir;
            filename.append(fileList.at(i));
            //qDebug() << "DELETE" << filename;
            QFile::remove(filename);
        }
    }
    */
}

//void FileHandler::slotTest(int x) {
//    qDebug() << "slot:" << x;
//}

// Crypto
QVariant FileHandler::encryptData(const QString & clearTextArg) {
#if defined(Q_WS_SIMULATOR)
    return QVariant(clearTextArg);
#elif defined(Q_OS_SYMBIAN)
    unsigned char ivE[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};

    QByteArray t = clearTextArg.toUtf8();
    int size = t.size();
    int c = size / 16 + 1;
    short p = 16 - size % 16;

    unsigned char pout [c * 16];
    unsigned char pin [c * 16];
    memset (pin, p, c * 16);
    memset(pout, 0, c * 16);
    memcpy(pin, (unsigned char *)t.constData(), size);

    AES_cbc_encrypt(pin, pout, c*16, &aeskeyE, ivE, AES_ENCRYPT);

    QByteArray b;
    #ifdef BASE64
    b = QByteArray((char*)pout, c * 16).toBase64();
    #else
    b = QByteArray((char*)pout, c * 16);
    #endif

    return QVariant(b);

//    return QVariant(clearTextArg);
#else
    RAWDATA_PTR cipherText = NULL;
    size_t cipherLength = 0;

    QByteArray clearText( clearTextArg.toUtf8() );

    // Encrypt, only token can be NULL.
    if ( aegis_crypto_encrypt(clearText.data(), clearText.length(), aegis_token, &cipherText, &cipherLength) != aegis_crypto_ok )
    {
        aegis_crypto_free(cipherText);
        qDebug("C Info: Failed to encrypt data: %s", aegis_crypto_last_error_str());
        return QVariant();
    }
    QByteArray encrypted((char *)cipherText, cipherLength);
    aegis_crypto_free(cipherText);

#ifdef DBG
    qDebug() << "C Info: encrypData=" << clearText.data() << ", length=" << clearText.length();
    qDebug() << "C Info: DBG Encrypted=" << encrypted.constData() << ", length=" << cipherLength;
#endif

    // Replace ' with '' for SQL
    encrypted.replace(QByteArray("'"), QByteArray("''"));

    return QVariant(encrypted);
#endif // QT_SIMULATOR
}

QString FileHandler::decryptData(const QVariant cipherTextRaw) {
#if defined(Q_WS_SIMULATOR)
    return cipherTextRaw.toString();
#elif defined(Q_OS_SYMBIAN)
    QByteArray a = cipherTextRaw.toByteArray();

    unsigned char ivD[] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};

    int size = a.size ();
    int c = size / 16;
    unsigned char pout [size];
    unsigned char pin [size];
    memset(pout, 0, size);
    memcpy(pin, (unsigned char *)a.constData(), size);

    AES_cbc_encrypt(pin, pout, c*16, &aeskeyD, ivD, AES_DECRYPT);
    int ss = size-(short)(pout[size-1]);
    pout [ss] = 0;

    return QString::fromUtf8((char*)pout, ss);

//    return cipherTextRaw.toString();
#else
    RAWDATA_PTR clearText = NULL;
    size_t      clearLength = 0;

    QByteArray cipherText( cipherTextRaw.toByteArray() );

    // Decrypt
    if (aegis_crypto_decrypt(cipherText.constData(), cipherText.length(), aegis_token, &clearText, &clearLength) != aegis_crypto_ok)
    {
        aegis_crypto_free(clearText);
        qDebug("C Info: Failed to decrypt data: %s", aegis_crypto_last_error_str());
        return QString();
    }
    QByteArray decrypted((char *)clearText, clearLength);
    aegis_crypto_free(clearText);

#ifdef DBG
    qDebug() << "C Info: decryptData=" << cipherText.constData() << ", length=" << cipherText.length();
    qDebug() << "C Info: Decrypted=" << decrypted.constData() << ", length=" << clearLength;;
#endif
    return QString(decrypted.constData());
#endif // QT_SIMULATOR
}

void FileHandler::debugPfo() {
    for (int i=0; i<pfoModel.pfoName.length(); i++) {
#ifdef DBG
        qDebug() << i << "="
                 << pfoModel.pfoName[i].toString() << ":"
                 << pfoModel.pfoDesc[i].toString() << ":"
                 << pfoModel.pfoIsYahoo[i].toBool() ; //<< ":"
        //<< pfoModel.pfoNum[i].toInt();
#endif
    }
}

////////////////////////////////////////
// Convert from files to SQlite
////////////////////////////////////////
int FileHandler::convertPortfolioToDB() {
    QString filePath = cfgDir + "portfolio.cfg";
    QFile f( filePath );

    if( !f.exists() )
    {
#ifdef DBG
        qDebug() << "C_Info: Local portfolio does not exist.";
#endif

        return -1;
    }

    if( !f.open( QIODevice::ReadOnly ) )
    {
#ifdef DBG
        qDebug() << "C_Info: Failed to open for read.";
#endif

        return -1;
    }

    QTextStream ts( &f );
    QStringList strList;

    int pfo_cnt = 0;

    while ( !ts.atEnd() ) {
        strList = ts.readLine().split(":");

        if (strList.length()==3) {
            for (int i=0; i<strList.length(); i++) {
                //qDebug() << "C_Info: " << strList[i].toLocal8Bit().constData();
                if (i==0)
                    pfoModel.pfoName.append( strList[i].toLocal8Bit().constData() );
                else if (i==1)
                    pfoModel.pfoDesc.append( strList[i].toLocal8Bit().constData() );
                else
                    pfoModel.pfoIsYahoo.append( strList[i].toLocal8Bit().constData() );
            }

            pfo_cnt++;
        }
        else {
            return -2;
        }
    }
    f.close();

    // Save to SQL
    storePfoAll();

    // delete after conversion
    QString filename = cfgDir;
    filename.append("portfolio.cfg");
    QFile::remove(filename);

    // Read position files
    QDir dir(cfgDir);
    if (dir.exists()) {
        QStringList filters;
        filters << "*.pos";
        dir.setNameFilters(filters);
        QStringList fileList = dir.entryList();

        int pos_cnt = 0;

        for (int i=0; i<(signed)dir.count(); i++) {
            filename = cfgDir;
            filename.append(fileList.at(i));

        #ifdef DBG
            qDebug() << "C_Info: convert ---> " << filename;
        #endif

            QFile f( filename );

            if( !f.exists() )
                return -1;

            if( !f.open( QIODevice::ReadOnly ) )
                return -1;

            QTextStream ts( &f );

            QStringList strList;

            while ( !ts.atEnd() ) {
                strList = ts.readLine().split(":");

                if (strList.length()==6) {
                    for (int i=0; i<strList.length(); i++) {
                        //qDebug() << "C_Info: " << strList[i].toLocal8Bit().constData();
                        if (i==0)
                            posSymbol.append( strList[i].toLocal8Bit().constData() );
                        else if (i==1)
                            posExg.append( strList[i].toLocal8Bit().constData() );
                        else if (i==2)
                            posShare.append( strList[i].toLocal8Bit().constData() );
                        else if (i==3)
                            posCost.append( strList[i].toLocal8Bit().constData() );
                        else if (i==4)
                            posStop.append( strList[i].toLocal8Bit().constData() );
                    }
                }
                else {
                    return -2;
                }
            }

            f.close();

            QFile::remove(filename);

            // Store to SQL
            storePosAll(pos_cnt);

            pos_cnt++;
        }
    }

    return 0;
}

///////////////////////////////////////////
//  Portfolio Table
///////////////////////////////////////////
// Overloaded function to eliminate appendPfo()
Q_INVOKABLE int FileHandler::addPfo(const QString name, const QString desc, const bool isYahoo)
{
#ifdef DBG
    qDebug() << "C_Info: addPfo() " << name << " " << desc << " " << isYahoo;
#endif

    pfoModel.pfoName.append(name);
    pfoModel.pfoDesc.append(desc);
    pfoModel.pfoIsYahoo.append(isYahoo);

    if (!pfoModel.pfoName.isEmpty()) {
        QSqlDatabase db = QSqlDatabase::database();
        QSqlQuery query(db);

        // Get the size
        int db_size = 0;

        query.setForwardOnly(TRUE);
        if (query.exec("SELECT id FROM portfolio")) {
            while (query.next())
                db_size++;
        }
        else
            qDebug() << "addPfo::QsqlQuery Error:" << query.lastError().type();

        query.prepare("INSERT INTO portfolio (id, name, desc, isYahoo) VALUES (:id, :name, :desc, :isYahoo)");
        query.bindValue(":id", db_size);
        query.bindValue(":name", name);
        query.bindValue(":desc", desc);
        query.bindValue(":isYahoo", isYahoo);

        query.setForwardOnly(TRUE);

        if (!query.exec()) {
            qDebug() << "addPfo::QsqlQuery Error:" << query.lastError().type();

            return -1;
        }
        else
            query.next();
    }

    return 0;
}

Q_INVOKABLE int FileHandler::setPfo(const int idx, const QString name, const QString desc, const bool isYahoo)
{
#ifdef DBG
    qDebug() << "C_Info: addPfo() " << name << " " << desc << " " << isYahoo;
#endif

    if (idx>=0) {
        if (idx < pfoModel.pfoName.length()) {
            pfoModel.pfoName.replace(idx, name);
            pfoModel.pfoDesc.replace(idx, desc);
            pfoModel.pfoIsYahoo.replace(idx, isYahoo);
        }
        else {
            pfoModel.pfoName.append(name);
            pfoModel.pfoDesc.append(desc);
            pfoModel.pfoIsYahoo.append(isYahoo);
        }
    }

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    query.prepare("UPDATE portfolio SET (name = :name, desc = :desc, isYahoo = :isYahoo) WHERE id = :id");
    query.bindValue(":name", name);
    query.bindValue(":desc", desc);
    query.bindValue(":isYahoo", isYahoo);
    query.bindValue(":id", idx);

    query.setForwardOnly(TRUE);
    if (!query.exec()) {
        qDebug() << "addPfo::QsqlQuery Error:" << query.lastError().type();

        return -1;
    }
    else
        query.next();

    return 0;
}

Q_INVOKABLE int FileHandler::storePfoAll()
{
#ifdef DBG
    qDebug() << "C_Info: storePfoAll()";
#endif

    if (!pfoModel.pfoName.isEmpty()) {
        QSqlDatabase db = QSqlDatabase::database();
        QSqlQuery query(db);

        for (int i=0; i < pfoModel.pfoName.count(); i++) {
#ifdef DBG
            qDebug() << "C_Info: " << pfoModel.pfoName[i].toString() << ":" << pfoModel.pfoDesc[i].toString() << ":" << pfoModel.pfoIsYahoo[i].toBool();
#endif
            // INSERT
            query.prepare("INSERT INTO portfolio (id, name, desc, isYahoo) VALUES (:id, :name, :desc, :isYahoo)");
            query.bindValue(":id", i);
            query.bindValue(":name", pfoModel.pfoName.at(i).toString());
            query.bindValue(":desc", pfoModel.pfoDesc.at(i).toString());
            query.bindValue(":isYahoo", pfoModel.pfoIsYahoo.at(i).toInt());

            query.setForwardOnly(TRUE);

            if (!query.exec()) {
                qDebug() << "storePfoAll::QsqlQuery Error:" << query.lastError().type();

                return -1;
            }
            else
                query.next();
        }
    }

    return 0;
}

Q_INVOKABLE int FileHandler::loadPfo()
{
#ifdef DBG
    qDebug() << "C_Info: loadPfo --->";
#endif

    pfoModel.pfoName.clear();
    pfoModel.pfoDesc.clear();
    pfoModel.pfoIsYahoo.clear();

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    int pos_cnt = 0;

    query.setForwardOnly(TRUE);
    if (query.exec("SELECT name, desc, isYahoo FROM portfolio")) {
        while(query.next()) {
            pos_cnt++;
            pfoModel.pfoName.append(    query.value(0).toString() );
            pfoModel.pfoDesc.append(    query.value(1).toString() );
            pfoModel.pfoIsYahoo.append( query.value(2).toBool() );
        }
    }
    else {
        qDebug() << "loadPfo::QsqlQuery Error:" << query.lastError().type();

        return -1;
    }

    // Check if there are redundant files lurking around.
    //removeRedundantPosFile(pos_cnt);

    for (int i=0; i<pfoModel.pfoName.length(); i++) {
        loadPosNum(i);
    }

    debugPfo();

    return 0;
}

int FileHandler::removeRedundantPosFile(const int pcnt) {
    if (pcnt==0)
        return -1;
    else {
        QDir dir(cfgDir);
        if (!dir.exists()) {
            return -1;
        }
        QStringList filters;
        filters << "*.pos";
        dir.setNameFilters(filters);
        QStringList fileList = dir.entryList();
#ifdef DBG
        qDebug() << "removeRedundantPosFile: entryCount=" << dir.count();
#endif
        for (int i=0; i<(signed)dir.count(); i++) {
            QString filename = fileList.at(i);
#ifdef DBG
            qDebug() << "removeRedundantPosFile: Checking" << filename;
#endif
            QString pattern = ".pos";
            int endIdx = filename.indexOf(pattern);

            if (endIdx==-1)
                return -1;

            // Extract filename
            filename = filename.left(endIdx);
#ifdef DBG
            qDebug() << "removeRedundantPosFile: endIdx=" << endIdx;
            qDebug() << "removeRedundantPosFile: filename=" << filename;
#endif

            bool ok;
            int idx = filename.toInt(&ok, 10);

            if (ok==false)
                return -1;
            else {
                if (idx > (pcnt-1)) {
#ifdef DBG
                    qDebug() << "removeRedundantPosFile: deletePos=" << idx;
#endif
                    if (idx >= 0) {
                        QString filename = cfgDir;
                        filename.append(QString::number(idx));
                        filename.append(".pos");
                        QFile::remove(filename);
                    }
                }
            }
        }

        return 0;
    }
}

Q_INVOKABLE void FileHandler::setPfoCmodel(const int idx, const QString name, const QString desc, const bool isYahoo) {
#ifdef DBG
    qDebug() << "C_Info: Append: " << name << " " << desc << " " << isYahoo << "to" << idx;
#endif
    if (idx >= 0) {
		if (idx>=pfoModel.pfoName.length()) {
			pfoModel.pfoName.append(name);
			pfoModel.pfoDesc.append(desc);
			pfoModel.pfoIsYahoo.append(isYahoo);
		}
		else {
			pfoModel.pfoName.replace(idx, name);
			pfoModel.pfoDesc.replace(idx, desc);
			pfoModel.pfoIsYahoo.replace(idx, isYahoo);
		}
	}
}

Q_INVOKABLE void FileHandler::clearPfoCmodel()
{
    if (pfoModel.pfoName.length()>0) {
        pfoModel.pfoName.clear();
        pfoModel.pfoDesc.clear();
        pfoModel.pfoIsYahoo.clear();
        pfoModel.pfoNum.clear();
    }
}

Q_INVOKABLE void FileHandler::removePfo(const int pfoIdx) {
    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    query.setForwardOnly(TRUE);
    if (!query.exec("DELETE FROM portfolio WHERE id =" + pfoIdx))
        qDebug() << "removePfoAll::QsqlQuery Error:" << query.lastError().type();

    // Update id after deleteion
    int id_cnt = 0;

    query.setForwardOnly(TRUE);
    if (query.exec("UPDATE portfolio SET id = " + id_cnt)) {
        while (query.next())
            id_cnt++;
    }
}

Q_INVOKABLE void FileHandler::removePfoCmodel(const int idx) {
    if (idx < pfoModel.pfoName.length() && idx >= 0) {
        pfoModel.pfoName.removeAt(idx);
        pfoModel.pfoDesc.removeAt(idx);
        pfoModel.pfoIsYahoo.removeAt(idx);
        pfoModel.pfoNum.removeAt(idx);
    }
}

// Clear array
Q_INVOKABLE void FileHandler::removePfoAll() {
    // Don't clear to avoid moving data from QML ListModel to C.
    //clearPfoCmodel();

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    query.setForwardOnly(TRUE);
    // Delete portfolio table
    //query.exec("DROP TABLE portfolio");
    // Delete all records
    if (!query.exec("DELETE FROM portfolio"))
        qDebug() << "removePfoAll::QsqlQuery Error:" << query.lastError().type();
}

void FileHandler::updatePfoNum(const int idx, const int num) {
    if (idx < pfoModel.pfoNum.length())
        pfoModel.pfoNum[idx] = num;
    else
        pfoModel.pfoNum.append(num);
}

// Delete portfolio file, this is currently not used.
/*
int FileHandler::deletePfo()
{
    QFile f( "portfolio.cfg" );

    if( !f.exists() )
    {
#ifdef DBG
        qDebug() << "Local portfolio does not exist.";
#endif

        return -1;
    }

    f.remove();
#ifdef DBG
    qDebug() << "Delete local portfolio.";
#endif

    f.close();

    return 0;
}
*/

///////////////////////////////////////////
//  Position Table
///////////////////////////////////////////
Q_INVOKABLE int FileHandler::loadPosNum(const int idx)
{
    QString posName = "pos_";
    posName.append(QString::number(idx));

    QSqlDatabase db = QSqlDatabase::database();

    if (db.tables(QSql::Tables).contains(posName)) {
        QSqlQuery query(db);

        // Get the size
        int db_size = 0;

        query.setForwardOnly(TRUE);
        if (query.exec("SELECT DISTINCT sym, exg FROM " + posName)) {
            while (query.next())
                db_size++;
        }
        else
            qDebug() << "loadPosNum::QsqlQuery Error:" << query.lastError().type();

        updatePfoNum(idx, db_size);
    }
    else {
        updatePfoNum(idx, 0);
    }

    return 0;
}

Q_INVOKABLE int FileHandler::loadPos(const int idx)
{
    if (idx < 0)
        return -1;

    clearHashCmodel();
    clearUniCmodel();
    clearPosCmodel();

    QString posName = "pos_";
    posName.append(QString::number(idx));

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    query.setForwardOnly(TRUE);
    if (query.exec("SELECT sym, exg, share, cost, comm, misc, id FROM " + posName)) {
        while(query.next()) {
            QString key = query.value(0).toString() + QString(":") + query.value(1).toString();

            // Store (sym,exg) key and id as value
            pHash.insertMulti( key, query.value(6).toInt() );

            posSymbol.append( query.value(0).toString() );
            posExg.append(    query.value(1).toString() );
            posShare.append(  query.value(2).toFloat() );
            posCost.append(   query.value(3).toFloat() );
            posStop.append(   query.value(4).toFloat() );
            posType.append(   query.value(5).toString() );
        }
    }
    else
        qDebug() << "loadPos::QsqlQuery Error:" << query.lastError().type();

    // Calculate total share/cost/com for unique (sym,exg) combo
    QList<QString> uniqueList;

    // Ordered by ascending key order
    uniqueList = pHash.uniqueKeys();

    // Alternatively, use 'SELECT DISTINCT', but 'ORDER BY sym AESC|DESC' does not work.
//    if (query.exec("SELECT DISTINCT sym, exg FROM " + posName)) {
//        while(query.next()) {
//            QString key = query.value(0).toString() + QString(":") + query.value(1).toString();
//            uniqueList.append(key);

//            qDebug() << "SQL distinct:" << key;
//        }
//    }
//    else
//        qDebug() << "loadPos::QsqlQuery Error:" << query.lastError().type();

    for (int k=0; k<uniqueList.length(); k++) {
        QString uniqueKey = uniqueList.at(k);
        QStringList tmp = uniqueKey.split(":");
        uniSymbol.append(tmp.at(0));
        uniExg.append(tmp.at(1));

        QMap<QString, int>::iterator i = pHash.find(uniqueKey);

        int  cnt = 0;

        // Floating point done in integer.
        quint64 myShare = 0;
        quint64 myCost = 0;
        quint64 myComm = 0;

        while (i != pHash.end() && i.key() == uniqueKey) {
            int idx = i.value();

//            if (posType.at(idx).toString()=="Sell") {
//                myShare -= posShare.at(idx).toInt();
//                myCost  -= posCost.at(idx).toFloat();
//                myComm  -= posStop.at(idx).toFloat();
//            }
//            else {

            // Error protection
            if (idx < posShare.length()) {
                myShare += quint64(posShare.at(idx).toFloat()*100);
                myCost  += quint64(posCost.at(idx).toFloat()*100)*quint64(posShare.at(idx).toFloat()*100);
                myCost  += quint64(posStop.at(idx).toFloat()*10000);
                myComm  += quint64(posStop.at(idx).toFloat()*100);
            }

#ifdef DBG
                qDebug() << i.key() << " " << i.value() << "(share,cost,comm)=("
                         << myShare << "," << myCost << "," << myComm << ")";
#endif

            ++i;
            cnt++;
        }

        // Store to list
        uniShare.append(dec2Pt<quint64>(myShare,2));
        uniCost.append(dec2Pt<quint64>(myCost,4));
        uniComm.append(dec2Pt<quint64>(myComm,2));
        uniNum.append(cnt);

#ifdef DBG
        qDebug() << "DBG: uniqueKey=" << uniqueKey << ", num=" << cnt;
        //qDebug() << "DBG: i=" << k << " uniNum=" << uniNum.at(k);
#endif
    }

    // Save memory footprint
//    pHash.clear();

    debugPos();

    updatePfoNum(idx, posSymbol.length());

    return 0;
}

Q_INVOKABLE int FileHandler::storePos(
        const int idx,
        const QString symbol,
        const QString exchange,
        const float share,
        const float cost,
        const float stop,
        const QString type)
{
#ifdef DBG
    qDebug() << "C_Info: storePos() " << symbol << " " << exchange << " " << share << " " << cost << " " << stop;
#endif
    if (idx < 0)
        return -1;

    posSymbol.append(symbol);
    posExg.append(exchange);
    posShare.append(share);
    posCost.append(cost);
    posStop.append(stop);
    posType.append(type);

    if (!posSymbol.isEmpty()) {
        QString posName = "pos_";
        posName.append(QString::number(idx));

        QSqlDatabase db = QSqlDatabase::database();
        QSqlQuery query(db);

        if (!db.tables(QSql::Tables).contains(posName)) {
            QSqlQuery query("CREATE TABLE " + posName +
                        " (id INT, sym TEXT, exg TEXT, share REAL, cost REAL, comm REAL, misc TEXT)", db);
        }

        // Get the size
        int db_size = 0;

        query.setForwardOnly(TRUE);
        if (query.exec("SELECT id FROM " + posName)) {
            while (query.next())
                db_size++;
        }
        else
            qDebug() << "storePos::QsqlQuery Error:" << query.lastError().type();

        // INSERT
        query.prepare("INSERT INTO " + posName +
                      " (id, sym, exg, share, cost, comm, misc) VALUES (:id, :sym, :exg, :share, :cost, :comm, :misc)");
        query.bindValue(":id",    db_size);
        query.bindValue(":sym",   symbol);
        query.bindValue(":exg",   exchange);
        query.bindValue(":share", share);
        if (cost != cost)
            query.bindValue(":cost",  0);
        else
            query.bindValue(":cost",  cost);
        query.bindValue(":comm",  stop);
        query.bindValue(":misc",  type);

        query.setForwardOnly(TRUE);

        if (!query.exec())
            qDebug() << "storePos::QsqlQuery Error:" << query.lastError().type();

        // Update position numbers
        if (pfoModel.pfoNum.length()>0 && idx < pfoModel.pfoNum.length()) {
            pfoModel.pfoNum[idx] = posSymbol.length();
        }
    }

    return 0;
}

Q_INVOKABLE int FileHandler::storePosAll(const int idx)
{
    if (idx < 0)
        return -1;

    if (!posSymbol.isEmpty()) {
        QString posName = "pos_";
        posName.append(QString::number(idx));

        QSqlDatabase db = QSqlDatabase::database();
        QSqlQuery query(db);

        if (!db.tables(QSql::Tables).contains(posName)) {
            QSqlQuery query("CREATE TABLE " + posName +
                        " (id INT, sym TEXT, exg TEXT, share REAL, cost REAL, comm REAL, misc TEXT)", db);
        }

        for (int i=0; i < posSymbol.count(); i++) {
            query.prepare("INSERT INTO " + posName +
                          " (id, sym, exg, share, cost, comm, misc) VALUES (:id, :sym, :exg, :share, :cost, :comm, :misc)");
            query.bindValue(":id", i);
            query.bindValue(":sym",   posSymbol.at(i).toString());
            query.bindValue(":exg",   posExg.at(i).toString());
            query.bindValue(":share", posShare.at(i).toString());
            if (posCost.at(i) != posCost.at(i))
                query.bindValue(":cost",  0);
            else
                query.bindValue(":cost",  posCost.at(i).toString());
            query.bindValue(":comm",  posStop.at(i).toString());
            query.bindValue(":misc",  posType.at(i).toString());

            query.setForwardOnly(TRUE);

            if (!query.exec()) {
                qDebug() << "storePosAll::QsqlQuery Error:" << query.lastError().type();
            }
            else
                query.next();
        }

        if (pfoModel.pfoNum.length()>0 && idx < pfoModel.pfoNum.length()) {
            pfoModel.pfoNum[idx] = posSymbol.length();
        }
    }

    return 0;
}

Q_INVOKABLE void FileHandler::setPosCmodel(
        const int idx,
        const QString symbol,
        const QString exchange,
        const float share,
        const float cost,
        const float stop,
        const QString type)
{
#ifdef DBG
    qDebug() << "C_Info: setPosCmodel: idx=" << idx << "," << symbol << " " << exchange << " " << share << " " << cost << " " << stop << " " << type;
#endif

    if (idx >= 0) {
		if (idx>=posSymbol.length()) {
			posSymbol.append(symbol);
			posExg.append(exchange);
			posShare.append(share);
			posCost.append(cost);
			posStop.append(stop);
            posType.append(type);
		}
		else {
            posSymbol.replace(idx, symbol);
			posExg.replace(idx, exchange);
			posShare.replace(idx, share);
			posCost.replace(idx, cost);
			posStop.replace(idx, stop);
            posType.replace(idx, type);
        }
	}
}

Q_INVOKABLE void FileHandler::removePosCmodel(const int idx)
{
#ifdef DBG
    qDebug() << "C_Info: Remove pos entry " << idx;
#endif

    if (idx < posSymbol.length() && idx >= 0){
        posSymbol.removeAt(idx);
        posExg.removeAt(idx);
        posShare.removeAt(idx);
        posCost.removeAt(idx);
        posStop.removeAt(idx);
        posType.removeAt(idx);
    }
}

Q_INVOKABLE void FileHandler::clearPosCmodel()
{
    if (posSymbol.length()>0) {
        posSymbol.clear(); posExg.clear();
        posShare.clear();  posCost.clear();
        posStop.clear();   posType.clear();
    }
}

Q_INVOKABLE void FileHandler::removePos(const int idx, const QString sym, const QString exg)
{
    qDebug() << "removePos: " << idx << ", " << sym << ":" << exg;

    QString posName = "pos_";
    posName.append(QString::number(idx));

    QSqlDatabase db = QSqlDatabase::database();

    if (db.tables(QSql::Tables).contains(posName)) {
        QSqlQuery query(db);

        // This deletes all duplicated items.
        query.prepare("DELETE FROM " + posName +
                      " WHERE (sym = :sym) AND (exg = :exg)");
        query.bindValue(":sym", sym);
        query.bindValue(":exg", exg);

        query.setForwardOnly(TRUE);
        if (!query.exec())
            qDebug() << "removePos::QsqlQuery Error:" << query.lastError().type();

        // Update id after deleteion
        int id_cnt = 0;

        query.setForwardOnly(TRUE);
        if (query.exec("UPDATE " + posName + " SET id = " + id_cnt)) {
            qDebug() << "removePos: update_id = " + id_cnt;
            while (query.next())
                id_cnt++;
        }
    }
}

Q_INVOKABLE void FileHandler::removePosAll(const int idx)
{
    // Don't clear QList to aviod moving data from QML ListModel to C.
    //clearPosCmodel();

    QString posName = "pos_";
    posName.append(QString::number(idx));

    QSqlDatabase db = QSqlDatabase::database();

    if (db.tables(QSql::Tables).contains(posName)) {
        QSqlQuery query(db);
        query.exec("DELETE FROM " + posName);
    }
}

Q_INVOKABLE void FileHandler::deletePos(const int idx)
{
    //qDebug() << "C_Info: deletePos=" << idx;
    if (idx >= 0) {
        QString posName = "pos_";
        posName.append(QString::number(idx));

        QSqlDatabase db = QSqlDatabase::database();
        QSqlQuery query(db);

        query.setForwardOnly(TRUE);
        query.exec("DROP TABLE " + posName);
    }
}

Q_INVOKABLE bool FileHandler::renamePos(const int old_idx, const int new_idx) {
    QString oldName = "pos_";
    oldName.append(QString::number(old_idx));

    QString newName = "pos_";
    newName.append(QString::number(new_idx));

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    query.setForwardOnly(TRUE);
    bool result = query.exec("ALTER TABLE " + oldName + " RENAME TO " + newName);

    return result;
}

Q_INVOKABLE int FileHandler::loadTx(const int idx, const QString sym, const QString exg)
{
#ifdef DBG
    qDebug() << "loadTx: (idx,sym,exg)=(" << idx << "," << sym << "," << exg << ")";
#endif

    if (idx < 0)
        return -1;

    clearTxCmodel();

    QString posName = "pos_";
    posName.append(QString::number(idx));

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    query.prepare("SELECT id FROM " + posName +
                  " WHERE (sym = :sym) AND (exg = :exg)");
    query.bindValue(":sym", sym);
    query.bindValue(":exg", exg);

    query.setForwardOnly(TRUE);

    if (query.exec()) {
        while (query.next()) {
            //qDebug() << "loadTx:" << query.value(0).toInt() ;
            txId.append(     query.value(0).toInt() );
        }
    }
    else
        qDebug() << "loadTx::QsqlQuery Error:" << query.lastError().type();

    return 0;
}

Q_INVOKABLE void FileHandler::setTx(
        const int posIdx,
        const int idx,
        const float share,
        const float cost,
        const float stop,
        const QString type)
{
    int txIdx = txId.at(idx).toInt();

#ifdef DBG
    qDebug() << "C_Info: setTx: (posIdx, idx, txId)=(" << posIdx << "," << idx << "," << txIdx << "). " << share << " " << cost << " " << stop << " " << type;
#endif

    if (txIdx >= 0) {
        if (txIdx>=posShare.length()) {
            posShare.append(share);
            posCost.append(cost);
            posStop.append(stop);
            posType.append(type);
        }
        else {
            posShare.replace(txIdx, share);
            posCost.replace(txIdx, cost);
            posStop.replace(txIdx, stop);
            posType.replace(txIdx, type);
        }
    }

    QString posName = "pos_";
    posName.append(QString::number(posIdx));

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    // (id, sym, exg, share, cost, comm, misc)
    query.prepare("UPDATE " + posName +
                  " SET (share = :share, cost = :cost, comm = :comm, misc = :misc)" +
                  " WHERE (id = :id)");
    query.bindValue(":share", share);
    query.bindValue(":cost",  cost);
    query.bindValue(":comm",  stop);
    query.bindValue(":misc",  type);
    query.bindValue(":id",    txIdx);

    query.setForwardOnly(TRUE);

    if (!query.exec()) {
        qDebug() << "setTx::QsqlQuery Error:" << query.lastError().type() << ", "
                 << query.lastError().driverText() << ", "
                 << query.executedQuery();
    }
}

Q_INVOKABLE void FileHandler::removeTx(const int posIdx, const int idx)
{
    int txIdx = txId.at(idx).toInt();
#ifdef DBG
    qDebug() << "C_Info: removeTx " << posIdx << " " << idx << ", txIdx=" << txIdx;
#endif

    if (txIdx >= 0) {
        if (txIdx<posShare.length()) {
            posShare.removeAt(txIdx);
            posCost.removeAt(txIdx);
            posStop.removeAt(txIdx);
            posType.removeAt(txIdx);
        }
    }

    QString posName = "pos_";
    posName.append(QString::number(posIdx));

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    query.prepare("DELETE FROM " + posName +
                  " WHERE (id = :id)");
    query.bindValue(":id", txIdx);

    query.setForwardOnly(TRUE);

    if (!query.exec())
        qDebug() << "removeTx::QsqlQuery Error:" << query.lastError().type() << " " << query.executedQuery();

    // Update id after deleteion
    int id_cnt = 0;

    qDebug() << id_cnt;
    query.setForwardOnly(TRUE);
    if (query.exec("SELECT id FROM " + posName)) {
        qDebug() << "removePos: update_id = " + id_cnt;
        while (query.next()) {
            int orig_id = query.value(0).toInt();
            query.prepare("UPDATE " + posName + " SET id = :idx WHERE id = :id");

            query.bindValue(":idx", orig_id);
            query.bindValue(":idx", id_cnt);

            if (!query.exec())
                qDebug() << "removeTx-Update id::QsqlQuery Error:" << query.lastError().type() << " " << query.executedQuery();

            id_cnt++;
        }
    }
}

Q_INVOKABLE void FileHandler::clearTxCmodel()
{
    if (txId.length()>0)
        txId.clear();
}

Q_INVOKABLE void FileHandler::clearCsvCmodel()
{
    if (csvList.length()>0)
        csvList.clear();
}

Q_INVOKABLE void FileHandler::clearUniCmodel()
{
    //qDebug() << uniSymbol.length() << uniExg.length() << uniShare.length() << uniCost.length() << uniComm.length() << uniNum.length();

    if (uniSymbol.length()>0) {
        uniSymbol.clear(); uniExg.clear();
        uniShare.clear();  uniCost.clear();
        uniComm.clear();   uniNum.clear();
    }
}

Q_INVOKABLE void FileHandler::clearHashCmodel() {
    if (pHash.count()>0)
        pHash.clear();
}

void FileHandler::debugPos() {
    for (int i=0; i<posSymbol.count(); i++) {
#ifdef DBG
        qDebug() << i << "="
                 << posSymbol[i].toString() << ":"
                 << posExg[i].toString() << ":"
                 << posShare[i].toInt() << ":"
                 << posCost[i].toFloat() << ":"
                 << posStop[i].toFloat();
#endif
    }
}

Q_INVOKABLE void FileHandler::removeHashCmodel(const QString sym, const QString exg)
{
    QString key = sym + ":" + exg;
    QMap<QString, int>::iterator i = pHash.find(key);

    while (i != pHash.end() && i.key() == key) {
        int txIdx = i.value();

        removePosCmodel(txIdx);

        ++i;
    }
}

////////////////////////////
// Utility functions
////////////////////////////
Q_INVOKABLE void FileHandler::listCSV() {
    // Remove *.csv files
    csvList.clear();

#ifdef Q_OS_SYMBIAN
    QString csvDir = "e:/";
#else
    QString csvDir = "/home/user/MyDocs/";
#endif

    QDir dir(csvDir);
    if (dir.exists()) {
        QStringList filters;
        filters << "*.csv";
        dir.setNameFilters(filters);
        QStringList fileList = dir.entryList();
        for (int i=0; i<(signed)dir.count(); i++) {
            csvList.append(fileList.at(i));
        }
    }
}

Q_INVOKABLE int FileHandler::loadCSV(QString name)
{
#ifdef Q_OS_SYMBIAN
    QString csvDir = "e:/";
#else
    QString csvDir = "/home/user/MyDocs/";
#endif

    QString inF = csvDir;
    inF.append(name);

    QFile f(inF);

    if( !f.exists() )
    {
#ifdef DBG
        qDebug() << "C_Info: " << inF << " does not exist.";
#endif

        return -1;
    }

    if( !f.open( QIODevice::ReadOnly ) )
    {
#ifdef DBG
        qDebug() << "C_Info: Failed to open " << inF << " for read.";
#endif

        return -1;
    }

    QTextStream ts( &f );
    QStringList strList;

    int line_cnt = 0;
    bool posExist = false;

    // Get db_size
    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    // Get the size
    int db_size = 0;

    query.setForwardOnly(TRUE);
    if (query.exec("SELECT id FROM portfolio")) {
        while (query.next())
            db_size++;
    }
    else
        qDebug() << "addPfo::QsqlQuery Error:" << query.lastError().type();

    // Store in QMap
    // Format: "Symbol,Shares,Purchase price per share,Commission"
    QMap<QString, int> cMap;

    while ( !ts.atEnd() ) {
        QString lineTxt = ts.readLine();

        // Name field can contain string begin and end with ".
        // Within the string there might be comma.
        if (lineTxt.contains("\"")) {
            // Find the first \"
            int sIdx = lineTxt.indexOf(QString("\""));

            // Replace the comma immediately following \"
            if (sIdx > -1) {
                int commaIdx = lineTxt.indexOf(QString(","), sIdx);
                lineTxt.remove(commaIdx, 1);
            }
        }

        strList = lineTxt.split(",");

        //qDebug() << strList;

        // Extract header and build map
        if (line_cnt==0) {
            for (int i=0; i<strList.length(); i++) {
                cMap.insert( strList[i].toLocal8Bit().constData(), i );
            }
        }
        else {
            QString s = strList[cMap.value("Symbol")].toLocal8Bit().constData();
            QStringList symList = s.split(":", QString::SkipEmptyParts);

            // Store if non-empty
            if (!symList.isEmpty()) {
                posExist = true;
                QString exg;

                if (symList.length()==2)
                    exg = strList.at(1);
                else
                    exg = "";

                //qDebug() << db_size << symList.at(0) << exg;

                storePos(db_size,
                         symList.at(0),
                         exg,
                         strList.at(cMap.value("Shares")).toFloat(),
                         strList.at(cMap.value("Purchase price per share")).toFloat(),
                         strList.at(cMap.value("Comission")).toFloat(),
                         QString("Buy")
                );
            }
        }

        line_cnt++;
    }

    if (posExist) {
        // Create entry in pfo table
        addPfo(name, "", false);
    }

    return 0;
}

Q_INVOKABLE QString FileHandler::toCSV(const int idx, QString name)
{
    if (idx < 0)
        return "-1";

    QString posName = "pos_";
    posName.append(QString::number(idx));

    QString outF = cfgDir;
    outF.append("stockona_");
    outF.append(name);
    outF.append(".csv");

    QFile of( outF );

    if( !of.open( QIODevice::WriteOnly ) )
    {
#ifdef DBG
        qDebug() << "Failed to open " << outF << " for write.";
#endif
        return "-1";
    }

    QSqlDatabase db = QSqlDatabase::database();
    QSqlQuery query(db);

    QTextStream ots( &of );

    ots << "Symbol,Shares,Purchase price per share,Commission" << endl;

    query.setForwardOnly(TRUE);
    if (query.exec("SELECT sym, exg, share, cost, comm FROM " + posName)) {
        while(query.next()) {
            ots << query.value(0).toString() << ":" << query.value(1).toString() << ","
                << query.value(2).toFloat() << ","
                << query.value(3).toFloat() << ","
                << query.value(4).toFloat() << "," << endl;
        }
    }
    else {
        qDebug() << "toCSV::QsqlQuery Error:" << query.lastError().type();
        of.close();
        return "-1";
    }

    of.close();
    return cfgDir;
}

// Use 64-bit integer for calculation to avoid floating point errors...
// price = true_price * 100
Q_INVOKABLE QVariantList FileHandler::calcUniSymPerf (const int &i, const int &price) {
    QVariantList perfData;

    quint64 intShare  = quint64(uniShare.at(i).toFloat()*100);
    quint64 intValue  = quint64(price)*intShare;
    quint64 intCost   = quint64(uniCost.at(i).toFloat()*10000);
    qint64  intGain   = intValue - intCost;
    qint64  gainPtg   = (intCost!=0) ? (10000*intGain)/qint64(intCost) : 0;
//    qDebug() << "(price,share,value,cost,gain,%)=" << price << " " << intShare << " " << intValue << " "
//             << intCost << " " << intGain << " " << gainPtg;

    perfData.append( dec2Pt<qint64>(intGain,  4) );          // gain
    perfData.append( dec2Pt<quint64>(intCost, 4) );         // cost
    perfData.append( dec2Pt<quint64>(intValue,4) );         // value

    // gain percentage
    if (intCost==0) {
        perfData.append("-");
    }
    else {
        perfData.append( dec2Pt<qint64>(gainPtg, 2) );         // gain %
    }

    accumPfoPerf(intGain, intCost, intValue);

#ifdef DBG
    qDebug() << "(cost, value, gainPtg, share, price)=" <<
                  intCost << " " << intValue << " " << gainPtg << " " << intShare << " " << price;
#endif

    return perfData;
}

Q_INVOKABLE QString FileHandler::calcGainPtg (const float &cost, const float &gain) {
    qint64 intGain = 10000*qint64(gain*100);
    qint64 intCost = qint64(100*cost);
    qint64 gainPtg = (cost!=0) ? intGain/intCost : 0;
//    qDebug() << "(cost, gain, gainPtg)=" << cost << "," << gain << "," << gainPtg << " " << intGain;
    return dec2Pt<qint64>(gainPtg, 2);
}

Q_INVOKABLE void FileHandler::clearPfoPerf () {
    pfoGain  = pfoCost  = pfoValue = 0;
}

Q_INVOKABLE void FileHandler::accumPfoPerf (const qint64 & a, const quint64 & b, const quint64 & c) {
    pfoGain  += a;
    pfoCost  += b;
    pfoValue += c;

    //qDebug() << QString::number(c, 'g', 10) << " " << QString::number(pfoValue, 'g', 10);
}

Q_INVOKABLE QString FileHandler::calcTxCost (const float share, const float comm, const float price) {
    quint64 cost = quint64(share*100)*quint64(price*100) + quint64(comm*10000);
    return dec2Pt<quint64>(cost, 4);
}

Q_INVOKABLE QString FileHandler::formatNumber (const float number) {
    QString s;
    //qDebug() << "formatNum:" << QString::number(number, 'f', 2);
    s.sprintf("%.2f", number);
    return s;
//    return QString::number(number, 'f', 2);
}

Q_INVOKABLE QVariantList FileHandler::parseCSV (const QString data) {
        QVariantList tokens;
        std::string str = data.toStdString();

        char delimiter;
        strcpy(&delimiter, ",");

        unsigned int pos = 0;
        bool quotes = false;
        std::string field = "";

        while(str[pos] != 0x00 && pos < str.length()){
            char c = str[pos];
            // Start of quote
            if ( !quotes && c == '"' ){
                quotes = true;
            // End of quote
            } else if ( quotes && c== '"' ){
//                if (pos + 1 <str.length() && str[pos+1]== '"' ){
//                    field.push_back(c);
//                    pos++;
//                } else {
                    quotes = false;
//                }
            } else if ( !quotes && c == delimiter) {
                tokens.push_back(field.c_str());
                field.clear();
            // new line or CR
            } else if ( !quotes && c == 0x0A ){
                tokens.push_back(field.c_str());
                field.clear();
            } else if ( c!= 0x0D ){
                field.push_back(c);
            }
//#ifdef DBG
//            qDebug() << "pos=" << pos << "field=" << field.c_str() << "c=" << c;
//#endif
            pos++;
        }
//#ifdef DBG
//        //qDebug()<<data;
//        qDebug()<<tokens;
//#endif
        return tokens;
}

Q_INVOKABLE QString FileHandler::parseGoogleRelated (const QString data) {
    QString result;

    if (!data.isEmpty()) {
        std::string tmp = data.toStdString();
        //qDebug() << tmp.c_str();

        // std::string
        int startIdx = tmp.find("google.finance.data");
        int endIdx   = tmp.find(";", startIdx);
        startIdx = tmp.find("{", startIdx);
        //qDebug() << "(start, end)=(" << startIdx << "," << endIdx << ")";

        //if (startIdx!=-1 && endIdx!=-1) {
        if (startIdx!=-1 && endIdx!=-1 && (startIdx < endIdx)) {
            tmp = tmp.substr(startIdx, endIdx - startIdx);
            result = tmp.c_str();
            //qDebug() << result;
        }
        else {
            result = "0";
        }
    }
    else {
        result = "0";
    }

    return result;
}

Q_INVOKABLE QVariantList FileHandler::parseGoogleCurrency (const QString data) {
    QString result;
    QVariantList obj;

    /*
    <div id=currencies>
    <div class=hdg><div class=float><h3>Currencies</h3></div>
    <div class="gf-reorder-btn SP_menu_button"></div>
    </div>

    <div class=sfe-section>
    <table class=quotes width=100%><tbody><tr>
    <td class=symbol><a href="/finance?q=EURUSD" >EUR/USD</a>
    <td class=price>1.3410
    <td class="change chr">-0.0010 (-0.07%)<tr>
    <td class=symbol><a href="/finance?q=USDJPY" >USD/JPY</a>
    <td class=price>77.7100
    <td class="change chr">-0.3200 (-0.41%)<tr>
    <td class=symbol><a href="/finance?q=GBPUSD" >GBP/USD</a>
    <td class=price>1.5605
    <td class="change chg">+0.0003 (0.02%)<tr>
    <td class=symbol><a href="/finance?q=USDCAD" >USD/CAD</a>
    <td class=price>1.0089
    <td class="change chr">-0.0088 (-0.86%)<tr>
    <td class=symbol><a href="/finance?q=USDHKD" >USD/HKD</a>
    <td class=price>7.7716
    <td class="change chg">+0.0051 (0.07%)<tr>
    <td class=symbol><a href="/finance?q=USDCNY" >USD/CNY</a>
    <td class=price>6.3645
    <td class="change chg">+0.0049 (0.08%)<tr>
    <td class=symbol><a href="/finance?q=AUDUSD" >AUD/USD</a>
    <td class=price>1.0261
    <td class="change chg">+0.0027 (0.26%)
    </table>
    */

    if (!data.isEmpty()) {
        bool cont = true;
        std::string tmp = data.toStdString();
        //qDebug() << tmp.c_str();

        // Parse Stock

        // Parse Currency
        int startIdx = tmp.find("<div id=currencies");
        int endIdx   = tmp.find("</table>", startIdx);

        endIdx       = tmp.find(">", endIdx);
        endIdx       = (endIdx==-1) ? -1 : (endIdx+1);
        startIdx     = tmp.find("<td class=symbol>", startIdx);

        //qDebug() << "Currency: start=" << startIdx << " end=" << endIdx;
        if (startIdx!=-1 && endIdx!=-1 && (startIdx < endIdx)) {
            std::string cut = tmp.substr(startIdx, endIdx - startIdx);
            result = cut.c_str();
            //qDebug() << result;

            cont = parseGoogleSFE(result, obj, 0);
        }
        else {
            cont = false;
        }

        // Parse Bond, not always exists
        if (cont) {
            startIdx = tmp.find("<div id=bonds", startIdx);
            endIdx   = tmp.find("</table>", startIdx);

            endIdx   = tmp.find(">", endIdx);
            endIdx   = (endIdx==-1) ? -1 : (endIdx+1);
            startIdx = tmp.find("<td class=symbol>", startIdx);

            //qDebug() << "Bond: start=" << startIdx << " end=" << endIdx;
            if (startIdx!=-1 && endIdx!=-1 && (startIdx < endIdx)) {
                tmp = tmp.substr(startIdx, endIdx - startIdx);
                result = tmp.c_str();

                cont = parseGoogleSFE(result, obj, 1);
            }
//            else {
//                if (!obj.isEmpty())
//                    obj.removeLast();
//            }
        }
    }

    return obj;
}

// mode: 0, Currencies / 1, Bond / 2, Stock
bool FileHandler::parseGoogleSFE (const QString src, QVariantList &obj, const short mode) {
    if (!src.isEmpty()) {
        // Remove isNewspace()
        QString data;
        data = src.simplified();
        std::string tmp = data.toStdString();
        //qDebug() << tmp.c_str();

        int startIdx = 0;
        int endIdx   = 0;
        short done   = 0;
        int endOfTable = tmp.find("</table>");

        // Header
        if (mode==0) {
            obj.append("- Currencies");
            obj.append("header");
            obj.append("-");
        }
        else if (mode==1){
            obj.append("- US Bond ");
            obj.append("header");
            obj.append("-");
        }

        while (done < 10) {
            // Symbol, 0=currency; 1=bond
            if (mode==0) {
                startIdx = tmp.find("<td class=symbol>", startIdx);
                endIdx   = tmp.find("</a", startIdx);
                startIdx = tmp.find(">", startIdx+1);
                startIdx = tmp.find(">", startIdx+1);
                startIdx = (startIdx==-1) ? -1 : (startIdx+1);
            }
            else {
                startIdx = tmp.find("<td class=symbol>", startIdx);
                endIdx   = tmp.find("<", startIdx+1);
                startIdx = tmp.find(">", startIdx+1);
                startIdx = (startIdx==-1) ? -1 : (startIdx+1);
            }
//            qDebug() << "(start, end)=(" << startIdx << "," << endIdx << ")";

            if (startIdx!=-1 && endIdx!=-1 && (startIdx < endIdx)) {
                std::string cut = tmp.substr(startIdx, endIdx - startIdx);
#ifdef DBG
                qDebug() << "Symbol=" << cut.c_str();
#endif
                obj.append( cut.c_str() );
            }
            else {
                break;
            }

            // Price
            startIdx = tmp.find("<td class=price>", startIdx);
            endIdx   = tmp.find("<", startIdx+1);
            startIdx = tmp.find(">", startIdx+1);
            startIdx = (startIdx==-1) ? -1 : (startIdx+1);

            if (startIdx!=-1 && endIdx!=-1 && (startIdx < endIdx)) {
                std::string cut = tmp.substr(startIdx, endIdx - startIdx);
                //qDebug() << "(start, end)=(" << startIdx << "," << endIdx << ")";
#ifdef DBG
                qDebug() << "price=" << cut.c_str();
#endif

                obj.append( cut.c_str() );
            }
            else {
                if (!obj.isEmpty())
                    obj.removeLast();
                break;
            }

            // Change
            startIdx = tmp.find("<td class=\"change ch", startIdx);
            endIdx   = tmp.find("<", startIdx+1);
            startIdx = tmp.find(">", startIdx+1);
            startIdx = (startIdx==-1) ? -1 : (startIdx+1);

            if (startIdx!=-1 && endIdx!=-1 && (startIdx < endIdx)) {
                std::string cut = tmp.substr(startIdx, endIdx - startIdx);
#ifdef DBG
                qDebug() << "change=" << cut.c_str();
#endif
                obj.append( cut.c_str() );
            }
            else {
                if (!obj.isEmpty())
                    obj.removeLast();
                if (!obj.isEmpty())
                    obj.removeLast();
                break;
            }

            // Check for done
            done++;
            if ( endOfTable == endIdx ) {
#ifdef DBG
                qDebug() << "##### Done: " << done;
#endif
                break;
            }
        } // End of while

        return (obj.count()%3==0);
    }
    else {
        return false;
    }

//    for (int i=0; i<obj.count(); i++) {
//        qDebug() << "i=" << i << ", obj=" << obj[i];
//    }
}

Q_INVOKABLE QVariantList FileHandler::parseGoogleFinanceSearch (const QString data) {
    // <a id=rc-1 href="/finance?q=NYSE:MMM&sq=MMM&sp=1" >3M Co</a></nobr>
    // <td class=exch>FRA
    QString result;
    QVariantList obj;

    if (!data.isEmpty()) {
        // Remove isWhitespace(). Continuous whitespace are consolidated to one.
        result          = data.simplified();
        //
        std::string tmp = result.toStdString();
#ifdef DBG
        //qDebug() << tmp.c_str();
#endif

        // Parse EXG:SYM
        int startIdx, endIdx, endIdx2;
        bool done = false;
        bool cont;

        startIdx = tmp.find("<div class=sfe-content>");

        while (!done) {
            startIdx = tmp.find("<a id=rc-", startIdx);
            cont = true;

            // determine whether ends
            if (startIdx==-1) {
                done = true;
#ifdef DBG
                qDebug() << "done";
#endif
                break;
            }

            // Check for end of tag
            endIdx   = tmp.find("\" >", startIdx);
            // Check for '&' symbol in the tag string
            endIdx2   = tmp.find("&", startIdx);
            if ((endIdx2>0) && (endIdx2<endIdx))
                endIdx = endIdx2;

            startIdx = tmp.find("finance?q=", startIdx);
#ifdef DBG
            qDebug() << "sym.(start, end)=(" << startIdx << "," << endIdx << ")";
#endif
            if (startIdx!=-1 && endIdx!=-1) {
                // finace?cid=xxxx causes this
                if (startIdx < endIdx) {
                    // Point to the string after 'q='
                    startIdx += 10;
                    std::string cut = tmp.substr(startIdx, endIdx - startIdx);
                    result = cut.c_str();
#ifdef DBG
                    qDebug() << result;
#endif
                    QStringList spt = result.split(":");

                    // sym
                    obj.append(spt[1]);
                    // exg
                    obj.append(spt[0]);
                }
                else {
                    // Bypass fullname parsing
                    startIdx = endIdx;
                    cont = false;
                }
            }
            else {
                break;
            }

            // Parse FullName
            if (cont) {
                if (endIdx==-1)
                    startIdx = -1;
                else {
                    startIdx = tmp.find(">", endIdx);
                    startIdx = (startIdx==-1) ? -1 : (startIdx+1);
                }
                endIdx   = tmp.find("</a>", startIdx);
#ifdef DBG
                qDebug() << "name.(start, end)=(" << startIdx << "," << endIdx << ")";
#endif

                if (startIdx!=-1 && endIdx!=-1) {
                    // Error handling
                    if (startIdx < endIdx) {
                        std::string cut = tmp.substr(startIdx, endIdx - startIdx);
                        result = cut.c_str();
#ifdef DBG
                        qDebug() << result;
#endif
                        obj.append(result);
                    }
                    else {
                        obj.removeLast();
                        obj.removeLast();
                    }
                }
                else {
                    obj.removeLast();
                    obj.removeLast();
                    break;
                }
            }
        }
    }

    return obj;
}
