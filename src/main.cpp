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

#ifdef DEV
#include "pfoItem.h"
#endif

#if defined(Q_WS_SIMULATOR) || defined(Q_OS_SYMBIAN) || defined(Q_OS_BLACKBERRY)
  #include <QtCore/QTimer>
  #include "loadhelper.h"
#endif

#if defined(Q_OS_BLACKBERRY)
//#define GL
#ifdef GL
#include <QGLWidget>
#include <QGLFormat>
#endif
#endif

#ifdef AD_ENABLE
#include "inneractiveplugin.h"
#endif

Q_DECL_EXPORT int main(int argc, char *argv[])
{
#if defined(Q_OS_BLACKBERRY)
    QApplication::setStartDragDistance(16);
#endif
    QScopedPointer<QApplication> app(createApplication(argc, argv));
    QScopedPointer<QmlApplicationViewer> viewer(QmlApplicationViewer::create());

    // Performance
#if defined(Q_OS_BLACKBERRY)
#ifdef GL
    QGLFormat format = QGLFormat::defaultFormat();
    format.setSampleBuffers(false);
    QGLWidget *glWidget = new QGLWidget(format);
    glWidget->setAutoFillBackground(false);

    viewer->setViewport(glWidget);
#endif
#endif

    viewer->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->viewport()->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->setAttribute(Qt::WA_NoSystemBackground);
    viewer->viewport()->setAttribute(Qt::WA_NoSystemBackground);
    viewer->setViewportUpdateMode(QGraphicsView::FullViewportUpdate);

#if defined(Q_OS_SYMBIAN) || defined(Q_WS_SIMULATOR) || defined (Q_OS_BLACKBERRY)
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

    // Hook up C++ model
#ifdef DEV
    ListModel* pfoModel = new ListModel(new PfoItem);
    pfoModel->appendRow(new PfoItem("A","B","C","D",false,0, "0.0","0.0","10.0") );
    pfoModel->appendRow(new PfoItem("K","K","K","K",false,0, "0.0","0.0","10.0") );
    viewer->rootContext()->setContextProperty("pfoModelC", pfoModel);
#endif

#if defined(Q_WS_HARMATTAN)
    viewer->setMainQmlFile(QLatin1String("/opt/stockona/qml/stockona/mainAd.qml"));
#else
    viewer->setMainQmlFile(QLatin1String("qml/stockona/Splash.qml"));
#endif

#if defined(Q_WS_SIMULATOR) || defined(Q_OS_SYMBIAN) || defined(Q_OS_BLACKBERRY)
    viewer->showExpanded();
#else
    viewer->showFullScreen();
#endif

    return app->exec();
}
