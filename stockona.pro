# Add more folders to ship with the application, here
stockona_core.source = qml/stockona/common/stockona
stockona_core.target = qml
DEPLOYMENTFOLDERS += stockona_core

# inner-active
include(component/component.pri)
folder_components.source = component/inneractive
folder_components.target = qml/stockona
DEPLOYMENTFOLDERS += folder_components

# IAP
#CONFIG += mobility inapppurchase debug
#addIapFiles.sources = ./items2sell/IAP_VARIANTID.txt #./items2sell/TEST_MODE.txt
#addIapFiles.path = ./

#DEPLOYMENT += iap_dependency addIapFiles

# Version
VERSION = 0.6.6
VERSTR = '\\"$${VERSION}\\"'
DEFINES += VER=\"$${VERSTR}\"
#CONFIG += plus

# Linguist
trans_folder.source = i18n
trans_folder.target =
DEPLOYMENTFOLDERS += trans_folder

TRANSLATIONS = stockona_zh_TW.ts
CODECFORTR   = UTF-8
CODECFORSRC  = UTF-8

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
# CONFIG += mobility
# MOBILITY +=
QT += sql

# The .cpp file which was generated for your project. Feel free to hack it.
HEADERS += \
    src/filehandler.h \
    src/loadhelper.h \
#    src/pfoItem.h \
#    src/listModel.h \
    src/params.h \
    src/key.h

SOURCES += src/main.cpp \
    src/filehandler.cpp \
#    src/pfoItem.cpp \
#    src/listModel.cpp \
    src/loadhelper.cpp

OTHER_FILES += \
    stockona_harmattan.desktop \
    qtc_packaging/debian_harmattan/rules \
    qtc_packaging/debian_harmattan/README \
    qtc_packaging/debian_harmattan/copyright \
    qtc_packaging/debian_harmattan/control \
    qtc_packaging/debian_harmattan/compat \
    qtc_packaging/debian_harmattan/changelog \
    qtc_packaging/debian_harmattan/manifest.aegis \
    component/inneractive/adFunctions.js \
    component/inneractive/AdParameters.qml \
    component/inneractive/AdItem.qml \

simulator {
    message(Simulator build)
    platform_qml.source = qml/stockona/harmattan/stockona
#    platform_qml.source = qml/stockona/symbian/stockona
#    platform_qml.source = qml/stockona/bb/stockona
    platform_qml.target = qml
}

symbian {
    message(Symbian build)

    # Platform_specific
    platform_qml.source = qml/stockona/symbian/stockona
    platform_qml.target = qml
    QML_IMPORT_PATH = qml/stockona/symbian/stockona

#    CONFIG(plus) {
#    TARGET = stockona+
#    }
#    else {
#    TARGET = stockona
#    }
    TARGET.EPOCSTACKSIZE = 0x14000
    TARGET.EPOCHEAPSIZE = 0x1000 0x1800000 # 24MB
    TARGET.UID3 = 0x2006235d

    # Allow network access on Symbian
    TARGET.CAPABILITY += NetworkServices

    # Add dependency to symbian components
    QT += declarative
    CONFIG += qt-components
    LIBS += -llibcrypto

    # Smart Installer package's UID
    # This UID is from the protected range and therefore the package will
    # fail to install if self-signed. By default qmake uses the unprotected
    # range value if unprotected UID is defined for the application and
    # 0x2002CCCF value if protected UID is given to the application
    #symbian:DEPLOYMENT.installer_header = 0x2002CCCF

    # Limit to Belle
    supported_platforms = \
        "[0x2003A678],0,0,0,{\"S60ProductID\"}" \  # only Belle
        "[0x20022E6D],0,0,0,{\"S60ProductID\"}"   # Symbian^3
    #    "[0x1028315F],0,0,0,{\"S60ProductID\"}" \ # Symbian^1

    # remove default platforms
    default_deployment.pkg_prerules -= pkg_platform_dependencies
    # add our platforms
    platform_deploy.pkg_prerules += supported_platforms
    DEPLOYMENT += platform_deploy

    # add our platforms
    vendorinfo += "%{\"stockona\"}" ":\"stockona\""

    my_deployment.pkg_prerules += vendorinfo
    DEPLOYMENT += my_deployment

    # Add qtquick dependency
    qtquick_deployment.pkg_prerules += \
            "; Dependency to Symbian Qt Quick components" \
            "(0x200346DE), 1, 1, 0, {\"Qt Quick components\"}"

    DEPLOYMENT += qtquick_deployment

    ICON = stockona.svg
#    DEPLOYMENT.display_name += stockona+
}

# unix
contains(MEEGO_EDITION, harmattan) {
    message(Harmattan build)

    DEFINES += Q_WS_HARMATTAN

    # Platform_specific
    platform_qml.source = qml/stockona/harmattan/stockona
    platform_qml.target = qml
    QML_IMPORT_PATH = qml/stockona/harmattan/stockona

    # Account provider definition and icon
    #CONFIG += link_pkgconfig
    #PKGCONFIG += accounts-qt AccountSetup libsignon-qt #gq-gconf

    #provider.files = stockona.provider
    #provider.path = /usr/share/accounts/providers
    #providericon.files = icon-m-service-stockona.png
    #providericon.path = /usr/share/themes/blanco/meegotouch/icons
    #INSTALLS += provider providericon

    # Splash screen
    splash.files = images/stockona-splash.jpg
    splash.path = /opt/stockona/qml/stockona/gfx
#    splash.path = /usr/share/themes/blanco/meegotouch/images/splash
    INSTALLS += splash

    # Add AEGIS Crypto library
    PKGCONFIG += aegis-crypto
    CONFIG += qdeclarative-boostable \
        link_pkgconfig

    # qdeclarative-boostable workaround
    QMAKE_CXXFLAGS += `pkg-config --cflags qdeclarative-boostable`
    QMAKE_LFLAGS   += `pkg-config --libs qdeclarative-boostable`
    QMAKE_CXXFLAGS += -fPIC -fvisibility=hidden -fvisibility-inlines-hidden
    QMAKE_LFLAGS   += -pie -rdynamic
}

DEPLOYMENTFOLDERS += platform_qml

# Please do not modify the following two lines. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)
qtcAddDeployment()
