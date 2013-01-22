/*
    Stockona is free software/Stockona+ is paid software: you can redistribute
    it and/or modify it under the terms of the GNU Lesser General Public License
    as published by the Free Software Foundation, either version 3 of the License,
    or(at your option) any later version.

    Stockona(+) is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with Stockona. If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 1.1
import com.nokia.meego 1.0
//import QtMobility.systeminfo 1.2

import "js/script.js" as Script
import "js/storage.js" as Storage

PageStackWindow {
    id: appWindow

    showStatusBar: false
    // Workaround for pfo's editsheet toolbar issue.
    showToolBar: true &&
                 (editSheet.status==DialogStatus.Closed||editSheet.status==DialogStatus.Closing) &&
                 (posFinderSheet.status==DialogStatus.Closed||posFinderSheet.status==DialogStatus.Closing) &&
                 (txSheet.status==DialogStatus.Closed||txSheet.status==DialogStatus.Closing)
    initialPage: posView

    //////////////////////////
    // Common Properties
    //////////////////////////
    property alias username:           settingMenu.username
    property alias password:           settingMenu.password
    property alias timer:              settingMenu.timer
    property alias timerIdx:           settingMenu.timerIdx
    property alias overviewNewsIdx:    settingMenu.overviewNewsIdx
    property alias overviewNewsRegion: settingMenu.overviewNewsRegion

    property alias pfoSelectedIdx:     settingMenu.pfoSelectedIdx
    property alias pfoIsLocal:         settingMenu.pfoIsLocal
    property alias pfoIsYahoo:         settingMenu.pfoIsYahoo
    property alias gPfoLength:         settingMenu.gPfoLength

    property alias useWidgetView:      settingMenu.useWidgetView
    property alias usePortfolioView:   settingMenu.usePortfolioView
    property alias useAsianGainColor:  settingMenu.useAsianGainColor
    property alias useDarkTheme:       settingMenu.useDarkTheme
    property bool  useLocalMode:       settingMenu.useLocalMode
    property alias useEditGuide:       settingMenu.useEditGuide
    property alias useMktViewDefault:  settingMenu.useMktViewDefault

    property alias showBusyIndicator:   settingMenu.showBusyIndicator
    property alias startIndicator:      settingMenu.startIndicator
    property alias localModeTrue2False: settingMenu.localModeTrue2False
    property alias localModeFalse2True: settingMenu.localModeFalse2True

    property alias plus:                settingMenu.plus
    //property alias qmlDbg:            settingMenu.qmlDbg

    property alias dbgStr:              settingMenu.dbgStr
    property alias signature:           settingMenu.signature
    property alias activePos:           settingMenu.activePos
    property alias pfoName:             settingMenu.pfoName
    property alias posName:             settingMenu.posName
    property alias posExg:              settingMenu.posExg

//    Text {
//        id: dbgTxt
//        visible: qmlDbg
//        x:2; y:2
//        text: dbgStr
//        font.pixelSize: 25
//        color: "red"
//    }

    // Theme Parameters
    Params {
        id: params
        useDarkTheme: appWindow.useDarkTheme
    }

    Menu {
        id: menu
        visualParent: pageStack
        MenuLayout {
            MenuItem {
                text: qsTr("About");
                onClicked: {
                    aboutDialog.open();
                    appWindow.state = "inAboutDialog"
                }
            }
            MenuItem {
                text: qsTr("Market Overview");
                onClicked: {
                    //mktView.item.state = (appWindow.useMktViewDefault) ? "" : "newsList";
                    fsmTimer2.restart();
                    appWindow.state = "inMktOverview"
                }
            }
            MenuItem {
                text: qsTr("Select Portfolio");
                onClicked: {
                    //console.log("LocalMode=" + appWindow.useLocalMode);
                    if (useLocalMode){
                        // Promote user to create a portfolio when there is no local pfo.
                        if (pfoModel.count==0)
                            appWindow.state = "inPfoViewErrorLocal";
                        else
                            appWindow.state = "inPfoView";
                    }
                    else {
                        appWindow.state = "inPfoView";
                    }
                }
            }
            MenuItem {
                text: qsTr("Settings");
                onClicked: {
                    if (!plus) { activateAd(); }

                    // Reload setting
                    settingMenu.shadow_username = settingMenu.username;
                    settingMenu.shadow_password = settingMenu.password;

                    pageStack.push(settingMenu);
                }
            }
            MenuItem {
                text: qsTr("Help");
                onClicked: {
                    pageStack.push(helpPage);
                }
            }
        }
    }

    //////////////////////////
    //  functions
    //////////////////////////

    // garbage cleaning
    function garbageCollect() {
        if (pfoStoreModel.count > 0) {
            pfoStoreModel.clear();
            console.log("### gc:pfoStoreModel ###");
        }

        if (searchModel.count > 0) {
            searchModel.clear();
            console.log("### gc:searchModel ###");
        }

        if (txModel.count > 0) {
            txModel.clear();
            console.log("### gc:txModel ###");
        }

        if (rtModel.count > 0) {
            rtModel.clear();
            console.log("### gc:rtModel ###");
        }

        if (overviewModel.count > 0) {
            overviewModel.clear();
            console.log("### gc:overviewModel ###");
        }
    }

    function garbageCollectCModel() {
        fileHandler.clearPosCmodel();
        fileHandler.clearPfoCmodel();
        fileHandler.clearTxCmodel();
        fileHandler.clearHashCmodel();
        // Don't call clearUniCmodel() but uniShare & uniCost are needed by Script.parseJSONAll()
        //fileHandler.clearUniCmodel();
    }

    function returnToMainView(model, state) {
        if (model.count > 0)
            model.clear();
        pageStack.pop();
        waitState.state = "hidden";
        appWindow.state = state;
    }

    function reseteditSheet() {
        editSheet.myPfoName = editSheet.myPfoDesc = editSheet.mySym = editSheet.myExg = "";
        editSheet.myShare = editSheet.myCost = editSheet.myStop = 0;
        editSheet.myType = "Buy";
        editSheet.pfoMode = editSheet.posFindMode = editSheet.googleMode = false;
    }

    // idx is local pfo index, so pfoModel uses pfoSelectedIdx.
    function addPfo(idx, update) {
        if (update) {
            pfoModel.set(pfoSelectedIdx, {
                         "local": 1,
                         "name": checkForDelimiter(editSheet.myPfoName),
                         "feedLink": "",
                         "excerpt": checkForDelimiter(editSheet.myPfoDesc),
                         "isYahoo": editSheet.myIsYahoo
            });

            fileHandler.setPfoCmodel(idx,
                                     checkForDelimiter(editSheet.myPfoName),
                                     checkForDelimiter(editSheet.myPfoDesc),
                                     editSheet.myIsYahoo
            );

            storePfo();
        }
        else {
            pfoModel.append({
                         "local": 1,
                         "name": checkForDelimiter(editSheet.myPfoName),
                         "feedLink": "",
                         "excerpt": checkForDelimiter(editSheet.myPfoDesc),
                         "isYahoo": editSheet.myIsYahoo,
                         "num": 0,
                         "cost": "",
                         "gain": "",
                         "value": ""
            });

            fileHandler.addPfo(
                        checkForDelimiter(editSheet.myPfoName),
                        checkForDelimiter(editSheet.myPfoDesc),
                        editSheet.myIsYahoo);
        }
    }

    function checkForComma(x) {
        return x.replace(/,/, ".");
    }

    function addPos(idx, update, sym, exg) {
        if (update) {
            // This is no longer a valid condition
//            fileHandler.setHashCmodel(
//                        idx,
//                        checkForDelimiter(sym).toUpperCase(),
//                        checkForDelimiter(exg).toUpperCase(),
//                        editSheet.myShare,
//                        editSheet.myCost,
//                        editSheet.myStop,
//                        editSheet.myType
//                        )

//            storePos(appWindow.activePos);
        }
        else {
            // addPosEditModel(name, exg, share, cost, comm, num, type, dirty) {
            Script.addPosEditModel(posModel,
                            checkForDelimiter(sym).toUpperCase(),
                            checkForDelimiter(exg).toUpperCase(),
                            jRound(checkForComma(editSheet.myShare)),
                            jRound(checkForComma(editSheet.myCost)),
                            jRound(checkForComma(editSheet.myStop)),
                            0,
                            editSheet.myType,
                            1
            );
            /*
            posModel.append({
                         "name":      checkForDelimiter(sym).toUpperCase(),
                         "exchange":  checkForDelimiter(exg).toUpperCase(),
                         "share":     checkForComma(editSheet.myShare),
                         "shareCost": checkForComma(editSheet.myCost),
                         "shareDayGain": checkForComma(editSheet.myStop), // Overloaded to store shareComm.
                         "shareGain": 0,                       // Overloaded to store shareNum.
                         "shareGainPercent": editSheet.myType, // Overloaded to store shareType.
                         "fullname": 1                         // Overloaded to store dirty flag.
            });
            */

            fileHandler.storePos(
                        appWindow.activePos,
                        checkForDelimiter(sym).toUpperCase(),
                        checkForDelimiter(exg).toUpperCase(),
                        checkForComma(editSheet.myShare),
                        checkForComma(editSheet.myCost),
                        checkForComma(editSheet.myStop),
                        editSheet.myType);
        }
    }

    // Store data into local portfolio marked by posIdx.
    function storeEditPos(posIdx) {
        fileHandler.removePosAll(posIdx);

        for (var i=0; i<posModel.count; i++) {
            console.log("storeEditPos: i=" + i + ", name=" + posModel.get(i).name +
                        ", cost=" + posModel.get(i).shareCost +
                        ", comm=" + posModel.get(i).shareDayGain);

            // Local portfolio's cost is 'cost per share'
            var cost;

            if (pfoIsLocal) {
                cost = posModel.get(i).shareCost;
            }
            else {
                cost = ((posModel.get(i).shareCost=="-") || (posModel.get(i).share==0)) ? 0 :
                        (posModel.get(i).shareCost/posModel.get(i).share);
            }

            // shareDayGain=comm, shareGainPercent=type
            fileHandler.setPosCmodel(i, posModel.get(i).name, posModel.get(i).exchange,
                                     posModel.get(i).share,
                                     cost,
                                     posModel.get(i).shareDayGain,
                                     posModel.get(i).shareGainPercent);
        }

        fileHandler.storePosAll(posIdx);
    }

    function storePos(posIdx) {
        fileHandler.removePosAll(posIdx);
        fileHandler.storePosAll(posIdx);
    }

    // C-model pfoNum is saved in storePos functions
    function updateLocalPfoNum(mode, idx) {
        var localIdx = idx - appWindow.gPfoLength;
        //console.log("udpateLocalPfoNum: pfoIdx=" + idx + " num=" + fileHandler.localPfoNum[localIdx]);

        // Validate idx
        if ( mode!=0 || (localIdx >= 0) ) {
            fileHandler.loadPosNum(localIdx);
            pfoModel.set(idx, {"num": fileHandler.localPfoNum[localIdx]});
        }
    }

    function loadMktOverview() {
        var quoteList;
        var mktSelList = settingMenu.mktSelDialog.selectedIndexes;
        for (var i=0; i<mktSelList.length; i++) {
            var idx = mktSelList[i];
            quoteList += settingMenu.mktSelDialog.model.get(idx).symbol;
            // Google ignores the ending comma
            quoteList += ",";
            //console.log("###" + settingMenu.mktSelDialog.model.get(idx).symbol);
        }

        // Currency
        // Bond

        appWindow.__loadAllQuotesIntoModel(quoteList, mktSelList.length, overviewModel);
    }

    function __loadAllQuotesIntoModel(quoteList, quoteLength, model) {
        Script.loadAllQuotesIntoModel(quoteList, quoteLength, model);
    }

    function __convertExchangeForYahoo (name, exg) {
        return Script.convertExchangeForYahoo(name, exg);
    }

    function storeParams(key, data) {
        //console.log("timer=" + appWindow.timerIdx + ", widget=" + appWindow.useWidgetView + ", pfo=" +appWindow.usePortfolioView);
        //console.log("darkTheme=" + appWindow.useDarkTheme + ", gainColorMode=" + appWindow.useAsianGainColor);
        if (key!="password")
            console.log("storeParams:" + key + "=" + data);

        if (key=="username" && data!=appWindow.username) {
            Storage.setKeyValue(key, appWindow.username);
        }
        else if (key=="password") {
            var enc_pwd;
            if (data!="") { enc_pwd = fileHandler.encryptData(appWindow.password); }
            //console.log("QML clear=" + appWindow.password + " encrypt=" + enc_pwd);
            Storage.setKeyValue(key, enc_pwd);
        }
        else if (key=="timer" && (data != appWindow.timerIdx)) {
            appWindow.timerIdx = (appWindow.timerIdx > 5) ? 1 : appWindow.timerIdx;
            Storage.setKeyValue(key, appWindow.timerIdx);
        }
        else if (key=="pfoStats") {
            localModeTrue2False = localModeFalse2True = false;

            // Trigger pfoView if useLocalMode change from true to false
            if (data>15 && appWindow.useLocalMode==false) {
                localModeTrue2False = true;
                localModeFalse2True = false;
            }
            else if (data<16 && appWindow.useLocalMode==true) {
                localModeTrue2False = false;
                localModeFalse2True = true;
            }

            var tmp = (appWindow.useLocalMode<<4)^(appWindow.useDarkTheme<<3)^(appWindow.useAsianGainColor<<2)^(appWindow.useWidgetView<<1)^(appWindow.usePortfolioView);
            Storage.setKeyValue(key, tmp);
        }
        else if (key=="activePos" && (data != appWindow.activePos)) {
            Storage.setKeyValue(key, appWindow.activePos);
        }
        else if (key=="pfoActiveIdx" && (data != appWindow.pfoSelectedIdx)) {
            Storage.setKeyValue(key, appWindow.pfoSelectedIdx);
        }
        else if (key=="mktOverviewIdx" && (data != appWindow.overviewNewsIdx)) {
            Storage.setKeyValue(key, appWindow.overviewNewsIdx);
        }
        else if (key=="mktOverviewList") {
            var tmp = 0;
            // 0 at LSB
            for (var i=0; i<settingMenu.mktSelDialog.selectedIndexes.length; i++) {
                tmp = tmp | (1<<settingMenu.mktSelDialog.selectedIndexes[i]);
            }

            Storage.setKeyValue(key, tmp);
        }
        else if (key=="pfoIsLocal") {
            var tmp = (appWindow.pfoIsLocal<<1)^(appWindow.pfoIsYahoo);
            Storage.setKeyValue(key, tmp);
        }
        else if (key=="useEditGuide" && (data != (appWindow.useMktViewDefault<<1)^appWindow.useEditGuide)) {
            var tmp = (appWindow.useMktViewDefault<<1)^(appWindow.useEditGuide);
            Storage.setKeyValue(key, tmp);
        }
        else if (key=="useSearchShortcut" && data != settingMenu.useSearchShortcut) {
            Storage.setKeyValue(key, settingMenu.useSearchShortcut);
        }
    }

    function timerValueLUT(idx) {
        if (idx==0)        { return 15;   }
        else if (idx==1)   { return 30;   }
        else if (idx==2)   { return 60;   }
        else if (idx==3)   { return 300;  }
        else if (idx==4)   { return 900;  }
        else if (idx==5)   { return 1800; }
    }

    function timerTextLUT(idx) {
        if (idx==0)        { return "15 seconds"; }
        else if (idx==1)   { return "30 seconds"; }
        else if (idx==2)   { return "1 minute";   }
        else if (idx==3)   { return "5 minutes";  }
        else if (idx==4)   { return "15 minutes"; }
        else if (idx==5)   { return "30 minutes"; }
    }

    function mktOverviewValueLUT(idx) {
        /*
                ListElement { name: "US";        }
                ListElement { name: "Canada";    }
                ListElement { name: "Mexico";    }
                ListElement { name: "Brazil";    }
                ListElement { name: "UK";        }
                ListElement { name: "France";    }
                ListElement { name: "Germany";   }
                ListElement { name: "Russian";   }
                ListElement { name: "Singapore"; }
                ListElement { name: "Malaysia";  }
                ListElement { name: "Taiwan"; }
                ListElement { name: "HK"; }
                ListElement { name: "China"; }
                ListElement { name: "India; }
        */
        //console.log("mktOverviewIdx=" + idx);
        switch (idx) {
            case 0:
                return "us"; break;
            case 1:
                return "ca"; break;
            case 2:
                return "es_mx"; break;
            case 3:
                return "pt-BR_br"; break;
            case 4:
                return "uk"; break;
            case 5:
                return "fr"; break;
            case 6:
                return "de"; break;
            case 7:
                return "es"; break;
            case 8:
                return "ru_ru"; break;
            case 9:
                return "en_za"; break;
            case 10:
                return "en_sg"; break;
            case 11:
                return "en_my"; break;
            case 12:
                return "tw"; break;
            case 13:
                return "hk"; break;
            case 14:
                return "cn"; break;
            case 15:
                return "in"; break;
            default:
                return "us";
        }
    }

    // Restore settings
    function setParams (key, data) {
        console.log("setParams:" + key + "=" + data);

        if (key=="username") {
            username = data;
        }
        else if(key=="timer") {
            if (data != "")   {
                appWindow.timerIdx = data;
                appWindow.timer    = timerValueLUT(data);
            }
        }
        else if (key=="pfoStats") {
            if (data != "")   {
                appWindow.useLocalMode      = data&16;
                appWindow.useDarkTheme      = (plus) ? data&8 : false;
                appWindow.useAsianGainColor = data&4;
                appWindow.useWidgetView     = data&2;
                appWindow.usePortfolioView  = data&1;
            }
        }
        else if (key=="activePos") {
            if (data != "") { appWindow.activePos = data; }
        }
        else if (key=="pfoActiveIdx") {
            if (data != "") { appWindow.pfoSelectedIdx = data; }
        }
        else if (key=="pfoIsLocal") {
            if (data != "") {
                appWindow.pfoIsLocal = data&2;
                appWindow.pfoIsYahoo = data&1;
            }
        }
        else if (key=="mktOverviewIdx") {
            if (data != "") { appWindow.overviewNewsIdx = data; }
        }
        // 0 at LSB
        else if (key=="mktOverviewList") {
            if (data != "") {
                var tmp = new Array;
                for (var i = 0; i<14; i++) {
                    if ((data >> i) & 1 ) {
                        tmp.push(i);
                    }
                }
                settingMenu.mktSelDialog.selectedIndexes = tmp;
            }
            else            { settingMenu.mktSelDialog.selectedIndexes = [0,1,2,3,4,5,6,7,8,9,10,11,12,13]; }
            //console.log("selLength="+settingMenu.mktSelDialog.selectedIndexes.length);
        }
        else if (key=="useEditGuide") {
            if (data != "") {
                appWindow.useMktViewDefault = data&2;
                appWindow.useEditGuide = data&1;
            }
        }
        else if (key=="useSearchShortcut") {
            if (data != "")
                settingMenu.useSearchShortcut = data;
        }
    }

    function setLoginCredentials(key, data) {
        if(key=="username") {
            appWindow.username = data;
        } else {
            // aegis_encrypt
            var dec_pwd = fileHandler.decryptData(data);
            //console.log("QML decrypt=" + dec_pwd);
            appWindow.password = dec_pwd;
        }

        // Auto login when not in local mode.
        if (useLocalMode) {
            localModeInit();
        }
        else if(appWindow.username.length>0 && appWindow.password.length>0) {
            doLogin();
        } else {
            startIndicator++;
            if(startIndicator==2) {
                console.log("Try to show login dialog");
                pageStack.push(settingMenu);
                appWindow.state = "inSettingView";
            }
        }
    }

    function jRound(val) {
        return Math.round(val*100)/100;
    }

    function loadLocalTx(idx, sym, exg) {
        txModel.clear();
        fileHandler.loadTx(idx, sym, exg);

        var txLength = fileHandler.localTxId.length;
        //console.log("DBG: localTxLength="+txLength+" (sym,exg)="+sym+","+exg);
        for (var i=0; i < txLength; i++)
        {
            var k = fileHandler.localTxId[i];
//            console.log("loadLocalTx: k=" + k + " type=" + fileHandler.localPosType[k] +
//                    " share=" + fileHandler.localPosShare[k] +
//                    " price=" + jRound(fileHandler.localPosCost[k]) +
//                    " comm="  + jRound(fileHandler.localPosStop[k]));
            if (i<txModel.count) {
                txModel.set(i, {
                    "id": k,
                    "type":  fileHandler.localPosType[k],
                    "share": jRound(fileHandler.localPosShare[k]),
                    "price": jRound(fileHandler.localPosCost[k]),
                    "comm":  jRound(fileHandler.localPosStop[k])
                });
            }
            else {
                txModel.append({
                    "id": k,
                    "type": fileHandler.localPosType[k],
                    "share": jRound(fileHandler.localPosShare[k]),
                    "price": jRound(fileHandler.localPosCost[k]),
                    "comm":  jRound(fileHandler.localPosStop[k])
                });
            }
        }
    }

    function __createTx(txLink, txId, type, share, price, comm) {
        Script.createGoogleTx(txLink, txId, type, share, price, comm);
    }

    function __loadTx(txLink) {
        Script.loadTx(txLink, txModel);
    }

    function __loadGoogleRelated(sym, exg) {
        Script.loadGoogleRelated(sym, exg, rtModel);
    }

    function __loadGoogleExtra(model) {
        Script.loadGoogleExtra(model);
    }

    function __loadPortfolio() {
        if (useLocalMode)
            Script.loadLocalPortfolio(0);
        else
            Script.loadAllPortfolios();
    }

    function __loadPosition() {
        if (waitState.state=="hidden") {
            // Update fileHandler.localPos index
            if (pfoIsLocal && !useLocalMode && (gPfoLength==0)) {
                var gLen = calcGPfoLength();
                if (fileHandler.localPos < gLen)
                    fileHandler.localPos += gLen;
            }

            // Lite version: only update quotes without checking google portfolio
            Script.updateTimerQuotes(pfoIsYahoo, pfoIsLocal);
        }
    }

    function __loadPositionSymbol(feedlink) {
        posModel.clear();
        Script.loadPositionSymbol(feedlink, posModel);
    }

    function __loadGoogleFinanceSearch(query) {
        Script.loadGoogleFinanceSearch(query, searchModel);
    }

    function loadPosViewSettings() {
        posView.usePortfolioView = usePortfolioView;
        posView.useWidgetView = useWidgetView;
        if (!plus) posView.activateBannerAd();
    }

    function storeSettings() {
        Script.setGainColor(appWindow.useAsianGainColor);
        loadPosViewSettings();

        Storage.getKeyValue("timer",        storeParams);
        Storage.getKeyValue("pfoStats",     storeParams);
        Storage.getKeyValue("useEditGuide", storeParams);
        Storage.getKeyValue("mktOverviewList",  storeParams);
        Storage.getKeyValue("useSearchShortcut",  storeParams);
    }

    function storeAccount() {
        Storage.getKeyValue("username", storeParams);
        Storage.getKeyValue("password", storeParams);
        Storage.getKeyValue("activePos", storeParams);
    }

    function doLogin() {
        //if (waitState.state=="hidden") {
            console.log("doLogin");
            Script.login(appWindow.username, appWindow.password);
            appWindow.state = "inLogin";
        //}
    }

    function checkForDelimiter(str) {
        return str.replace(/:/, ",");
    }

    function loadLocalPfoToPosEditModel(idx) {
        posModel.clear();

        var fileOk = fileHandler.loadPos(idx);

        if (fileOk==0){
            for (var i=0; i < fileHandler.localUniSymbol.length; i++) {
//                console.log("LoadPos: " + i + ", " + fileHandler.localUniSymbol[i] + ":" + fileHandler.localUniExg[i] +
//                            "(share,cost,comm)=(" +
//                            fileHandler.localUniShare[i] + "," +
//                            fileHandler.localUniCost[i] + "," +
//                            fileHandler.localUniComm[i] + "," +
//                            fileHandler.localUniNum[i] + ")");
                Script.addPosEditModel(posModel,
                                fileHandler.localUniSymbol[i],
                                fileHandler.localUniExg[i],
                                jRound(fileHandler.localUniShare[i]),
                                jRound(fileHandler.localUniCost[i]),
                                fileHandler.localUniComm[i],
                                fileHandler.localUniNum[i],
                                "",
                                0
                );

                /*
                posModel.append({
                      "name": fileHandler.localUniSymbol[i],
                      "exchange": fileHandler.localUniExg[i],
                      "share":     jRound(fileHandler.localUniShare[i]),
                      "shareCost": jRound(fileHandler.localUniCost[i]),
                      "shareDayGain": fileHandler.localUniComm[i],
                      "shareGain": fileHandler.localUniNum[i],  // Overloaded to store shareNum.
                      "shareGainPercent": "",                   // Overloaded to store shareType.
                      "fullname": 0,                            // Overloaded to store dirty flag.
                      "shareValue":   "",           "quotePrice":     "",
                      "quoteChgColor":  "black",
                      "quoteChg":       "",         "quoteChgPtg":    "",
                      "quoteVol":       "",         "quoteAvgVol":    "",
                      "quoteMktCap":    "",

                      "quoteDayHi":     "",         "quoteDayLo":     "",
                      "quote52wHi":     "",
                      "quote52wLo":     "",

                      "quoteEps":       "",
                      "quoteBeta":      "",
                      "quotePe":        "",
                      "quoteType":      "",
                      "quoteAsk":       "",
                      "quoteBid":       "",
                      "quoteDiv":       "",
                      "quoteYld":       "",
                      "afterPrice":     "",
                      "afterChg":       "",
                      "afterChgPtg":    "",
                      "afterChgColor":  "black"
                });
                */
            }
        }
        else {
            console.log("Cannot load local position");
        }
    }

    function localModeInit() {
        console.log("localModeInit()");

        pfoModel.clear();
        Script.loadLocalPortfolio(0);

        // Promote user to create a portfolio when there is no local pfo.
        if (pfoModel.count==0) {
            appWindow.state = "inPfoViewErrorLocal";
        }
        else {
            if (activePos.match(/http/) || (activePos > pfoModel.count - 1))
                activePos = 0;

            pfoIsLocal = true;
            pfoIsYahoo = pfoModel.get(activePos).isYahoo;

            Script.loadOnePortfolio(activePos, pfoIsLocal, pfoIsYahoo);
            appWindow.state = "inMainView";
        }
    }

    function __createGooglePfo(name, currency, idx) {
        return Script.createGooglePfo(name, currency, idx);
    }

    function __createGooglePos(pfoIdx) {
        Script.createGooglePos(posModel, activePos, pfoIdx);
    }

    function fetchPosData(idx) {
//        console.log("fetchPosData");
        if (posModel.count != 0 && idx < posModel.count) {
            posView.myName             = posModel.get(idx).name;
            posView.myExg              = posModel.get(idx).exchange;
            posView.myFullname         = posModel.get(idx).fullName;
            posView.myQuotePrice       = posModel.get(idx).quotePrice      ;
            posView.myQuoteChgColor    = posModel.get(idx).quoteChgColor   ;
            posView.myQuoteChg         = posModel.get(idx).quoteChg        ;
            posView.myQuoteChgPtg      = posModel.get(idx).quoteChgPtg     ;
            posView.myQuoteAsk         = posModel.get(idx).quoteAsk        ;
            posView.myQuoteBid         = posModel.get(idx).quoteBid        ;
            posView.myShare            = posModel.get(idx).share           ;
            posView.myShareValue       = posModel.get(idx).shareValue      ;
            posView.myShareCost        = posModel.get(idx).shareCost       ;
            posView.myShareDayGain     = posModel.get(idx).shareDayGain    ;
            posView.myShareGain        = posModel.get(idx).shareGain       ;
            posView.myShareGainPercent = posModel.get(idx).shareGainPercent;
            posView.myQuoteDayHi       = posModel.get(idx).quoteDayHi ;
            posView.myQuoteDayLo       = posModel.get(idx).quoteDayLo ;
            posView.myQuote52wHi       = posModel.get(idx).quote52wHi ;
            posView.myQuote52wLo       = posModel.get(idx).quote52wLo ;
            posView.myQuoteMktCap      = posModel.get(idx).quoteMktCap;
            posView.myQuoteEps         = posModel.get(idx).quoteEps   ;
            posView.myQuotePe          = posModel.get(idx).quotePe    ;
            posView.myQuoteBeta        = posModel.get(idx).quoteBeta  ;
            posView.myQuoteVol         = posModel.get(idx).quoteVol   ;
            posView.myQuoteAvgVol      = posModel.get(idx).quoteAvgVol;
            posView.myQuoteDiv         = posModel.get(idx).quoteDiv   ;
            posView.myQuoteYld         = posModel.get(idx).quoteYld   ;
            posView.myAfterPrice       = posModel.get(idx).afterPrice ;
            posView.myAfterChg         = posModel.get(idx).afterChg   ;
            posView.myAfterChgPtg      = posModel.get(idx).afterChgPtg;
            posView.myAfterChgColor    = posModel.get(idx).afterChgColor;
        }
    }

    function removeLinks(data) {
        var txt = data;
        txt = txt.replace(/<a /g, "<span ");
        txt = txt.replace(/<\/a>/g, "</span>");
        return txt;
    }

    function removeHeaderLink(data) {
        var txt = data;
        txt = txt.replace(/<a /, "<span ");
        txt = txt.replace(/<\/a>/, "</span>");
        return txt;
    }

    function updateOverview() {
        appWindow.loadMktOverview();
        rssModel.reload();
    }

    function updateTimerActive () {
        return ( (posView.status==PageStatus.Active && posFinderSheet.visible==false) || (mktView.stauts==Loader.Ready)) && Qt.application.active
    }

    function calcGPfoLength() {
        var cnt = 0;

        for (var i=0; i<pfoModel.count; i++) {
            if (pfoModel.get(i).local==0) { cnt++; }
        }

        return cnt;
    }

    function loadPfoStoreModel() {
        pfoStoreModel.clear();

        for (var i=0; i<pfoModel.count; i++) {
            // Only show local Google portfolio
            if (pfoModel.get(i).local && (pfoModel.get(i).isYahoo == false)) {
                //console.log("idx=" + i + " name=" + pfoModel.get(i).name);
                pfoStoreModel.append({
                    "name": pfoModel.get(i).name,
                    "idx": i
                });
            }
        }
    }

    function storePfo() {
        fileHandler.removePfoAll();
        fileHandler.storePfoAll();
    }

    function updateTimerActiveAd () {
        return Qt.application.active;
    }

    function activateAd() {
        if (adLoader.status==Loader.Null) {
            adLoader.sourceComponent = adPageComponent;
        }
        adLoader.item.requestAd();
        adLoader.item.show();
    }

    function signModifier(value) {
        if (value.indexOf("-") == 0)
            return value;
        else
            return ("+" + value);
    }

    // #009900 is n9Green in script.js
    function colorModifier(value) {
        var redColor = "#FA3A3A"; //"#CC0000"

        if (value.indexOf("-")==0)
            return (useAsianGainColor) ? "#009900" : redColor;
        else
            return (useAsianGainColor) ? redColor : "#009900";
    }

    function activatePosFinder() {
        appWindow.loadPfoStoreModel();

        // Reset specified portfolio every time for now
        posFinderSheet.psIdx = 0;

        posFinderSheet.myName = "";
        posFinderSheet.mySym  = "";
        posFinderSheet.myExg  = "";
        posFinderSheet.symInput = "";
        posFinderSheet.myPfoName = "";
        posFinderSheet.pfoStoreIdx = 0;
        posFinderSheet.noSearchMode = false;

        if (pfoStoreModel.count>0) {
            posFinderSheet.pfoStoreIdx = pfoStoreModel.get(0).idx;
            posFinderSheet.myPfoName   = pfoStoreModel.get(0).name;
        }

        posFinderSheet.open();
    }

    function parseDesc(data) {
//        console.log(data);

        // Extract only the content without including the links to related news.
        var startIdx = data.indexOf("<div class=\"lh\">");
        var endIdx   = data.indexOf("...</b></font>", startIdx);
        endIdx       = data.indexOf("t>", endIdx);

        // Search for hyperlink after </b>
        var endIdx2   = data.indexOf("</b>", startIdx);
        endIdx2   = data.indexOf("<a href", endIdx2);

        // Allow only one hyperlink after first <div
        var endIdx3   = data.indexOf("<a href", startIdx);
        endIdx3       = data.indexOf("<a href", endIdx3+5);

        console.log("idx=" + startIdx + " " + endIdx + " " + endIdx2 + " " + endIdx3);

        // Use endIdx2 if endIdx < endIdx
        if (startIdx > endIdx) {
            if (endIdx2 > endIdx) {
                endIdx = endIdx2 - 2;
            }
        }
        else {
            if (startIdx==-1 && (endIdx3>=endIdx2) && endIdx3!=-1) {
                startIdx = 0;
                endIdx = endIdx3 - 2;
            }
        }

        //console.log("idx=" + startIdx + " " + endIdx + " " + endIdx2 + " " + endIdx3);

        // Error handling
        if ((startIdx >= endIdx) || (startIdx == -1) || (endIdx == -1)) {
            return data;
        }
        else {
            // Compensate "t>"
            endIdx += 2;
            var desc     = data.substr(startIdx, endIdx-startIdx);
            desc += "</div>";

            desc         = removeHeaderLink(desc);
            desc         = removeFontFormat(desc);

//            console.log(desc);

            return desc;
        }
    }

    function removeFontFormat(data) {
        var txt = data;
        txt = txt.replace(/<font size/g, "<span ");
        txt = txt.replace(/<\/font>/, "</span>");
        return txt;
    }

    ////////////////////////////////
    // Instantiation
    ////////////////////////////////

    XmlListModel {
        id: rssModel

        query: "/rss/channel/item"

        XmlRole { name: "title"; query: "title/string()" }
        XmlRole { name: "link"; query: "link/string()" }
        XmlRole { name: "desc"; query: "description/string()" }
        XmlRole { name: "date"; query: "pubDate/string()"; }//isKey: true }

        onStatusChanged: {
            if (status == XmlListModel.Ready) {
                console.log("FeedViewModel Status: ready")
            } else if (status == XmlListModel.Error) {
                console.log("FeedViewModel Status: error")
            } else if (status == XmlListModel.Loading) {
                console.log("FeedViewModel Status: loading")
            }
        }
    }

    ListModel {
        id: pfoModel
    }

    ListModel {
        id: posModel
    }

    ListModel {
        id: pfoStoreModel
    }

    ListModel {
        id: txModel
    }

    ListModel {
        id: rtModel
    }

    ListModel {
        id: overviewModel
    }

    ListModel {
        id: searchModel
//        ListElement { name: "--"; sym: "-"; exg: "-" }
    }

    Notice {
        id: notice
    }

    Component.onCompleted: {
        var date = new Date();
        //console.log(date.getMonth() + " " + date.getFullYear())

        if (date.getMonth()>=10&&date.getFullYear()==2012) {
            notice.open();
        }

        Script.setComponents(pfoModel, posModel, waitState, errorState);
        Storage.getKeyValue("pfoStats", setParams);
        Storage.getKeyValue("pfoIsLocal", setParams);
        Storage.getKeyValue("useEditGuide", setParams);

        Storage.getKeyValue("timer", setParams);
        Storage.getKeyValue("activePos", setParams);
        Storage.getKeyValue("pfoActiveIdx", setParams);
        Storage.getKeyValue("mktOverviewIdx", setParams);
        Storage.getKeyValue("mktOverviewList", setParams);
        Storage.getKeyValue("useSearchShortcut", setParams);
        Script.setGainColor(appWindow.useAsianGainColor);

        if (pfoIsLocal) {
            //console.log("Init:activePos=" + activePos);
            // activePos is the index for local portfolio when selecting a local pfo in google mode.
            fileHandler.localPos = activePos;
        }

        // Use this after Google shuts down API
//        Storage.getKeyValue("username", setParams);
//        if (username!="")
//            errorState.state = "showSignout";

//        storeParams("username", "");
//        storeParams("password", "");
//        localModeInit();

        Storage.getKeyValue("username", setLoginCredentials);
        Storage.getKeyValue("password", setLoginCredentials);

        loadPosViewSettings();
    }

    Help {
        id: helpPage
        anchors.fill: parent
    }

    AboutDialog {
        id: aboutDialog
        onAccepted: { appWindow.state = "inMainView"; }
        onRejected: { appWindow.state = "inMainView"; }
    }

    Loader {
        id: mktView
        anchors.fill: parent
        onLoaded: {
//            mktView.item.state = (appWindow.useMktViewDefault) ? "" : "newsList";
//            pageStack.push(mktView.item);
        }
    }

    Component {
        id: mktViewComp
        MktOverview {
            //id: mktView
            anchors.fill: parent

            onClose: {
                Storage.setKeyValue("mktOverviewIdx", appWindow.overviewNewsIdx);
                returnToMainView(overviewModel, 'inMainView');
            }
            onHome: {
                Storage.setKeyValue("mktOverviewIdx", appWindow.overviewNewsIdx);
                returnToMainView(overviewModel, 'inMainView');
            }
        }
    }

    NewsView {
        id: newsView
        anchors.fill: parent

        onClose: {
            pageStack.pop();
            appWindow.state = 'inStatsView';
        }
        onHome: {
            posView.state = (posView.useWidgetView) ? "widgetView" : "";
            pageStack.pop();
            appWindow.state = 'inMainView';
        }
    }

    PfoListView {
        id: pfoView
        anchors.fill: parent

        onUpdate: {
            // Clear in advance for the delayed loading
            posModel.clear();

            // storePfoSettings()
            Storage.getKeyValue("activePos", storeParams);
            Storage.getKeyValue("pfoIsLocal", storeParams);
            Storage.getKeyValue("pfoActiveIdx", storeParams);
            pageStack.pop();

            // Add delay to avoid visual glitch
            fsmTimer.restart();
        }
        onClose: {
            // Hide busy indicator for pending loadPosition.
            waitState.state = "hidden";
            pageStack.pop();
            appWindow.state = "inMainView";
        }
    }

    PosListViewAd {
        id: posView
        anchors.fill: parent

        onBack: {
            posView.chartView = "";
            posView.state = (posView.useWidgetView) ? "widgetView" : "";
            appWindow.state = 'inMainView';
        }

        onInNewsView:  {
            pageStack.push(newsView);
            appWindow.state = 'inNewsView';
        }
        onInStatsView: {
            appWindow.state = 'inStatsView'
        }
        onInTxView: {
            txView.pfoIsLocal = appWindow.pfoIsLocal;
            pageStack.push(txView);
            appWindow.state = 'inTxView'
        }
        onInRtView: {
            pageStack.push(rtView);
            appWindow.state = 'inRtView'
        }
    }

    TxSheet {
        id: txSheet
        anchors.fill: parent
        z: 2

        onAccepted: {
            // Store tx
            if (txView.state=="entryUpdate") {
                console.log("Store TX: entryUpdate");

                if (appWindow.activePos >= 0) {
                    //fileHandler.loadPos(appWindow.activePos);
                    // 1. Update C model list
                    //console.log("DBG: selectedIdx=" + txView.selectedIdx + " txId=" + fileHandler.localTxId[txView.selectedIdx]);
                    fileHandler.setPosCmodel(fileHandler.localTxId[txView.selectedIdx],
                                             appWindow.posName,
                                             appWindow.posExg,
                                             checkForComma(txSheet.myShare),
                                             checkForComma(txSheet.myPrice),
                                             checkForComma(txSheet.myComm),
                                             checkForComma(txSheet.myType));
                    // 2. Store to db
                    storePos(appWindow.activePos);
//                    fileHandler.setTx(
//                                appWindow.activePos,
//                                txView.selectedIdx,
//                                txSheet.myShare, txSheet.myPrice, txSheet.myComm, txSheet.myType);
                }
            }
            else {
                console.log("Store TX: entry");
                if (appWindow.activePos >= 0) {
                    //fileHandler.loadPos(appWindow.activePos);
                    fileHandler.storePos(appWindow.activePos,
                                         appWindow.posName,
                                         appWindow.posExg,
                                         checkForComma(txSheet.myShare),
                                         checkForComma(txSheet.myPrice),
                                         checkForComma(txSheet.myComm),
                                         checkForComma(txSheet.myType));
                }
            }

            txView.state = "";

            appWindow.loadLocalTx(appWindow.activePos, appWindow.posName, appWindow.posExg);
        }
        onRejected: {
            txView.state = "";;
        }
    }

    TxView {
        id: txView
        anchors.fill: parent

        onClose: {
            returnToMainView(txModel, 'inStatsView');
            goBack();
        }
        onHome: {
            posView.state = (posView.useWidgetView) ? "widgetView" : "";
            returnToMainView(txModel, 'inMainView');
            goBack();
        }
    }

    RtView {
        id: rtView
        anchors.fill: parent

        onClose: {
            returnToMainView(rtModel, 'inStatsView');
        }
        onHome: {
            posView.state = (posView.useWidgetView) ? "widgetView" : "";
            returnToMainView(rtModel, 'inMainView');
        }
    }


    SettingMenu {
        id: settingMenu
        anchors.fill: parent

        onSignin: {
            username = shadow_username;
            password = shadow_password;
            activePos = "";
            localModeFalse2True = false;
            localModeTrue2False = false;

            storeAccount();
            storeSettings();

            // Workaround for sticky VKB: Add delay for VKB to "settle"
            if (!useLocalMode) {
                pfoIsLocal = false;
                pfoIsYahoo = false;

                pageStack.pop();
                doLogin();
            }
            else {
                errorState.state = "shownError";
                errorState.reason = "Turn off 'Disable Google login' and try again!";
            }
        }
        onSignout: {
            posModel.clear();
            pfoModel.clear();
            Script.clearSid();
            username = password = shadow_username = shadow_password = activePos = "";

            storeAccount();
            storeSettings();

            pageStack.pop();

            // Give visual cue that signout is successful.
            errorState.state = "showSignout";
        }
        onClose: {
            storeSettings();

            // Reload portfolio data if useLocalMode change from true to false.
            if (localModeTrue2False||localModeFalse2True) {
                console.log("localMode.(True2False, False2True)=" + localModeTrue2False + "," + localModeFalse2True);

                pfoSelectedIdx = 0;
                posModel.clear();
                pfoIsLocal = pfoIsYahoo = false;

                if (localModeFalse2True) {
                    pfoModel.clear();
                    appWindow.__loadPortfolio();
                    // load pfoView
                    fsmTimer2.restart();
                }
                else
                    appWindow.doLogin();

                // switch to pfoView, delayed to avoid race condition
                pageStack.pop();
            }
            else {
                pageStack.pop();
                appWindow.state = "inMainView";
            }
        }
    }

    // Position-edit list view under portfolio view
    PosEdit {
        id: posEditView
        anchors.fill: parent

        editMode: true
        pfoIsLocal: true

        onClose: {
            // Don't self-reset to avoid X buttion popping up for Google finance
            editSheet.pfoMode = true;
            pfoView.state = "pfoEdit";

            waitState.state = "hidden";

            // Update portfolio when # of portfolio changed
            if ((pfoModel.count-appWindow.gPfoLength)!=fileHandler.localPfoName.length)
                appWindow.__loadPortfolio();

            updateLocalPfoNum(0, appWindow.pfoSelectedIdx);

            pageStack.pop();
        }
        onInTxView: {
            txView.pfoIsLocal = posEditView.pfoIsLocal;
            pageStack.push(txView);
            appWindow.state = 'inTxView'
        }
    }

    // Position search sheet
    PosFinder {
        id: posFinderSheet
        anchors.fill: parent
        z: 2

        onAccepted: {
            // Add and store the selected symbol into the specified portfolio
            var gLength = calcGPfoLength();
            gLength = posFinderSheet.pfoStoreIdx - gLength;
            if (gLength >= 0) {
                // 0. Load position in C side
                fileHandler.loadPos(gLength);
                // 1. Add & store C file
                //console.log(posFinderSheet.mySym + " " + posFinderSheet.myExg);
                fileHandler.storePos(gLength, posFinderSheet.mySym, posFinderSheet.myExg, 0, 0, 0, "Buy");
                // 2. Update pfoModel updatePfoNum();                
                updateLocalPfoNum(1, posFinderSheet.pfoStoreIdx);
            }

            // Let garbageCollect() does the cleaning
            //resetPosFinderSheet();
            searchModel.clear();

            // Auto re-load portfolio if invokng from posView
            if (appWindow.state == "inMainView") {
                pfoIsLocal = true;
                activePos = gLength
                fsmTimer.restart();
            }
        }

        onRejected: {
            // Let garbageCollect() does the cleaning
            //resetPosFinderSheet();
            //pfoView.state = "";
            searchModel.clear();
        }

        function resetPosFinderSheet() {
            posFinderSheet.myExg  = "";
            posFinderSheet.mySym  = "";
            posFinderSheet.myName = "";
        }
    }

    // Edit sheet for portfolio and position
    EditSheet {
        id: editSheet
        anchors.fill: parent
        pfoMode: true
        myIsYahoo: pfoIsYahoo
        z: 2.5

        onAccepted: {
            // PosFinder
            if (posFindMode) {
                addPfo(activePos, 0);

                appWindow.loadPfoStoreModel();

                if (pfoStoreModel.count>0) {
                    posFinderSheet.psIdx = 0;
                    posFinderSheet.pfoStoreIdx = pfoStoreModel.get(0).idx;
                    posFinderSheet.myPfoName   = pfoStoreModel.get(0).name;
                }
            }
            // Portfolio
            else if (pfoMode && editSheet.myPfoName!="") {
                //console.log(editSheet.myPfoName);
                if (pfoView.state=="entryUpdate") { addPfo(activePos, 1); }
                else                              { addPfo(activePos, 0); }

                pfoView.state = "pfoEdit";
            }
            // PosEdit
            else if (!pfoMode && (editSheet.mySym!="")){
                if (posEditView.state=="entryUpdate"||
                    posEditView.state=="googleUpdate") { addPos(posEditView.selectedIdx, 1, editSheet.mySym, editSheet.myExg); }
                else                                   { addPos(posEditView.selectedIdx, 0, editSheet.mySym, editSheet.myExg); }

                if (googleMode)
                    posEditView.state = "google";
                else {
                    // Update
                    loadLocalPfoToPosEditModel(appWindow.activePos);

                    // Clear dirty flag
                    for (var i=0; i<posModel.count; i++) {
                        if (posModel.get(i).fullname == 1) posModel.setProperty(i, "fullname", 0);
                    }

                    posEditView.state = "";
                }
            }
            // None of those
            else {
                if (pfoMode)         { pfoView.state = "pfoEdit"; }
                else if (googleMode) { posEditView.state = "google"; }
                else                 { posEditView.state = ""; }
            }
        }

        onRejected: {
            if (!posFindMode) {
                if (pfoMode)         { pfoView.state = "pfoEdit"; }
                else if (googleMode) { posEditView.state = "google"; }
                else                 { posEditView.state = ""; }
            }
        }
    }

    // Use sheet to implement this due to strange behavior in SelectionDialog
    SymbolSearch {
        id: scDialog
        anchors.fill: parent
        z: 3

        onAccepted: {
            if (posEditView.state != "" && posEditView.state != "google") {
                editSheet.mySym = scDialog.mySym;
                editSheet.myExg  = scDialog.myExg;
                console.log("symbolSearch: posEdit");
            }
            else {
                posFinderSheet.myName = scDialog.myName;
                posFinderSheet.mySym  = scDialog.mySym;
                posFinderSheet.myExg  = scDialog.myExg;

                console.log("symbolSearch: posSearch");
            }
        }

        onRejected: {
            scDialog.myName = "";
            scDialog.mySym  = "";
            scDialog.myExg  = "";
        }
    }

    //---------- inner-active ------------//
    Loader {
        id: adLoader
        anchors.fill: parent
    }

    Component {
        id: adPageComponent
        InnerActiveAdInterstitial {
            id: adPage
            width: parent.width
            height: parent.height
            skipIn: 4
        }
    }

    ///////////////////////////////
    // Timers
    ///////////////////////////////
    Timer {
        id: updateTimer
        interval: appWindow.timer*1000
        repeat: true
        running: updateTimerActive()
        onTriggered: {
            // garbage cleaning
            garbageCollect();

            if (appWindow.state=="inMktOverview") {
                console.log("mktTimer="+appWindow.timer+"s");
                appWindow.updateOverview();
            }
            else {
                console.log("posTimer="+appWindow.timer+"s");
                appWindow.__loadPosition();
            }
        }
    }

    // Running property will be available in QtMobility 1.2.1
//    AlignedTimer {
//        id: heartbeat
//        maximumInterval: appWindow.timer+5
//        minimumInterval: appWindow.timer
//        running: posView.status==PageStatus.Active && Qt.application.active
//        onTimeout: {
//            console.log("posTimer");
//            appWindow.__loadPosition();
//        }
//    }

    // Use a timer to delay events to avoid race condition
    Timer {
        id: fsmTimer
        interval: 400
        repeat: false
        onTriggered: {
            //console.log("Timer="+fsmTimer.interval+"s");
            // Stop if in setting menu
            if (appWindow.state!="inSettingView") { appWindow.state="inLoadPortfolio"; }
        }
    }

    // >= 550ms is critical to avoid page alignment issue.
    Timer {
        id: fsmTimer2
        interval: 550
        repeat: false
        onTriggered: {
            //console.log("fsmTimer2");
            if (localModeFalse2True || localModeTrue2False) {
                if (localModeFalse2True && pfoModel.count==0)
                    appWindow.state = "inPfoViewErrorLocal";
                else
                    appWindow.state = "inPfoView";

                localModeTrue2False = localModeFalse2True = false;
            }
            else if (appWindow.state=="inPfoViewError")
                appWindow.state="inPfoView";
            else if (appWindow.state=="inMktOverview") {
                console.log("fsmTimer2");
                loadMktOverview();
            }
            else
                appWindow.state="inMainView";
        }
    }

    ///////////////////////////////////////
    // Error Handling
    ///////////////////////////////////////
    // Error dialog
    StateGroup {
        id: errorState
        property string reason: ""
        states: [
            State {
                name: "";
            },

            State {
                name: "shownError";
                PropertyChanges { target: errorDialog; acceptButtonText: qsTr("Ok"); }
                PropertyChanges { target: errorDialog; titleText: qsTr("Sorry, there's an error..."); }
                StateChangeScript { script: { errorDialog.open(); } }
            },
            State {
                name: "shownMsg";
                PropertyChanges { target: errorDialog; acceptButtonText: qsTr("Ok"); }
                PropertyChanges { target: errorDialog; titleText: qsTr("Info"); }
                StateChangeScript { script: { errorDialog.open(); } }
            },
            State {
                name: "promotePfo";
                // Do not go into pfoView, since the timing could trigger UI issue.
                PropertyChanges { target: errorDialog; acceptButtonText: qsTr("Ok"); }
                StateChangeScript { script: { appWindow.state = "inPfoViewError"; } }
            },
            State {
                name: "showFeedError"
                when: (rssModel.status==XmlListModel.Error)&&(appWindow.state=="inNewsView")
                PropertyChanges { target: errorDialog; acceptButtonText: qsTr("Ok"); }
                PropertyChanges { target: errorDialog; titleText: qsTr("Sorry, there's an error..."); }
                PropertyChanges { target: errorDialog; message: qsTr("Didn't find RSS feed!"); }
                StateChangeScript { script: { errorDialog.open() } }
            },

            State {
                name: "showLocalPfoError"
                when: (appWindow.state=="inPfoViewErrorLocal")
                PropertyChanges { target: errorDialog; acceptButtonText: qsTr("Ok"); }
                PropertyChanges { target: errorDialog; message: qsTr("There's no local portfolios.\nPlease create one!"); }
                StateChangeScript { script: { errorDialog.open() } }
            },

            State {
                name: "showSignout"
                PropertyChanges { target: errorDialog; acceptButtonText: qsTr("Ok"); }
                PropertyChanges { target: errorDialog; titleText: qsTr("You've been signed out"); }
                PropertyChanges { target: errorDialog; message: qsTr("Account info are erased."); }
                StateChangeScript { script: { errorDialog.open() } }
            },

            State {
                name: "success"
                PropertyChanges { target: errorDialog; titleText: qsTr("Done"); }
                StateChangeScript { script: { errorDialog.open() } }
            }
        ]
    }

    QueryDialog {
        id: errorDialog
        message: errorState.reason

        acceptButtonText: ""
        rejectButtonText: ""

        onAccepted: {
            if (appWindow.state=="inNewsView") {
                // Clear rssModel
                rssModel.source = "";
                // return to posView
                pageStack.pop();
            }

            errorState.reason = "";
            errorState.state  = "";
        }
        onRejected: {
            errorState.reason = "";
            errorState.state  = "";
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        anchors.verticalCenterOffset: params.busyIndicatorVerticalOffset
        visible: (showBusyIndicator && (appWindow.state != "inNewsView")) || (appWindow.state == "inNewsView" && rssModel.status==XmlListModel.Loading)
        platformStyle: BusyIndicatorStyle {
            size: "large"
            // Don't chang color for appWindow.state=="inLogin" for setting signin case.
            spinnerFrames: (posView.state=="widgetView" && (appWindow.state=="inMainView"||appWindow.state=="inLoadPortfolio")) ?
                           "image://theme/spinnerinverted" : "image://theme/spinner"+__invertedString;
        }
    }

    // Controlled by js core
    StateGroup {
        id: waitState
        states: [
            State {
                name: "hidden"
            },
            State {
                name: "shown"
                PropertyChanges{ target: appWindow; showBusyIndicator: true }
                PropertyChanges{ target: busyIndicator; running: true; }
            },
            // Control by js core to continue position loading.
            State {
                name: "portfolio"
                StateChangeScript { script: { fsmTimer.restart(); } }
            }
        ]
    }

    ///////////////////////////////
    // FSM
    ///////////////////////////////
    states: [
        State {
            name: "";
            PropertyChanges{ target: appWindow; showBusyIndicator: true }
            PropertyChanges{ target: busyIndicator; running: true; }
        },

        State {
            name: "inLogin";
            StateChangeScript {
                script: {
                    dbgStr = "State.login";
                    console.log("State.login");
                }
            }
        },

        State {
            name: "inLoadPortfolio";
            // Hide listview because inLoadPortfolio clear then re-load pfoView.
            PropertyChanges { target: pfoView; state: "hidePfoListView"; }
            StateChangeScript {
                script: {
                    dbgStr = "State.inLoadPortfolio"; console.log(dbgStr);

                    // clear posModel here, pfoModel is cleared by loadAllPortfolios()
                    posModel.clear();

                    if (!useLocalMode)
                        Script.loadAllPortfolios();

                    Script.loadOnePortfolio(activePos, pfoIsLocal, pfoIsYahoo);

                    // Delayed to avoid race condition
                    // Switch to either posView or pfoView depending on localMode switching
                    fsmTimer2.restart();
                }
            }
        },

        State {
            name: "inMainView";
            StateChangeScript {
                script: {
                    dbgStr = "State.mainView"; console.log(dbgStr);
                }
            }
        },

        State {
            name: "inPfoView";
            StateChangeScript {
                script: {
                    dbgStr = "State.pfoView"; console.log(dbgStr);
                    pageStack.push(pfoView);
                }
            }
        },

        // This is triggered from QML-side by local portfolio.
        State {
            name: "inPfoViewErrorLocal";
            StateChangeScript {
                script: {
                    dbgStr = "State.pfoViewErrorLocal"; console.log(dbgStr);
                    // Do not change appWindow.state...
                    pageStack.push(pfoView);
                }
            }
        },

        // This is triggered by js core from promotePfo state.
        State {
            name: "inPfoViewError";
            StateChangeScript {
                script: {
                    dbgStr = "State.pfoViewError"; console.log(dbgStr);

                    // Trigger delayed pfoView loading
                    fsmTimer2.restart();
                }
            }
        },

        State {
            name: "inSettingView";
            StateChangeScript {
                script: {
                    dbgStr = "State.settingView"; console.log(dbgStr);

                    fsmTimer.stop();
                    fsmTimer2.stop();
                }
            }
        },

        State {
            name: "inNewsView";
            StateChangeScript {
                script: { dbgStr="State.newsView"; console.log("State.newsView"); }
            }
        },

        State {
            name: "inTxView";
            StateChangeScript {
                script: {
                    dbgStr = "State.txView"; console.log(dbgStr);
                }
            }
        },

        State {
            name: "inRtView";
            StateChangeScript {
                script: {
                    dbgStr = "State.rtView"; console.log(dbgStr);
                }
            }
        },

        State {
            name: "inStatsView";
            StateChangeScript {
                script: {
                    dbgStr = "State.statsView"; console.log(dbgStr);
                }
            }
        },

        State {
            name: "inMktOverview";
            PropertyChanges { target: rssModel; source: "http://news.google.com/news?cf=all&ned=" + mktOverviewValueLUT(appWindow.overviewNewsIdx) + "&topic=b&output=rss"; }
            StateChangeScript {
                script: {
                    mktView.sourceComponent = mktViewComp; // "MktOverview.qml";
                    //pageStack.push(mktView);
                    mktView.item.state = (appWindow.useMktViewDefault) ? "" : "newsList";
                    pageStack.push(mktView.item);
                    dbgStr = "State.mktOverview"; console.log(dbgStr);
                }
            }
        },

        State {
            name: "inAboutDialog";
            StateChangeScript { script: { console.log("State.About"); } }
        }
    ]
}
