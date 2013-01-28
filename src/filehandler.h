#ifndef FILEHANDLER_H
#define FILEHANDLER_H

#include <string>
#include <iostream>
#include <cmath>
#include <QObject>
#include <QIODevice>
#include <QFile>
#include <QTextStream>
#include <QDir>
#include <QByteArray>
#include <QString>
#include <QStringList>
#include <QList>
#include <QVariant>
#include <QDebug>
#include <QMap>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QtCore/qmath.h>

#if defined(Q_OS_SYMBIAN) || defined(Q_OS_BLACKBERRY)
  #include <openssl/evp.h>
  #include <openssl/aes.h>
#elif defined(Q_WS_HARMATTAN)
  #include <aegis_crypto.h>
#endif

#include "params.h"

class FileHandler : public QObject
{
    Q_OBJECT

    // portfolio
    Q_PROPERTY (QVariantList localPfoName READ localPfoName)
    Q_PROPERTY (QVariantList localPfoNum READ localPfoNum)
    Q_PROPERTY (QVariantList localPfoDesc READ localPfoDesc)
    Q_PROPERTY (QVariantList localPfoIsYahoo READ localPfoIsYahoo)

    // position
    Q_PROPERTY (QVariantList localPosSymbol READ localPosSymbol)
    Q_PROPERTY (QVariantList localPosExg READ localPosExg)
    Q_PROPERTY (QVariantList localPosShare READ localPosShare)
    Q_PROPERTY (QVariantList localPosCost READ localPosCost)
    Q_PROPERTY (QVariantList localPosStop READ localPosStop)
    Q_PROPERTY (QVariantList localPosType READ localPosType)

    Q_PROPERTY (QVariantList localTxId READ localTxId)
//    Q_PROPERTY (QVariantMap localUniHash READ localUniHash)

    Q_PROPERTY (QVariantList localUniSymbol READ localUniSymbol)
    Q_PROPERTY (QVariantList localUniExg READ localUniExg)
    Q_PROPERTY (QVariantList localUniShare READ localUniShare)
    Q_PROPERTY (QVariantList localUniCost READ localUniCost)
    Q_PROPERTY (QVariantList localUniComm READ localUniComm)
    Q_PROPERTY (QVariantList localUniNum READ localUniNum)

    Q_PROPERTY (QVariantList localCsvList READ localCsvList)

    Q_PROPERTY (QString localPfoGain READ localPfoGain)
    Q_PROPERTY (QString localPfoCost READ localPfoCost)
    Q_PROPERTY (QString localPfoValue READ localPfoValue)

    // Store the absolute index in portfolio list
    Q_PROPERTY (int localPos READ localPos WRITE setLocalPos)

    // ps
    Q_PROPERTY (bool plus READ plus NOTIFY plusChanged)

public:
    explicit FileHandler(QObject *parent = 0);

    // activePos
    void setLocalPos(const int &posIdx) {
        actvPos = posIdx;
    }

    // encrypt
    Q_INVOKABLE QVariant encryptData(const QString &);
    Q_INVOKABLE QString decryptData(const QVariant);

    // portfolio
    Q_INVOKABLE int storePfoAll();
    Q_INVOKABLE int addPfo(const QString , const QString, const bool);
    Q_INVOKABLE int loadPfo();
    Q_INVOKABLE int setPfo(const int, const QString , const QString, const bool);

    Q_INVOKABLE void removePfo(const int);
    Q_INVOKABLE void removePfoCmodel(const int);
    Q_INVOKABLE void removePfoAll();
    Q_INVOKABLE void setPfoCmodel(const int, const QString, const QString, const bool);
    Q_INVOKABLE int  loadPosNum(const int);
    Q_INVOKABLE void clearPfoCmodel();

    // position
    Q_INVOKABLE int  storePosAll(const int);
    Q_INVOKABLE int  storePos(const int, const QString, const QString, const float, const float, const float, const QString);
    Q_INVOKABLE int  loadPos(const int);
    Q_INVOKABLE void removePosAll(const int);
    Q_INVOKABLE void removePos(const int, const QString, const QString);
    Q_INVOKABLE void deletePos(const int);
    Q_INVOKABLE bool renamePos(const int, const int);

    Q_INVOKABLE void setPosCmodel(const int, const QString, const QString, const float, const float, const float, const QString);
    Q_INVOKABLE void removePosCmodel(const int);
    Q_INVOKABLE void clearPosCmodel();

    Q_INVOKABLE int  loadTx(const int idx, const QString sym, const QString exg);
    Q_INVOKABLE void setTx(const int, const int, const float, const float, const float, const QString);
    Q_INVOKABLE void removeTx(const int, const int);
    Q_INVOKABLE void clearTxCmodel();
    Q_INVOKABLE void clearUniCmodel();
    Q_INVOKABLE void clearHashCmodel();
    Q_INVOKABLE void removeHashCmodel(const QString, const QString);

    // Utility function
    int convertPortfolioToDB();
    Q_INVOKABLE QString toCSV(const int, QString);
    Q_INVOKABLE QVariantList calcUniSymPerf(const int &, const int &);
    Q_INVOKABLE QString calcTxCost(const float, const float, const float);
    Q_INVOKABLE QString formatNumber(const float);
    Q_INVOKABLE void clearPfoPerf();
    Q_INVOKABLE void accumPfoPerf(const qint64 &, const quint64 &, const quint64 &c);
    Q_INVOKABLE QString calcGainPtg (const float &cost, const float &gain);

    // csv
    Q_INVOKABLE QVariantList parseCSV(const QString);
    Q_INVOKABLE int loadCSV(QString);
    Q_INVOKABLE void listCSV();
    Q_INVOKABLE void clearCsvCmodel();

    Q_INVOKABLE QString parseGoogleRelated(const QString);
    Q_INVOKABLE QVariantList parseGoogleCurrency(const QString);
    Q_INVOKABLE QVariantList parseGoogleFinanceSearch(const QString);
    bool parseGoogleSFE(const QString, QVariantList&, const short);

    // Visible to QML
    QVariantList localPfoName() const { return pfoModel.pfoName; }
    QVariantList localPfoNum() const { return pfoModel.pfoNum; }
    QVariantList localPfoDesc() const { return pfoModel.pfoDesc; }
    QVariantList localPfoIsYahoo() const { return pfoModel.pfoIsYahoo; }

    QVariantList localPosSymbol() const { return posSymbol; }
    QVariantList localPosExg() const { return posExg; }
    QVariantList localPosShare() const { return posShare; }
    QVariantList localPosCost() const { return posCost; }
    QVariantList localPosStop() const { return posStop; }
    QVariantList localPosType() const { return posType; }

    QVariantList localTxId() const { return txId; }
//    QVariantMap  localUniHash() const { return pHash; }

    QVariantList localUniSymbol() const { return uniSymbol; }
    QVariantList localUniExg() const { return uniExg; }
    QVariantList localUniShare() const { return uniShare; }
    QVariantList localUniCost() const { return uniCost; }
    QVariantList localUniComm() const { return uniComm; }
    QVariantList localUniNum() const { return uniNum; }

    QVariantList localCsvList() const { return csvList; }

    // const modifier after function name means not allowed to
    // call non-const function & modify member variables.
    QString localPfoGain()  { return dec2Pt<qint64>(pfoGain, 4);  }
    QString localPfoCost()  { return dec2Pt<quint64>(pfoCost, 4);  }
    QString localPfoValue() { return dec2Pt<quint64>(pfoValue,4); }

    int localPos() const { return actvPos; }
    bool plus() const     { return sPlus; }

signals:
    void plusChanged();

public slots:
    //Q_INVOKABLE void slotTest(int x);

private:
    //int  deletePfo(); // obsolete
    void debugPfo();
    void updatePfoNum(const int, const int);
    void debugPos();
    template <typename T> QString dec2Pt (const T a, const int decPt) {
        QString s;
        int div = (decPt==4) ? 10000 :
                  (decPt==2) ? 100 : 1;
        s.append(QString::number(a/div));
        if (decPt!=0){
            s.append(".");
            int frac = a - div*(a/div);
            if (frac<0) frac = -frac;
            frac = frac/((decPt==4) ? 100 : 1);
            if (frac==0)
                s.append("00");
            else
                s.append(QString::number(frac));
        }
        return s;
    }

    struct pfoModelType {
        QVariantList pfoName;
        QVariantList pfoNum;
        QVariantList pfoDesc;
        QVariantList pfoIsYahoo;
    };

    QMap<QString, int> pHash;

    pfoModelType pfoModel;

    QVariantList posSymbol;
    QVariantList posExg;
    QVariantList posShare;
    QVariantList posCost;
    QVariantList posStop;
    QVariantList posType;

    // Store distinct symbols for pfoMenu population
    QVariantList uniSymbol;
    QVariantList uniExg;
    QVariantList uniShare;
    QVariantList uniCost;
    QVariantList uniComm;
    QVariantList uniNum;

    QVariantList txId;  // private, used to store the index in pos list.

    // cvs list
    QVariantList csvList;

    int actvPos;
    bool sPlus;
    const char * aegis_token;
    int removeRedundantPosFile(const int);
    QString cfgDir;

    // Accumulate portfolio performance
    qint64  pfoGain;
    quint64 pfoCost;
    quint64 pfoValue;

#if defined(Q_OS_SYMBIAN) || defined(Q_OS_BLACKBERRY)
    AES_KEY aeskeyD;
    AES_KEY aeskeyE;
#endif

    // SQL, suggested to not defined in class to avoid QSqlDatabasePrivate::removeDatabase warnings
    //QSqlDatabase db;
};

#endif // FILEHANDLER_H
