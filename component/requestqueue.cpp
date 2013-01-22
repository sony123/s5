/*
*
* requestqueue.cpp
* © Copyrights 2012 inneractive LTD, Nokia. All rights reserved
*
* This file is part of inneractiveAdQML.	
*
* inneractiveAdQML is free software: you can redistribute it and/or modify 
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* inneractiveAdQML is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with inneractiveAdQML. If not, see <http://www.gnu.org/licenses/>.
*/

#include "requestqueue.h"
#include "adinterface.h"
#include <qplatformdefs.h>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QDateTime>
#include <QDebug>
#include <QNetworkConfigurationManager>
#include <QNetworkSession>
#include <QXmlStreamReader>

RequestQueue::RequestQueue(AdInterface *parent) :
    QObject(parent)
  , m_nam(new QNetworkAccessManager(this))
  , m_runningRequest(0)
  , m_confman(new QNetworkConfigurationManager(this))
  , m_nsession(0)
  , m_onlineCheck(false)
  , m_networkError(false)
{
    connect(m_nam, SIGNAL(finished(QNetworkReply*)), this, SLOT(adRequestFinished(QNetworkReply*)));
    m_nsession = new QNetworkSession(m_confman->defaultConfiguration(), this);
    connect(m_nsession, SIGNAL(stateChanged(QNetworkSession::State)),
            this, SLOT(netSessionStateChanged(QNetworkSession::State)));
    connect(m_nsession, SIGNAL(opened()), this, SLOT(netSessionStateChanged()));
}

RequestQueue::~RequestQueue()
{
}

void RequestQueue::netSessionStateChanged(QNetworkSession::State state)
{
    AdInterface *adInterface = qobject_cast<AdInterface*>(parent());
    if (state == QNetworkSession::Connected) {
        emit adInterface->networkAccessibilityChanged(true);
    } else {
        emit adInterface->networkAccessibilityChanged(m_nsession->isOpen());
    }
}

void RequestQueue::cancelRequest(QObject *adItem)
{
    if (m_runningRequest == adItem) {
        m_runningRequest = 0;
        QMetaObject::invokeMethod(this, "handleRequests",Qt::QueuedConnection);
    } else {
        m_adItemQueue.removeAll(adItem);
    }
}

bool RequestQueue::isOnline() const
{
    return m_nsession->isOpen();
}

// Adds AdItem to request queue and calls handleRequests
void RequestQueue::addToQueue(QObject *adItem)
{
    // no need to add same object multipletimes
    if (!m_adItemQueue.contains(adItem)) {
        connect(adItem, SIGNAL(destroyed(QObject*)), this, SLOT(cancelRequest(QObject*)), Qt::UniqueConnection);
        m_adItemQueue.enqueue(adItem);
        QMetaObject::invokeMethod(this, "handleRequests",Qt::QueuedConnection);
    }
}

// Takes AdItem from queue and creates request for ad
void RequestQueue::handleRequests()
{
    // return if request queue is empty or other ad request is running
    if (m_adItemQueue.isEmpty() || m_runningRequest)
        return;
    QObject *adItem = m_adItemQueue.dequeue();
    m_runningRequest = adItem;

    QMetaObject::invokeMethod(adItem, "__createQuery", Qt::DirectConnection);
    QUrl requestUrl = adItem->property("__query").toUrl();
    if (!requestUrl.isValid()) {
        QMetaObject::invokeMethod(adItem, "adError",
                                  Q_ARG(QString, tr("Not valid query url")));
        m_runningRequest = 0;
        return;
    }
#if defined(Q_OS_SYMBIAN) || defined(MEEGO_EDITION_HARMATTAN) || defined(Q_WS_MAEMO_5)
    // online checking only on mobile
    if (!m_nsession->isOpen()) {
        if (!m_onlineCheck) {
            m_onlineCheck = true;
            m_nsession->open();
            if (!m_nsession->waitForOpened()) {
                AdInterface *adI = qobject_cast<AdInterface*>(parent());
                emit adI->networkNotAccessible();
                m_networkError = true;
            }
        } else {
            if (!m_networkError) {
                m_networkError = true;
                AdInterface *adI = qobject_cast<AdInterface*>(parent());
                emit adI->networkNotAccessible();
            }
            QMetaObject::invokeMethod(adItem, "adError",
                                      Q_ARG(QString, tr("Network not accessible")));
            m_runningRequest = 0;
            return;
        }
    }
#endif

    // Add timestamp to request
    requestUrl.addQueryItem(QLatin1String("t"), QString::number(QDateTime::currentDateTime().toTime_t()));
	
	// Add client id parameter if clientid set
    if (!m_clientId.isEmpty())
        requestUrl.addQueryItem(QLatin1String("cid"), m_clientId);
    
    // Set User-Agent header
    QNetworkRequest req(requestUrl);
    req.setRawHeader("User-Agent", m_userAgent);

    qDebug() << "AdRequest:" << req.url();
    qDebug() << "UA:" << m_userAgent;
    QNetworkReply *rep = m_nam->get(req);

    rep->setProperty("AdItem", QVariant::fromValue(adItem));
	
    connect(adItem, SIGNAL(destroyed()), rep, SLOT(deleteLater()));
}

void RequestQueue::adRequestFinished(QNetworkReply *req)
{
    if (!req)
        return;
    QObject *adItem = req->property("AdItem").value<QObject*>();
    if (!adItem) {
        req->deleteLater();
        return;
    }

    QByteArray data = req->readAll();

    m_runningRequest = 0;
    if (req->attribute(QNetworkRequest::HttpStatusCodeAttribute) != 200) {
        QMetaObject::invokeMethod(adItem, "adError",
                                  Q_ARG(QString,req->errorString()));
        // When no connectivity -> UnknownNetworkError
        if (req->error() == QNetworkReply::UnknownNetworkError) {
            AdInterface *adI = qobject_cast<AdInterface*>(parent());
            emit adI->networkNotAccessible();
        }
        req->deleteLater();
        QMetaObject::invokeMethod(this, "handleRequests",Qt::QueuedConnection);
        return;
    }
    req->deleteLater();

    // Parse xml
    data.replace("&auml;", "ä");
    data.replace("&Auml;", "Ä");
    data.replace("&ouml;", "ö");
    data.replace("&Ouml;", "Ö");
    data.replace("&uuml;", "ü");
    data.replace("&Uuml;", "Ü");
    data.replace("&aring;", "å");
    data.replace("&Aring;", "Å");

    QXmlStreamReader reader(data);
    while (!reader.atEnd() && reader.error() == QXmlStreamReader::NoError) {
        if (!reader.readNextStartElement()) {
            if (reader.name() == "Response")
                break; // Response element closed
            else
                continue; // Other element closed
        }
        if (reader.name() == "Text") {
            adItem->setProperty("adTextString", reader.readElementText());
        } else if (reader.name() == "URL") {
            adItem->setProperty("adClickUrl", reader.readElementText());
        } else if (reader.name() == "Image") {
            adItem->setProperty("adImageUrl", reader.readElementText());
        } else if (reader.name() == "Client") {
            m_clientId = reader.attributes().value("Id").toString();
        }
    }

    if (reader.error() != QXmlStreamReader::NoError) {
        QMetaObject::invokeMethod(adItem, "adError",
                                  Q_ARG(QString, QString("XML Error: " + reader.errorString())));
    } else {
        QMetaObject::invokeMethod(adItem, "adLoaded");
    }
    QMetaObject::invokeMethod(this, "handleRequests",Qt::QueuedConnection);
}

