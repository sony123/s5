/*
 * Referenced from Nokia's Diner app.
 */

#include "loadhelper.h"
// Internal includes
#include "qmlapplicationviewer.h"


/*!
  \class LoadHelper
  \brief LoadHelper is a utility class for loading the main.qml file after splash.
*/

LoadHelper::LoadHelper(QmlApplicationViewer *viewer, QObject *parent)
    : QObject(parent),
      m_viewer(viewer)
{}

void LoadHelper::loadMainQML()
{
    if (m_viewer) {
        m_viewer->setMainQmlFile(QLatin1String("qml/stockona/mainAd.qml"));
    }
}
