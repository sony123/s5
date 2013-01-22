#include "nwHelper.h"

NwHelper::NwHelper() {
	nm = new QNetworkAccessManager(this);
	QObject::connect(nm, SIGNAL(finished(QNetworkReply*)),
	         this, SLOT(finishedSlot(QNetworkReply*)));
}

Q_INVOKABLE void NwHelper::loadJSON2Model() {
	/*
	// create a data model with sorting keys for firstname and lastname
	GroupDataModel *model =
			new GroupDataModel(QStringList() << "firstname" << "lastname");

	// load the JSON data
	JsonDataAccess jda;
	QVariant list = jda.load("contacts.json");

	// add the data to the model
	model->insertList(list.value<QVariantList>());

	// create a ListView control and add the model to the list
	ListView *listView = new ListView();
	listView->setDataModel(model);
	*/
}

Q_INVOKABLE void NwHelper::request(QString link) {
//	QUrl url(link);
//	QUrl url("http://www.google.com/finance/info?client=ig&infotype=infoquoteall&q=INDEXDJX:.DJI,INDEXSP:.INX");
//	QNetworkReply* reply = nm->get(QNetworkRequest(url));
}

void NwHelper::finishedSlot(QNetworkReply* reply) {
    /*
	QVariant statusCodeV =
    reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    // Or the target URL if it was a redirect:
    QVariant redirectionTargetUrl =
    reply->attribute(QNetworkRequest::RedirectionTargetAttribute);
    // see CS001432 on how to handle this

    // no error received?
    if (reply->error() == QNetworkReply::NoError)
    {
        // read data from QNetworkReply here

        // Example 1: Creating QImage from the reply
//        QImageReader imageReader(reply);
//        QImage pic = imageReader.read();

        // Example 2: Reading bytes form the reply
        QByteArray bytes = reply.readAll();  // bytes
//        QString string = QString(bytes);
        QString string = QString::fromUtf8(bytes);
    }
    // Some http error received
    else
    {
        // handle errors here
    }

    // We receive ownership of the reply object
    // and therefore need to handle deletion.
    reply.deleteLater();
    */
}
