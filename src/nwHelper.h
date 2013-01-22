#ifndef NWHELPER_H
#define NWHELPER_H

#include <bb/cascades/Application>
#include <bb/cascades/DataModel>
#include <bb/data/JsonDataAccess>
#include <QObject>
#include <QNetworkAccessManager>
#include <QUrl>
#include <QNetworkRequest>
#include <QNetworkReply>

using namespace bb::cascades;
using namespace bb::data;

class NwHelper: public QObject
{
	Q_OBJECT

public:
	Q_INVOKABLE void loadJSON2Model();
	Q_INVOKABLE void request(QString);
	NwHelper();
	QNetworkAccessManager* nm;

private:

public slots:
	void finishedSlot(QNetworkReply* reply);
};

#endif
