#include <QtGui/QApplication>
#include <QTranslator>
#include <QTextCodec>
#include <QLocale>
#include <QDeclarativeContext>
//#include <QGraphicsObject>
//#include <QDeclarativeListReference>
//#include "qdeclarativelist.h"

#include "qmlapplicationviewer.h"
#include "fileHandler.h"

#if defined(Q_WS_SIMULATOR) || defined(Q_OS_SYMBIAN)
  #include <QtCore/QTimer>
  #include "loadhelper.h"
#endif

#ifdef AD_ENABLE
#include "inneractiveplugin.h"
#endif

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));
    QScopedPointer<QmlApplicationViewer> viewer(QmlApplicationViewer::create());

    // Performance
    viewer->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->viewport()->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->setAttribute(Qt::WA_NoSystemBackground);
    viewer->viewport()->setAttribute(Qt::WA_NoSystemBackground);
    viewer->setViewportUpdateMode(QGraphicsView::FullViewportUpdate);

#if defined(Q_OS_SYMBIAN) || defined(Q_WS_SIMULATOR)
    // First set a QML file that's quick to load and show it as a splash screen.
    //    viewer.setMainQmlFile(QLatin1String("qml/RestaurantAppComponents/SplashScreen.qml"));
    //    // Then trigger loading the *real* main.qml file, which can take longer to load.
    LoadHelper loadHelper(viewer.data());
    QTimer::singleShot(1, &loadHelper, SLOT(loadMainQML()));
#endif

    // Hook up inner-active
#ifdef AD_ENABLE
    inneractivePlugin::initializeEngine(viewer->engine());
#endif
    // Translation
    QTranslator trans;
    QString locale = QLocale::system().name();
    //qDebug() << locale;

    QString qm_path = app.data()->applicationDirPath();

#ifdef Q_WS_HARMATTAN
    qm_path.append("/../i18n");
#endif

    trans.load(QString("stockona_") + locale, qm_path);
    app.data()->installTranslator(&trans);
    QTextCodec::setCodecForTr(QTextCodec::codecForName("utf8"));

    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationAuto);

    // signal - slot pairing
    //QObject::connect(viewer->rootObject(), SIGNAL(signalTest(int)),
    //                 fileHandler, SLOT(slotTest(int)));

    // Hook up fileHandler
    FileHandler *fileHandler = new FileHandler();
    viewer->rootContext()->setContextProperty("fileHandler", fileHandler);

#ifdef Q_WS_HARMATTAN
    viewer->setMainQmlFile(QLatin1String("/opt/stockona/qml/stockona/mainAd.qml"));

    // Register QML elements
//    QObject* pfoModel = viewer->rootObject()->findChild<QObject*>("pfoModel");
#else
    viewer->setMainQmlFile(QLatin1String("qml/stockona/Splash.qml"));
#endif

#if defined(Q_WS_SIMULATOR) || defined(Q_OS_SYMBIAN)
    viewer->showExpanded();
#else
    viewer->showFullScreen();
#endif

    return app->exec();
}
