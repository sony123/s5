/*
    Stockona is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Stockona is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with NewsFlow. If not, see <http://www.gnu.org/licenses/>.
*/

var sid = "";

// UI components
var waiting;
var error;

var model;
var pModel;

var itemsURL = "";
var pkt = "";
var pfoId = "";
var quoteListGoogle = "";
var quoteListYahoo = "";

// 0: US; 1: Asia
var quoteChgColorMode = false;

// OLED color shift
var n9Green = "#009900";

function setGainColor(gainColorMode) {
    quoteChgColorMode = gainColorMode;
}

function returnSid() {
    return sid;
}

function authSuccess() {
    return (sid=="");
}

function clearSid() {
    sid = "";
}

function setComponents(mod, pos, wait, err) {
    model   = mod;
    pModel  = pos;
    waiting = wait;
    error   = err;
}

// This will parse a delimited string into an array of
// arrays. The default delimiter is the comma, but this
// can be overriden in the second argument.
function CSVToArray( strData, strDelimiter ){
// Check to see if the delimiter is defined. If not,
// then default to comma.
strDelimiter = (strDelimiter || ",");

// Create a regular expression to parse the CSV values.
var objPattern = new RegExp(
(
// Delimiters.
"(\\" + strDelimiter + "|\\r?\\n|\\r|^)" +

// Quoted fields.
"(?:\"([^\"]*(?:\"\"[^\"]*)*)\"|" +

// Standard fields.
"([^\"\\" + strDelimiter + "\\r\\n]*))"
),
"gi"
);

// Create an array to hold our data. Give the array
// a default empty first row.
var arrData = [[]];

// Create an array to hold our individual pattern
// matching groups.
var arrMatches = null;


// Keep looping over the regular expression matches
// until we can no longer find a match.
while (arrMatches = objPattern.exec( strData )){

// Get the delimiter that was found.
var strMatchedDelimiter = arrMatches[ 1 ];

// Check to see if the given delimiter has a length
// (is not the start of string) and if it matches
// field delimiter. If id does not, then we know
// that this delimiter is a row delimiter.
if (
strMatchedDelimiter.length &&
(strMatchedDelimiter != strDelimiter)
){

// Since we have reached a new row of data,
// add an empty row to our data array.
arrData.push( [] );

}

// Now that we have our delimiter out of the way,
// let's check to see which kind of value we
// captured (quoted or unquoted).
if (arrMatches[ 2 ]){

// We found a quoted value. When we capture
// this value, unescape any double quotes.
var strMatchedValue = arrMatches[ 2 ].replace(
new RegExp( "\"\"", "g" ),
"\""
);

} else {

// We found a non-quoted value.
var strMatchedValue = arrMatches[ 3 ];

}


// Now that we have our value string, let's add
// it to the data array.
arrData[ arrData.length - 1 ].push( strMatchedValue );
}

// Return the parsed data.
return( arrData );
}

function httpErrorHandling (status, statusText, show) {
    // Ignore 500 error
    if (status==404) {
        showError(qsTr("Cannot load portfolio.") + "\n\n" + qsTr("Check if you have portfolio selected.") + "\n" + qsTr("Create one on Google if you don't have any."), 1);
        errorState.state = "promotePfo";
    }
    //else if (status==403) {
    //    showError("Do you have correct account info?", show);
    //    errorState.state = "shownError";
    //}
    else if (status==201) {
        console.log("API returns 201");
        errorState.reason = qsTr("Syncing data to Google Finance.");
        errorState.state = "success";
    }
    else if (status!=200&&status!=500) {
        showError("API returned " + status + " " + statusText, show);
    }
}

/*
 params
   0: Google Auth, encrypted
   1: Google Query with auth key
   2: Yahoo Query
   3: Google Portfolio management with auth key and atom+xml content type
*/
function doWebRequest(method, url, params, callback, show) {
    var doc = new XMLHttpRequest();
    //console.log(method + " " + url);

    // Replace http with https
    if (params&1) {
        url = url.replace("http:", "https:");
    }

    doc.onreadystatechange = function() {
        if (doc.readyState == XMLHttpRequest.HEADERS_RECEIVED) {
            var status = doc.status;
            var statusText = doc.statusText;
            httpErrorHandling(status, statusText, show);
        } else if (doc.readyState == XMLHttpRequest.DONE) {
            var data;
            var contentType = doc.getResponseHeader("Content-Type");

            if (params&1 && params!=5) {
                data = doc.responseXML.documentElement;
            }
            else {
                data = doc.responseText;
            }
//            var dbg = doc.responseText;
//            console.log(dbg);
            callback(data);
        }
    }

    doc.open(method, url);

    if(sid.length>0 && params&1) {
        // Google Finance ignore SID/LSID
        //console.log("Authorization GoogleLogin auth=" + sid);
        doc.setRequestHeader("Authorization", "GoogleLogin auth=" + sid);
        // Specifying a version
        doc.setRequestHeader("GData-Version", "2");
    }

    if(params<2) {
        //console.log("Sending: " + params);
        doc.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        doc.send();
    }
    // params is odd and not 1
    else if (params&1) {
        doc.setRequestHeader("Content-Type", "application/atom+xml");
        if (params==5)
            doc.send(idx);
        else {
            doc.send(pkt);
            pkt = "";
        }
    }
    else {
        doc.send();
    }
}

function doWebRequestIdx(method, url, params, callback, idx, show) {
    var doc = new XMLHttpRequest();
    //console.log(method + " " + url);

    // Replace http with https
    if (params&1) {
        url = url.replace("http:", "https:");
    }

    doc.onreadystatechange = function() {
        if (doc.readyState == XMLHttpRequest.HEADERS_RECEIVED) {
            var status = doc.status;
            var statusText = doc.statusText;
            httpErrorHandling(status, statusText, show);
        } else if (doc.readyState == XMLHttpRequest.DONE) {
            var data;
            //var contentType = doc.getResponseHeader("Content-Type");
            if (params&1 && params!=5) {
                data = doc.responseXML.documentElement;
            }
            else {
                data = doc.responseText;
            }
//            var dbg = doc.responseText;
//            console.log("DBG:"+ dbg);
            callback(data, idx);
        }
    }

    doc.open(method, url);

    if(sid.length>0 && params&1) {
        // Google Finance ignore SID/LSID
        doc.setRequestHeader("Authorization", "GoogleLogin auth=" + sid);
        doc.setRequestHeader("GData-Version", "2");
    }

    if(params<2) {
        //console.log("Sending: " + params);
        doc.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        doc.send();
    }
    // params is odd and not 1
    else if (params&1) {
        doc.setRequestHeader("Content-Type", "application/atom+xml");
        if (params==5)
            doc.send(idx);
        else {
            doc.send(pkt);
            pkt = "";
        }
    }
    else {
        doc.send();
    }
}

//////////////////////////////////////
// Google Pfo
//////////////////////////////////////
function createGooglePfo(pfoName, currency, idx) {
    waiting.state = "shown";

    var name = pfoName + "_meego";
    var valid = true;
    var errorCode;

    // Sanity check
    // #1 Duplicate name with Google Finance
    for (var i=0; i<model.count; i++) {
        console.log("Sanity check #1: " + name + ":" + model.get(i).name);
        if (name == model.get(i).name) {
            valid = false;
            errorCode = 1;
            showError("Duplicated portfolio name:\n" + name + "_meego.", 1);
            break;
        }
    }

    var fileOk = fileHandler.loadPos(idx);

    if (fileOk==0){

        // Sanity check
        // #2 Incomplete exchange info
        console.log("Sanity check #2");
        for (var i=0; i<fileHandler.localPosSymbol.length; i++) {
            if (fileHandler.localPosExg[i] == "") {
                valid = false;
                errorCode = 2;
                showError("Exchange cannot be empty for syncing:\n" + fileHandler.localPosSymbol[i], 1);
                break;
            }
        }

        if (valid) {
            pkt = "";
            pkt = "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:gf='http://schemas.google.com/finance/2007'>";
            pkt += "<title>" + name + "</title>";
            pkt += "<gf:portfolioData currencyCode='" + currency + "'/>";
            pkt += "</entry>";
            console.log(pkt);

            itemsURL = "http://finance.google.com/finance/feeds/default/portfolios";
            doWebRequestIdx("POST", itemsURL, 3, createGoogleTxEmbedded, idx, 1);
            return 0;
        }
        else {
            waiting.state = "hidden";
            return errorCode;
        }
    }
    else {
        waiting.state = "hidden";
        showError("Cannot load local position", 1);
        return 3;
    }
}

// Position management is through transaction
function createGoogleTxEmbedded(data, idx) {
    //console.log(data);

    // Extract pfoId
    //var pfoEtag        = data.childeNodes[0].parentNode.attributes[3].nodeValue;
    //var pfoEtag        = data.childNodes[0].attributes[3].nodeValue;
    var feedlink = data.childNodes[0].firstChild.nodeValue;      // 1,2,3...
    //console.log("id=" + feedlink);

    // Create transactions
    var urlArray = new Array();
    var tmp;

    for (var i=0; i<fileHandler.localPosSymbol.length; i++) {
        tmp = (fileHandler.localPosExg[i]=="") ? feedlink + "/positions/" + fileHandler.localPosSymbol[i] + "/transactions" :
                                                 feedlink + "/positions/" + fileHandler.localPosExg[i] + "%3A" + fileHandler.localPosSymbol[i] + "/transactions";
        urlArray.push(tmp);
    }

    createGooglePosEmbeddedLoop("", urlArray);
}

//////////////////////
// Position
//////////////////////
function createGooglePos(thisModel, feedlink, pfoIdx) {
    waiting.state = "shown";

    var urlArray = new Array();
    var tmp;
    var valid = true;
    var errorCode = 1;

    // Store in order to update portfolio number
    pfoId = new Array();
    pfoId.push(pfoIdx);
    pfoId.push(feedlink);

    for (var i=0; i<thisModel.count; i++) {
        // fullname is dirty flag.
        if (thisModel.get(i).fullname == 1) {
            // Sanity check
            // Incomplete exchange info
            if (thisModel.get(i).exchange == "") {
                valid = false;
                errorCode = 1;
                showError("Exchange cannot be empty for syncing:\n" + thisModel.get(i).name, 1);
                break;
            }
            else {
                tmp = feedlink + "/" + thisModel.get(i).exchange + "%3A" + thisModel.get(i).name + "/transactions";
                urlArray.push(tmp);

                // Clear new flag
                thisModel.setProperty(i, "fullname", 0);
            }
        }
    }

    if (valid) {
        createGooglePosEmbeddedLoop("", urlArray);
        return 0;
    }
    else
        return errorCode;
}

function createGooglePosEmbeddedLoop(data, urlArray) {

    console.log("urlArrayLength=" + urlArray.length);
    if (urlArray.length>0) {
        itemsURL = urlArray.shift();
        var share = 0;

        pkt = "";
        pkt = "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:gf='http://schemas.google.com/finance/2007'>";
        pkt += "<gf:transactionData date='" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + "T00:00:00.000' shares='" + share + "' type='Buy'>";
        pkt += "</gf:transactionData>";
        pkt += "</entry>";
        console.log(">> PosEmbeddedLoop: " + itemsURL);
        //console.log(pkt);

        doWebRequestIdx("POST", itemsURL, 3, createGooglePosEmbeddedLoop, urlArray, 1);
    }
    else {
        pkt = "";
        errorState.reason = qsTr("Sync completed.");
        errorState.state = "success";
        waiting.state = "hidden";

        if (pfoId.length==2) {
            var feedlink = pfoId.pop();
            var pfoIdx   = pfoId.pop();
            console.log("DBG:" + feedlink + " " + pfoIdx);

            loadPortfolioNum(feedlink, pfoIdx)
        }
    }
}


//////////////////////
// Transaction
//////////////////////
function createGoogleTx(txLink, txId, type, share, price, comm) {
    /*
   <entry>
     <gf:transactionData date='2007-09-26T00:00:00.000' shares='1000.0' type='Buy'>
       <gf:commission>
         <gd:money amount='0.0' currencyCode='USD'/>
       </gf:commission>
       <gf:price>
         <gd:money amount='568.2' currencyCode='USD'/>
       </gf:price>
     </gf:transactionData>
   </entry>
   */
    itemsURL = txLink;
    itemsURL = "http://finance.google.com/finance/feeds/default/portfolios/6/positions/NYSE%3AJPM/transactions";
    console.log("createGoogleTx: " + itemsURL);

    pkt = "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:gf='http://schemas.google.com/finance/2007'>";
    pkt += "<gf:transactionData date='" + Qt.formatDateTime(new Date(), "yyyy-MM-dd") + "T00:00:00.000' shares='" + share + "' type='" + type + "'>";
    //pkt += "<gf:transactionData shares='" + share + "' type='" + type + "'>";
    //pkt += "<gf:price><gd:money amount='" + price + "' currencyCode='USD'/></gf:price>";
    //pkt += "<gf:commission><gd:money amount='" + comm + "' currencyCode='USD'/></gf:commission>";

    pkt += "<gf:commission><gd:money amount='0.0' currencyCode='USD'/></gf:commission><gf:price><gd:money amount='0.0' currencyCode='USD'/></gf:price>";
    pkt += "</gf:transactionData>";
    pkt += "</entry>";
    console.log(pkt);

    doWebRequest("POST", itemsURL, 3, dummy, 1);
}

function updateGoogleTx(txLink, txId, etag, share, type, comm, price) {
    /*
<entry gd:etag='W/"DE8MRH47eCp7ImA9WxRXGE0."'>
  <id>
    http://finance.google.com/finance/feeds/liz@gmail.com/portfolios/1/positions/NASDAQ%3AGOOG/transactions/2
  </id>
  <updated>2009-11-19T23:55:59.000Z</updated>
  <app:edited xmlns:app='http://www.w3.org/2007/app'>
  2009-11-19T23:55:59.000Z</app:edited>
  <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/finance/2007#transaction'/>
  <title>2</title>
  <link rel='self' type='application/atom+xml' href='http://finance.google.com/finance/feeds/default/portfolios/1/positions/NASDAQ%3AGOOG/transactions/2'/>
  <link rel='edit' type='application/atom+xml' href='http://finance.google.com/finance/feeds/default/portfolios/1/positions/NASDAQ%3AGOOG/transactions/2'/>
  <gf:transactionData date='2007-09-27T00:00:00.000'
      shares='1000.0' type='Sell'>
    <gf:commission>
      <gd:money amount='25.0' currencyCode='USD'/>
    </gf:commission>
    <gf:price>
      <gd:money amount='201.1' currencyCode='USD'/>
    </gf:price>
  </gf:transactionData>
</entry>
    */
    itemsURL = txLink + "/" + txId;

    pkt = "<entry gd:etag='" + etag + "'>";
    pkt += "<id>" + itemsURL + "</id>";
    pkt += "<updated>" + Qt.formatDateTime(new Date(), "yyyy-MM-ddThh:mm:ss.zzz") + "</updated>";
    pkt += "<app:edited xmlns:app='http://www.w3.org/2007/app'>" + Qt.formatDateTime(new Date(), "yyyy-MM-ddThh:mm:ss.zzz") + "</app:edited>";
    pkt += "<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/finance/2007#transaction'/>";
    pkt += "<title>" + txId + "</title>";
    pkt += "<link rel='self' type='application/atom+xml' href='" + itemsURL + "'/>";
    pkt += "<link rel='edit' type='application/atom+xml' href='" + itemsURL + "'/>";
    pkt += "<gf:transactionData date='" + Qt.formatDateTime(new Date(), "yyyy-MM-ddThh:mm:ss.zzz");
    pkt += "' shares='" + share + "' type='" + type + "'>";
    pkt += "<gf:commission><gd:money amount='" + comm + "' currencyCode='USD'/></gf:commission>";
    pkt += "<gf:price><gd:money amount='" + price + "' currencyCode='USD'/>";
    pkt += "</gf:price></gf:transactionData></entry>";
    console.log(pkt);

    doWebRequest("PUT", itemsURL, 5, dummy, 1);
}

function dummy(data) {
    waiting.state = "hidden";
    console.log("data="+data);
}

function dummy2(data, pkt) {
    waiting.state = "hidden";
    console.log("data="+data);
    console.log("pkt="+pkt);
}

function updateGooglePfo(url, data) {
    console.log(data);
    // 1. Retrieve portfolio info
    // 2. Update fields
    // 3. PUT, content type: application/atom+xml
    /*
    <entry gd:etag='W/"DE8MRH47eCp7ImA9WxRXGE0."'>
      <id>
        http://finance.google.com/finance/feeds/liz@gmail.com/portfolios/1/positions/NASDAQ%3AGOOG/transactions/2
      </id>
      <updated>2009-11-19T23:55:59.000Z</updated>
      <app:edited xmlns:app='http://www.w3.org/2007/app'>
      2009-11-19T23:55:59.000Z</app:edited>
      <category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/finance/2007#transaction'/>
      <title>2</title>
      <link rel='self' type='application/atom+xml' href='http://finance.google.com/finance/feeds/default/portfolios/1/positions/NASDAQ%3AGOOG/transactions/2'/>
      <link rel='edit' type='application/atom+xml' href='http://finance.google.com/finance/feeds/default/portfolios/1/positions/NASDAQ%3AGOOG/transactions/2'/>
      <gf:transactionData date='2007-09-27T00:00:00.000'
          shares='1000.0' type='Sell'>
        <gf:commission>
          <gd:money amount='25.0' currencyCode='USD'/>
        </gf:commission>
        <gf:price>
          <gd:money amount='201.1' currencyCode='USD'/>
        </gf:price>
      </gf:transactionData>
    </entry>
    */
    var txId;

    doWebRequest("POST", url, 3, dummy, 1);
}

function loadGoogleRelated(sym, exg, rModel) {
    rModel.clear();
    waiting.state = "shown";
    itemsURL = "http://www.google.com/finance/related?q=" + exg + "%3A" + sym;
    //console.log(itemsURL);

    doWebRequestIdx("GET", itemsURL, 0, parseGoogleRelated, rModel, 1);
}

function loadGoogleMobileNews(country, model) {
    model.clear();
    waiting.state = "shown";
    itemsURL = "http://www.google.com/m/finance?hl=" + country + "&tab=we#news";
    console.log(itemsURL);

    doWebRequestIdx("GET", itemsURL, 0, dummy, model, 1);
}

function parseGoogleRelated(data, rModel) {
    //console.log(data);

    /* Find
    google.finance.data = {
    common:{rq:{ct:""},up:"chg",down:"chr",linktargetInternal:"",hash:"OWdQbm1zSkk4MHNVUlNZS2ptRDFmblIzSzNrfDEzMjE5MDYwNjI"},
    company:{
    related:{
    cols:[0,1,4,30,34,31,32,5,2,33,3],
    rows:[
    {id:"662079",values:["BRCM","Broadcom Corporation","32.14","-0.63","chr","-1.92","","17.32B","NASDAQ","662079","BRCM"]},
    {id:"656142",values:["QCOM","QUALCOMM, Inc.","54.20","-1.26","chr","-2.26","","91.11B","NASDAQ","656142","QCOM"]},
    {id:"34649",values:["TXN","Texas Instruments Inc.","29.26","-0.79","chr","-2.63","","33.43B","NYSE","34649","TXN"]},
    {id:"284784",values:["INTC","Intel Corporation","23.52","-0.77","chr","-3.19","","119.74B","NASDAQ","284784","INTC"]},
    {id:"695775",values:["NETL","NetLogic Microsystems, Inc.","49.36","-0.01","chr","-0.02","","3.43B","NASDAQ","695775","NETL"]},
    {id:"664838",values:["MRVL","Marvell Tech. Group Ltd.","14.40","-0.24","chr","-1.67","","8.73B","NASDAQ","664838","MRVL"]},
    {id:"658044",values:["STM","STMicroelectronics N.V. (ADR)","6.30","-0.40","chr","-5.97","","5.58B","NYSE","658044","STM"]},
    {id:"660493",values:["ZRAN","Zoran Corporation","8.11","0.00","chb","0.00","","407.16M","NASDAQ","660493","ZRAN"]},
    {id:"526627",values:["PMCS","PMC-Sierra, Inc.","5.72","-0.12","chr","-2.14","","1.32B","NASDAQ","526627","PMCS"]},
    {id:"662925",values:["NVDA","NVIDIA Corporation","14.44","+0.51","chg","3.66","","8.72B","NASDAQ","662925","NVDA"]},
    {id:"664477",values:["IFNNY","Infineon Tech. AG (ADR)","7.78","-0.15","chr","-1.89","","8.45B","PINK","664477","IFNNY"]}],
    visible_cols:[0,1,4,30,34,31,32,5]}},
    stickyUrlArgs:""
    };*/

//    var tmp= data;
//    var sIdx = tmp.indexOf("google.finance.data");
//    var eIdx = tmp.indexOf(";", sIdx);
//    console.log("qml (start,end)=" + sIdx + "," + eIdx);
//    tmp = tmp.substr(sIdx, eIdx - sIdx);
//    console.log(tmp);
    data = fileHandler.parseGoogleRelated(data);

    var jObj = eval("(" + data + ")");

    if (jObj=="") {
        waiting.state = "hidden";
        showError("Didn't find related symbols!", 1);
    }
    else {
        var rLength = jObj.company.related.rows.length;
        console.log("rLength=" + rLength);

        // name; fullname; price; sign; change; changePtg; ""; market cap; exchange
        //{id:"662079",values:["BRCM","Broadcom Corporation","32.14","-0.63","chr","-1.92","","17.32B","NASDAQ","662079","BRCM"]},
        for (var i=0; i<rLength; i++) {
            // There are two patterns due to Google's inconsistency
            // col:[0,1,4,30,34,31,32,5,2,33,3]
            // col:[0,1,2,37,4,30,34,31,10,11,5,14,27,7,8,21,22,33,3]
            //["NOK","Nokia Corporation (ADR)","NYSE","USD","5.33","-0.09","chr","-1.66","-0.42","","19.96B","0.26","14.70","-3.95","-8.87","-2.78","-3.85","657729","NOK"]

            // Mapping
            // sym: 0
            // fullname: 1
            // exchange: 2
            // price: 4
            // change: 30
            // change_str: 34
            // change %: 31
            // mkt_cap: 32

            var mySym    = "";
            var myName   = "";
            var myPrice  = "";
            var myChg    = "";
            var myChgStr = "";
            var myChgPtg = "";
            var myMktCap = "";
            var myExg    = "";

            for (var j=0; j < jObj.company.related.cols.length; j++) {
                switch(jObj.company.related.cols[j]) {
                    case 0:
                        mySym = jObj.company.related.rows[i].values[j];
                        break;
                    case 1:
                        myName = jObj.company.related.rows[i].values[j];
                        break;
                    case 2:
                        myExg = jObj.company.related.rows[i].values[j];
                        break;
                    case 4:
                        myPrice = jObj.company.related.rows[i].values[j];
                        break;
                    case 30:
                        myChg = jObj.company.related.rows[i].values[j];
                        break;
                    case 34:
                        myChgStr = jObj.company.related.rows[i].values[j];
                        break;
                    case 31:
                        myChgPtg = jObj.company.related.rows[i].values[j];
                        break;
                    case 32:
                        myMktCap = jObj.company.related.rows[i].values[j];
                        break;
                    default:
                        break;
                }
            }

            // Push to txModel
            var tmp;
            tmp = convertGoogleRelatedInfo(myChgPtg);
//            //console.log("convert: sign=" + tmp.sign + " color=" + tmp.color);

            rModel.append({
                "id":            i ,
                "name":          mySym ,
                "fullname":      myName ,
                "quotePrice":    myPrice ,
                "quoteChg":      myChg ,
                "quoteChgColor": "green", //tmp.color ,
                "quoteChgPtg":   myChgPtg ,
                "quoteMktCap":   myMktCap ,
                "exchange":      myExg
            });
        }
        waiting.state = "hidden";
    }
}

function convertGoogleRelatedInfo(sign){
    var tmp;

    // "-"
    if (sign=="chr") {
        tmp = {
            "color": (quoteChgColorMode) ? n9Green : "red",
            "sign":  "-"
        }
    }
    // "+"
    else if (sign=="chg") {
        tmp = {
            "color": (quoteChgColorMode) ? "red" : n9Green,
            "sign":  "+"
        }
    }
    // chb
    else {
        tmp = {
            "color": (quoteChgColorMode) ? n9Green : "red",
            "sign":  ""
        }
    }

    return tmp;
}

function loadGoogleExtra(mdl) {
    waiting.state = "shown";

    var country = "us";

    // Cannot parse Chinese....
    if (country=="uk")
        itemsURL = "http://www.google.com.uk/finance";
    // China
    else if (country=="cn")
    itemsURL = "http://www.google.com.hk/finance?hl=zh-CN";
    // HK
    else if (country=="hk")
    itemsURL = "http://www.google.com.hk/finance";
    // Canada
    else if (country=="ca")
        itemsURL = "http://www.google.ca/finance";
    else
        itemsURL = "http://www.google.com/finance";
    console.log(itemsURL);
    //mdl.clear();

    doWebRequestIdx("GET", itemsURL, 0, parseGoogleExtra, mdl, 1);
}

function parseGoogleExtra(data, mdl) {
    var varList = fileHandler.parseGoogleCurrency(data);

    var exLength = varList.length;
    console.log("exLength=" + exLength + " quoteLength=" + mdl.quoteLength);
    //console.log("mdl.length="+mdl.model.count);

    // This makes currency/bond info only available after quote info are loaded successfully.
    if ((exLength%3 == 0) &&
        (exLength > 0) &&
        (mdl.model.count >= mdl.quoteLength)) {
        for (var i=0; i < exLength; i+=3) {
            //console.log("i="+i+", "+varList[i]);
            var quoteChgColor;

            if (varList[i+2].indexOf("+")==0)
                quoteChgColor = (quoteChgColorMode) ? "red" : n9Green;
            else
                quoteChgColor = (quoteChgColorMode) ? n9Green : "red";

            var idx = i/3;

            if (idx < (mdl.model.count - mdl.quoteLength)) {
                    mdl.model.set( mdl.quoteLength+idx, {
                        "name":        varList[i],
                        "quotePrice":  varList[i+1],
                        "quoteChg":    "",
                        "quoteChgPtg": varList[i+2],
                        "quoteChgColor":  quoteChgColor,
                        "type":        (varList[i+1]=="header") ? "h" : "ns"
                    });
            }
            else {
                    mdl.model.append({
                        "name":        varList[i],
                        "quotePrice":  varList[i+1],
                        "quoteChg":    "",
                        "quoteChgPtg": varList[i+2],
                        "quoteChgColor":  quoteChgColor,
                        "type":        (varList[i+1]=="header") ? "h" : "ns"
                    });
            }
        }
    }

    waiting.state = "hidden";
}

function loadGoogleFinanceSearch(query, mdl) {
    mdl.clear();
    waiting.state = "shown";
    itemsURL = "http://www.google.com/finance?q=" + query + "&restype=company&noIL=1&num=20";
    console.log(itemsURL);

    doWebRequestIdx("GET", itemsURL, 0, parseGoogleFinanceSearch, mdl, 1);
}

function parseGoogleFinanceSearch(data, mdl) {
    //console.log(data);
    var scList = fileHandler.parseGoogleFinanceSearch(data);
    var scLength = scList.length;
    console.log("scLength=" + scLength);

    if ((scLength%3==0) && (scLength>0)) {
        for (var i=0; i < scLength; i+=3) {
            mdl.append({
                "sym": scList[i],
                "exg": scList[i+1],
                "name": scList[i+2]
            });
        }
    }
    else {
        mdl.append({
                "sym": " ",
                "exg": " ",
                "name": "No suggestion found."
        });
    }

    for (var i=0; i<mdl.count; i++)
        console.log(mdl.get(i).name);

    waiting.state = "hidden";
}

//////////////////////////////////////
// Login
//////////////////////////////////////

function parseAuth(data, parameterName) {
    var parameterIndex = data.indexOf(parameterName + "=");
    if(parameterIndex<0) {
        console.log("Didn't find Auth");
        return "";
    }
    var equalIndex = data.indexOf("=", parameterIndex);
    if(equalIndex<0) {
        return "";
    }

    var lineBreakIndex = data.indexOf("\n", equalIndex+1)

    var value = "";
    value = data.substring(equalIndex+1, lineBreakIndex);
    return value;
}

function parseToken(data) {
    sid = parseAuth(data, "Auth");
    //console.log("Auth=" + sid);

    if(sid.length>0) {
        waiting.state = "portfolio";
    } else {
        //addError("Couldn't parse SID");
        showError(qsTr("Login failed.\n\nCheck username, password, or network connection.\nIf you use 2-step verification, please create a single-use password."), 1);
        waiting.state = "hidden";
    }
}

function login(email, password) {
    sid = "";
    error.reason = "";
    error.state  = "hidden";

    try {
        waiting.state = "shown";
        var url = "https://www.google.com/accounts/ClientLogin?Email=" + encodeURIComponent(email) + "&Passwd=" + encodeURIComponent(password) + "&service=finance" + "&source=" + encodeURIComponent("stockona");
        //console.log(url);
        doWebRequest("POST", url, 0, parseToken, 1);
    }catch(err) {
        showError(qsTr("Error while logging in: ") + err, 1);
    }
}

function showError(msg, dbg) {
    console.log(msg);
    waiting.state = "hidden";

    if (dbg>0) {
        error.reason = msg;
        error.state = "shownError";
    }
}

function addError(msg) {
    console.log(msg);
    error.reason = msg;
    error.state = "shownError";
}

function loadAllPortfolios() {
    itemsURL = "http://finance.google.com/finance/feeds/default/portfolios?returns=true";
    //itemsURL = "http://finance.google.com/finance/feeds/default/portfolios";
    console.log(itemsURL);
    loadPortfolio();
}

//////////////////////////////////////
// Loading
//////////////////////////////////////

function loadOnePortfolio(posFeedLink, pfoLocal, pfoIsYahoo) {

    // pfoModel not ready when calling loadOnePortfolio, so cannot use activePos index to look up the feedlink.
//    var posFeedLink;
//    if (pfoLocal)
//        posFeedLink = activePos;
//    else
//        posFeedLink = model.get(activePos).feedLink;

    // activePos is not set upon first entry
    if (posFeedLink=="")
        posFeedLink = "http://finance.google.com/finance/feeds/default/portfolios/1/positions";

    console.log("loadOnePortfolio: " + posFeedLink + " " + pfoLocal + " " + pfoIsYahoo);

    if (pfoLocal)
        loadLocalPosition(posFeedLink, pfoIsYahoo);
    else
        loadPosition(posFeedLink);
}

function loadAllQuotes(quoteList, pfoLocal) {
    itemsURL = "http://www.google.com/finance/info?client=ig&infotype=infoquoteall&q=" + quoteList;
    console.log(itemsURL);
    try {
        waiting.state = "shown";
        //doWebRequest("GET", itemsURL, 2, parseJSONAll, 3);
        doWebRequestIdx("GET", itemsURL, 2, parseJSONAll, pfoLocal, 3);
    } catch(err) {
        showError("Error while loading g_quote: " + err, 1);
    }
}

function loadAllQuotesIntoModel(quoteList, quoteLength, mdl) {
    itemsURL = "http://www.google.com/finance/info?client=ig&infotype=infoquoteall&q=" + quoteList;
    //console.log(itemsURL);
    try {
        waiting.state = "shown";
        //mdl.clear();
        var tmp = {
            "model": mdl,
            "quoteLength": quoteLength
        };
        doWebRequestIdx("GET", itemsURL, 2, parseJSONAllModel, tmp, 3);
    } catch(err) {
        showError("Error while loading g_quote: " + err, 1);
    }
}

function loadTx(txLink, tModel) {
    try {
        waiting.state = "shown";

        tModel.clear();
        itemsURL = txLink;
        console.log(itemsURL);
        doWebRequestIdx("GET", itemsURL, 1, parseTx, tModel, 1);
    } catch(err) {
        showError("Error while loading portfolio: " + err, 1);
    }
}

function loadPortfolio() {
    try {
        model.clear();
        waiting.state = "shown";
        doWebRequest("GET", itemsURL, 1, parsePortfolio, 1);
    } catch(err) {
        showError("Error while loading portfolio: " + err, 1);
    }
}

function loadPortfolioNum(posLink, pfoIdx) {
    try {
        waiting.state = "shown";
        itemsURL = posLink;
        doWebRequestIdx("GET", itemsURL, 1, parsePortfolioNum, pfoIdx, 1);
    } catch(err) {
        showError("Error while loading portfolio num: " + err, 1);
    }
}

function loadPosition(posFeedLink) {
    console.log("loadPosition");
    // Pull both return and transactions info
    itemsURL = posFeedLink+"?returns=true";

    try {
        waiting.state = "shown";
        doWebRequest("GET", itemsURL, 1, parsePosition, 2);
    } catch(err) {
        showError("Error while loading position: " + err, 1);
    }
}

// Simple parsing for loading Google portfolio symbols in posEditView.
function loadPositionSymbol(posFeedLink, thisModel) {
//    console.log("loadPositionSymbol");
    // Pull both return and transactions info
    itemsURL = posFeedLink + "?returns=true";

    try {
        waiting.state = "shown";
        doWebRequestIdx("GET", itemsURL, 1, parsePositionSymbol, thisModel, 2);
    } catch(err) {
        showError("Error while loading position: " + err, 1);
    }
}

function loadQuoteHeader(symObj, idx) {
    //console.log("loadQuoteHeader: idx=" + idx + " pModel.count=" + pModel.count);
    if (idx >= pModel.count) {
        pModel.append({
                     //"idx":            idx,
                     //"id":             symObj.symFeedLink,
                     //"eTag":           symObj.symEtag,
                     //"rtnYTD":         symObj.symRtnYTD,
                     "share":            symObj.symShare,
                     "shareCost":        symObj.shareCost,
                     "shareDayGain":     symObj.shareDayGain,
                     "shareGain":        symObj.shareGain,
                     "shareValue":       symObj.shareValue,
                     "shareGainPercent": symObj.shareGainPercent,

                     "exchange":       "-",
                     "fullName":       "-",
                     "name":           "Loading",

                     "quotePrice":     "-",

                     "quoteChgColor":  n9Green,
                     "quoteChg":       "-",
                     "quoteChgPtg":    "-",
                     "quoteVol":       "-",
                     "quoteAvgVol":    "-",
                     "quoteMktCap":    "-",

                     "quoteDayHi":     "-",
                     "quoteDayLo":     "-",
                     "quote52wHi":     "-",
                     "quote52wLo":     "-",

                     "quoteEps":       "-",
                     "quoteBeta":      "-",
                     "quotePe":        "-",
                     "quoteType":      "-",
                     "quoteAsk":       "-",
                     "quoteBid":       "-",
                     "quoteDiv":       "-",
                     "quoteYld":       "-",
                     "afterPrice":     "-",
                     "afterChg":       "-",
                     "afterChgPtg":    "-",
                     "afterChgColor":  n9Green
        });
    }
    else {
        pModel.set(idx, {
            "share":          symObj.symShare,
            "shareGain":      symObj.shareGain,
            "shareCost":      symObj.shareCost,
            "shareDayGain":   symObj.shareDayGain,
            "shareValue":     symObj.shareValue,
            "shareGainPercent": symObj.shareGainPercent
            //"rtnYTD":         symObj.symRtnYTD
        });
    }
}

function loadQuote(symObj, idx) {
    if (idx >= pModel.count) {
        pModel.append({
                     //"idx":            idx,
                     //"id":             symObj.symId,
                     //"rtnYTD":         symObj.symRtnYTD,
                     "share":          symObj.symShare,
                     "shareCost":      symObj.shareCost,
                     "shareDayGain":   symObj.shareDayGain,
                     "shareGain":      symObj.shareGain,
                     "shareValue":     symObj.shareValue,
                     "shareGainPercent": symObj.shareGainPercent,

                     "exchange":       "-",
                     "fullName":       "-",
                     "name":           "Loading",

                     "quotePrice":     "-",

                     "quoteChgColor":  n9Green,
                     "quoteChg":       "-",
                     "quoteChgPtg":    "-",
                     "quoteVol":       "-",
                     "quoteAvgVol":    "-",
                     "quoteMktCap":    "-",

                     "quoteDayHi":     "-",
                     "quoteDayLo":     "-",
                     "quote52wHi":     "-",
                     "quote52wLo":     "-",

                     "quoteEps":       "-",
                     "quoteBeta":      "-",
                     "quotePe":        "-",
                     "quoteType":      "-",
                     "quoteAsk":       "-",
                     "quoteBid":       "-",
                     "quoteDiv":       "-",
                     "quoteYld":       "-",
                     "afterPrice":     "-",
                     "afterChg":       "-",
                     "afterChgPtg":    "-",
                     "afterChgColor":  n9Green
        });
    }
    else {
        pModel.set(idx, {
            "share":          symObj.symShare,
            "shareGain":      symObj.shareGain,
            "shareCost":      symObj.shareCost,
            "shareDayGain":   symObj.shareDayGain,
            "shareValue":     symObj.shareValue,
            "shareGainPercent": symObj.shareGainPercent
            //"rtnYTD":         symObj.symRtnYTD
        });
    }

    try {
        waiting.state = "shown";
        doWebRequestIdx("GET", itemsURL, 2, parseJSON, idx, 3);
    } catch(err) {
        showError("Error while loading g_quote: " + err, 1);
    }
}

function loadYahooQuote(quoteList, isYahooQuote) {
    try {
        if (isYahooQuote)
            itemsURL =   "http://download.finance.yahoo.com/d/quotes.csv?s="+ quoteList + "&f=b2b3ghjkc6k2l1j3a2vr2e7xndy";
        else
            itemsURL =   "http://download.finance.yahoo.com/d/quotes.csv?s="+ quoteList + "&f=b2b3dy";

        waiting.state = "shown";
        //console.log(itemsURL);
        doWebRequestIdx("GET", itemsURL, 2, parseCSV, isYahooQuote, 3);
    } catch(err) {
        showError("Error while loading y_quote: " + err, 1);
    }
}

//////////////////////////////////////
// Local
//////////////////////////////////////
function loadLocalPortfolio(gPfoLength) {

    var fileOk = fileHandler.loadPfo();
    console.log("pfoFileOk="+fileOk);
    if (fileOk==0){
        //var length = (fileHandler.plus) ? fileHandler.localPfoName.length : 1;
        var pfoLength = fileHandler.localPfoName.length;
        for (var i=0; i < pfoLength; i++) {
            if ((i+gPfoLength) < model.count) {
                model.set(i, {
                             "local": 1,
                             "name": fileHandler.localPfoName[i],
                             "feedLink": "",
                             "excerpt": fileHandler.localPfoDesc[i],
                             "isYahoo": fileHandler.localPfoIsYahoo[i],
                             "num": fileHandler.localPfoNum[i],
                             "cost": "",
                             "gain": "",
                             "value": ""
                });
            }
            else {
                model.append({
                             "local": 1,
                             "name": fileHandler.localPfoName[i],
                             "feedLink": "",
                             "excerpt": fileHandler.localPfoDesc[i],
                             "isYahoo": fileHandler.localPfoIsYahoo[i],
                             "num": fileHandler.localPfoNum[i],
                             "cost": "",
                             "gain": "",
                             "value": ""
                });
            }
        } // end of for loop i
    }
    // For users that never have local portfolio, this causes bogus warning.
    //else if (fileOk==-1) {
    //    showError("Cannot load local portfolio.",1);
    //}

}

//////////////////////////////////////
// Parse Portfolio
//////////////////////////////////////
function parseTx(data, tModel) {
    //try {
        //console.log("DATA: " + data);

        // 2) XML DOM
        var txLength = data.childNodes[8].firstChild.nodeValue;
        console.log("tx.length="+txLength);

        // <entry>
        for (var i=0; i<txLength; i++) {
            var txEtag        = data.childNodes[11+i].attributes[0].nodeValue;
            var txId          = data.childNodes[11+i].childNodes[0].firstChild.nodeValue;      // 1,2,3...

            var txShare, txType;
            // If data exists, then attributes[1,2]
            // else attributes[0,1]
            if (data.childNodes[11+i].childNodes[7].attributes[0].nodeName=="date") {
                txShare       = data.childNodes[11+i].childNodes[7].attributes[1].nodeValue;   // Title
                txType        = data.childNodes[11+i].childNodes[7].attributes[2].nodeValue;   // Link of position
            }
            else {
                txShare       = data.childNodes[11+i].childNodes[7].attributes[0].nodeValue;   // Title
                txType        = data.childNodes[11+i].childNodes[7].attributes[1].nodeValue;   // Link of position
            }
            var txCommision   = data.childNodes[11+i].childNodes[7].childNodes[0].firstChild.attributes[0].nodeValue;
            var txPrice       = data.childNodes[11+i].childNodes[7].childNodes[1].firstChild.attributes[0].nodeValue;

//            console.log("Etag="+txEtag);
//            console.log("Id="+txId);
//            console.log("Share=" + txShare + " Type=" + txType + " Commision=" + txCommision + " Price=" + txPrice);

            // Push to txModel
            if (i<tModel.count) {
                tModel.set(i, {
                    "id": txId,
                    "type": txType,
                    "share": txShare,
                    "price": txPrice,
                    "comm": txCommision
                });
            }
            else {
                tModel.append({
                    "id": txId,
                    "type": txType,
                    "share": txShare,
                    "price": txPrice,
                    "comm": txCommision
                });
            }
        }

    //}catch(err) {
    //    addError("Error: " + err);
    //}

    waiting.state = "hidden";
}

function parsePortfolio(data) {
    //try {
        //console.log("DATA: " + data);

        // 2) XML DOM
        //var pfoLength = (fileHandler.plus) ? data.childNodes[8].firstChild.nodeValue : 1;
        var pfoLength = data.childNodes[8].firstChild.nodeValue;
        //console.log("pfo.length="+pfoLength);

        // <entry>
        for (var i=0; i<pfoLength; i++) {
            var pfoEtag        = data.childNodes[11+i].attributes[0].nodeValue;
            var pfoId          = data.childNodes[11+i].childNodes[0].firstChild.nodeValue;      // 1,2,3...

            var pfoName        = data.childNodes[11+i].childNodes[4].firstChild.nodeValue;      // Title
            var pfoFeedLink    = data.childNodes[11+i].childNodes[7].attributes[0].nodeValue;   // Link of position
            var currency       = data.childNodes[11+i].childNodes[8].attributes[0].nodeValue;
            var pfoGainPercent = data.childNodes[11+i].childNodes[8].attributes[1].nodeValue;
            var pfoRtnYTD      = data.childNodes[11+i].childNodes[8].attributes[9].nodeValue;

            /// These info are conditional, only portfolio that have TXs are shown
            var pfoCostBasis = "";
            var pfoGain      = "";
            var pfoMktValue  = "";

            if (data.childNodes[11+i].childNodes[8].childNodes.length == 4) {
                pfoCostBasis   = fileHandler.formatNumber(data.childNodes[11+i].childNodes[8].firstChild.firstChild.attributes[0].nodeValue);
                pfoGain        = fileHandler.formatNumber(data.childNodes[11+i].childNodes[8].childNodes[2].firstChild.attributes[0].nodeValue);
                pfoMktValue    = fileHandler.formatNumber(data.childNodes[11+i].childNodes[8].childNodes[3].firstChild.attributes[0].nodeValue);
                //console.log("(cost,gain,mkt)=(" + pfoCostBasis + "," + pfoGain + "," + pfoMktValue + ")");
            }

            // Push to pfoModel
            if (i<model.count) {
                model.set(i, {
                             "name": pfoName,
                             "feedLink": pfoFeedLink,
                             "excerpt": "-",
                             "num": 0,
                             "cost": pfoCostBasis,
                             "gain": pfoGain,
                             "value": pfoMktValue
                });
            }
            else {
                //pfoCModel.append(false, false, 0, pfoName, pfoFeedLink, "-");
                model.append({
                             "local": 0,
                             "name": pfoName,
                             "feedLink": pfoFeedLink,
                             "isYahoo": false,
                             "excerpt": "-",
                             "num": 0,
                             "cost": pfoCostBasis,
                             "gain": pfoGain,
                             "value": pfoMktValue
                });
            }

            // Retrieve number of quotes for each portfolio... this is kinda redundant but do with it for now.
            //var idx = i + 1;
            var posLink = pfoId + "/positions";
            loadPortfolioNum(posLink,i);

            /*
            console.log("<Portfolio.entry>");
            console.log("pfo.name"+pfoName);
            console.log("pfo.etag="+pfoEtag);
            console.log("pfo.Id="+pfoId);
            console.log("pfo.feedLink="+pfoFeedLink);
            console.log("currency="+currency);
            console.log("pfo.gainPercent="+pfoGainPercent);
            console.log("pfo.rtnYTD="+pfoRtnYTD);
            //*/
        }

    //}catch(err) {
    //    addError("Error: " + err);
    //}
    // Load local portfolio
    loadLocalPortfolio(pfoLength);

    waiting.state = "hidden";
}

function parsePortfolioNum(data, pfoIdx) {
    var posLength = data.childNodes[7].firstChild.nodeValue;
    var symName = new String("");

    for (var i=0; i< ((posLength>3) ? 3 : posLength) ; i++) {
        symName += data.childNodes[10+i].childNodes[7].attributes[2].nodeValue + ", ";
    }

    var lastComma = symName.lastIndexOf(",");
    symName = symName.substring(0, lastComma);
    symName +=  " ...";

    // Push to pfoModel
    //console.log("idx="+pfoIdx+" num="+posLength);
    if (pfoIdx < model.count) {
        model.set(pfoIdx, {
                  "num": posLength,
                  "excerpt": symName
        });
    }

    waiting.state = "hidden";
}

//////////////////////////////////////
// Parse Position
//////////////////////////////////////
function loadLocalPosition(pfoIdx, pfoIsYahoo) {
    console.log("loadLocalPosition");
    waiting.state = "shown";

    var fileOk = 0;
    quoteListGoogle = quoteListYahoo = "";

    fileOk = fileHandler.loadPos(pfoIdx);
    //console.log("fileOk="+fileOk+" "+fileHandler.localPosSymbol.length);

    if (fileOk==0) {
        for (var i=0; i<limitLength(fileHandler.localUniSymbol.length); i++) {
            //console.log(i + ":" + fileHandler.localUniSymbol[i]);

            // Load header for local Google portfolio
            if (!pfoIsYahoo) {
                var symObj = {
                        "symName":  fileHandler.localUniSymbol[i],
                        "symExg":   fileHandler.localUniExg[i],
                        "symShare": jRound(fileHandler.localUniShare[i]),
                        //"symEtag": "-",
                        "symFeedLink": "-",
                        "shareCost": "-", //fileHandler.localUniCost[i],
                        "shareDayGain": "-",
                        "shareGain": "-",
                        "shareValue": "-",
                        "shareGainPercent": "-"
                };

                loadQuoteHeader(symObj, i);

                if (symObj.symExg=="")
                    quoteListGoogle = quoteListGoogle + "," + symObj.symName;
                else
                    quoteListGoogle = quoteListGoogle + "," + symObj.symExg + ":" + symObj.symName;

                if (symObj.symName==".DJI")
                    quoteListYahoo  = quoteListYahoo + "+" + "INDU";
                else
                    quoteListYahoo  = quoteListYahoo + "+" + convertExchangeForYahoo(symObj.symName, symObj.symExg);
            }
            else {
                // Convert ^DJI to INDU to bypass yahoo limitation. Alternatively can use YQL but requires re-write.
                if (symObj.symName=="^DJI")
                    quoteListYahoo  = quoteListYahoo + "+" + "INDU";
                else
                    quoteListYahoo  = quoteListYahoo + "+" + symObj.symName + "." + symObj.symExg;
            }
        }
        // Take out leading symbol
        quoteListGoogle = quoteListGoogle.replace(/^\,/, "");
        quoteListYahoo = quoteListYahoo.replace(/^\+/, "");

        updateTimerQuotes(pfoIsYahoo, 1);

        // clear localPos* to save memory
        if (fileHandler.localPosSymbol.length>0)
            fileHandler.clearPosCmodel();

        waiting.state = "hidden";
    }
    else if (fileOk==-1){
        console.log("posLocalError: Cannot load position file " + pfoIdx + ".pos");
        //waiting.state = "posLocalError";
        waiting.state = "hidden";
    }
    else if (fileOk==-2){
        console.log("posLocalError: File format is wrong for " + pfoIdx + ".pos");
        waiting.state = "hidden";
    }
}

function parsePosition(data) {
    //try {
        var posLength = data.childNodes[7].firstChild.nodeValue;

        console.log("pos.length="+posLength);
        quoteListGoogle = quoteListYahoo = "";

        // Improved error handling
        if (posLength==0) {
            showError(qsTr("Cannot load portfolio.") + "\n\n" + qsTr("Check if you have portfolio selected.") + "\n" + qsTr("Create one on Google if you don't have any."), 1);
            errorState.state = "promotePfo";
        }
        else {
            for (var i=0; i<limitLength(posLength); i++) {
                var symObj = {
                "shareGainPercent" : fileHandler.formatNumber(100*data.childNodes[10+i].childNodes[6].attributes[0].nodeValue), // Same as returnOverall
                "symRtnYTD"      :   fileHandler.formatNumber(100*data.childNodes[10+i].childNodes[6].attributes[8].nodeValue),
                "symShare"       : data.childNodes[10+i].childNodes[6].attributes[9].nodeValue,
                "symExg"         : data.childNodes[10+i].childNodes[7].attributes[0].nodeValue,
                "symName"        : data.childNodes[10+i].childNodes[7].attributes[2].nodeValue,

                "shareCost"     : "-",
                "shareValue"    : "-",
                "shareDayGain"  : "-",
                "shareGain"     : "-",
                "symFeedLink"   :  data.childNodes[10+i].childNodes[5].attributes[0].nodeValue,   // transaction link
                "symEtag"        : data.childNodes[10+i].attributes[0].nodeValue,
                // Don't parse for now...
                //"symFullName"    : data.childNodes[10+i].childNodes[7].attributes[1].nodeValue,
                };

                // Performance
                // costBasis, gain, mktValue. Only those who have TX records are available
                if (data.childNodes[10+i].childNodes[6].childNodes.length==4) {
                    symObj.shareCost    = fileHandler.formatNumber(data.childNodes[10+i].childNodes[6].childNodes[0].firstChild.attributes[0].nodeValue);
                    symObj.shareDayGain = fileHandler.formatNumber(data.childNodes[10+i].childNodes[6].childNodes[1].firstChild.attributes[0].nodeValue);
                    symObj.shareGain    = fileHandler.formatNumber(data.childNodes[10+i].childNodes[6].childNodes[2].firstChild.attributes[0].nodeValue);
                    symObj.shareValue   = fileHandler.formatNumber(data.childNodes[10+i].childNodes[6].childNodes[3].firstChild.attributes[0].nodeValue);
                }

                //console.log(symObj.symName + " cost=" + symObj.shareCost + " value=" + symObj.shareValue + " gain=" + symObj.shareGain);

                // JSON Parsing, parsed data stored in global jsonObj.
                // Push needs to be done in parseJSON to keep the program synchronous.
                loadQuoteHeader(symObj, i);
                quoteListGoogle = quoteListGoogle + "," + symObj.symName + ":" + symObj.symExg;
                quoteListYahoo  = quoteListYahoo + "+" + convertExchangeForYahoo(symObj.symName, symObj.symExg);

                /*
                console.log("<position.entry>");
                //console.log("pos.etag="+symObj.symEtag);
                console.log("pos.id="+symObj.symId);
                console.log("pos.feedLink="+symObj.symFeedLink);
                console.log("pos.gainPercent="+symObj.shareGainPercent);
                console.log("pos.rtnYTD="+symObj.symRtnYTD);
                console.log("pos.share="+symObj.symShare);
                console.log("pos.exchange="+symObj.symExg);
                console.log("pos.fullName="+symObj.symFullName);
                console.log("pos.name="+symObj.symName);
                //*/
            } // for

        // Take out leading +
        quoteListGoogle = quoteListGoogle.replace(/^\,/, "");
        quoteListYahoo  = quoteListYahoo.replace(/^\+/, "");

        updateTimerQuotes(pfoIsYahoo, 0);
    //}catch(err) {
    //    addError("Error: " + err);
    //}
    waiting.state = "hidden";
        }
}

function parsePositionSymbol(data, thisModel) {
    //try {
        var posLength = data.childNodes[7].firstChild.nodeValue;
        console.log("pos.length="+posLength);

        // Improved error handling
        if (posLength==0) {
            showError(qsTr("Cannot load portfolio.") + "\n\n" + qsTr("Check if you have portfolio selected.") + "\n" + qsTr("Create one on Google if you don't have any."), 1);
            errorState.state = "promotePfo";
        }
        else {
            for (var i=0; i<limitLength(posLength); i++) {
                // (thisModel, name, exg, share, cost, comm, num, type, dirty) {
                addPosEditModel(thisModel,
                    data.childNodes[10+i].childNodes[7].attributes[2].nodeValue,
                    data.childNodes[10+i].childNodes[7].attributes[0].nodeValue,
                    data.childNodes[10+i].childNodes[6].attributes[9].nodeValue,
                    0,
                    0,
                    0,
                    "",
                    0
                );
                /*
                thisModel.append({
                    "name":      data.childNodes[10+i].childNodes[7].attributes[2].nodeValue,
                    "exchange":  data.childNodes[10+i].childNodes[7].attributes[0].nodeValue,
                    "share":     data.childNodes[10+i].childNodes[6].attributes[9].nodeValue,
                    "shareCost": "-",

                    "shareDayGain": 0,      // Overloaded to store shareComm.
                    "shareGain": 0,         // Overloaded to store shareNum.
                    "shareGainPercent": "", // Overloaded to store shareType.
                    "fullname": 0           // Overloaded to store dirty flag.
                });
        */

                if (data.childNodes[10+i].childNodes[6].childNodes.length==4) {
                    thisModel.setProperty(i, "shareCost", fileHandler.formatNumber(data.childNodes[10+i].childNodes[6].childNodes[0].firstChild.attributes[0].nodeValue));
                }
            } // for

    //}catch(err) {
    //    addError("Error: " + err);
    //}
            waiting.state = "hidden";
        }
}


// Only load portfolio data from jsobObj.
function updateTimerQuotes (pfoIsYahoo, pfoLocal) {
    if (!pfoIsYahoo) { loadAllQuotes(quoteListGoogle, pfoLocal); }
    loadYahooQuote(quoteListYahoo, pfoIsYahoo);
}

// Parse Yahoo feed
function parseCSV(data, isYahooQuote) {
//    console.log(data);
    var csvArray = fileHandler.parseCSV(data);
    //console.log(csvArray);
    //console.log("isYahoo="+isYahooQuote+"");

    // Array[count*i+j]
    //var csvObj = CSVToArray(data);

//    if ( csvArray.length != ( pModel.count*2 ))  {
//        console.log("yahoo feed info not shown: " + csvArray.length + ":" + pModel.count);
//        waiting.state = "hidden";
//        return;
//    }
//    else {
        // b2, b3: ask, bid (real-time)
        if (!isYahooQuote) {
            if ( csvArray.length != ( pModel.count*4 ))  {
                console.log("yahoo feed info not shown: " + csvArray.length + ":" + pModel.count);
                waiting.state = "hidden";
                return;
            }
            else {
                for (var i=0; i<limitLength(pModel.count); i++) {
                    var offset = 4;
                    //console.log( i +":(Ask,Bid) = "+csvArray[2*i+0] + "/" + csvArray[2*i+1]);
                    //console.log( i +":(Div,Yld) = "+csvArray[2*i+2] + "/" + csvArray[2*i+3]);
                    pModel.set(i, {
                               "quoteAsk": (csvArray[offset*i+0]=="N/A"||csvArray[offset*i+0]=="") ? "-" : csvArray[offset*i+0],
                               "quoteBid": (csvArray[offset*i+1]=="N/A"||csvArray[offset*i+1]=="") ? "-" : csvArray[offset*i+1],
                               "quoteDiv": (csvArray[offset*i+2]=="N/A") ? "-" : csvArray[offset*i+2],
                               "quoteYld": (csvArray[offset*i+3]=="N/A") ? "-" : csvArray[offset*i+3]
                    });
                }
            }
        }
        /*
        // b2, b3: ask, bid (real-time)
        // g,h,j,k (day lo, day hi, 52w lo 52w hi)
        // c6: change, k2: change percentage
        // l1: last trade price
        // j3: market cap
        // a2: avg volume (3m), v: volume (real-time)
        // r2: PE (real-time), r: PE
        // e7: EPS Estimate Current Year
        // x: stock exchange
        // n: name
        //itemsURL =   "http://download.finance.yahoo.com/d/quotes.csv?s="+ quoteList + "&f=b2b3ghjkc6k2l1j3a2vr2e7xn";
        else {
             for (var i=0; i<pModel.count; i=i+1) {
                 var offset = 18;
                 //var change = csvObj[i][7];
                 var change = csvArray[offset*i+6];
                 var changePtg = csvArray[offset*i+7];

                 var quoteChgColor;

                 if (change.indexOf("+")==0) {
                     quoteChgColor = (quoteChgColorMode) ? "red" : n9Green;
                 }
                 else {
                     quoteChgColor = (quoteChgColorMode) ? n9Green : "red";
                 }

                 // Split change percentage
                 changePtg = changePtg.split(" - ");
                 changePtg[1] = changePtg[1].substr(0, changePtg[1].indexOf("%"));

                 // C function to compute value, gain, day-gain, and gain percentage.
                 var perfData = "";

                 if (csvArray[offset*i+8]!="N/A") {
                     perfData = fileHandler.calcUniSymPerf(i, csvArray[offset*i+8]);
                 }
                 else {
                     perfData[0] = perfData[1] = perfData[2] = perfData[3] = "-";
                 }

                 if (pModel.count==0) {
                        pModel.append({
                             //"id": "-",
                             "exchange":   (csvArray[offset*i+14]=="N/A") ? "-" : csvArray[offset*i+14],
                             "fullName":   (csvArray[offset*i+15]=="N/A") ? "-" : csvArray[offset*i+15],
                             "name":         fileHandler.localUniSymbol[i],
                             "share":        fileHandler.localUniShare[i],
                             "shareGain":    perfData[0],
                             "shareCost":    perfData[1],
                             "shareDayGain": "-",
                             "shareValue":   perfData[2],
                             "shareGainPercent": perfData[3],

                             "quoteAsk":   (csvArray[offset*i+0]=="N/A") ? "-" : csvArray[offset*i+0],
                             "quoteBid":   (csvArray[offset*i+1]=="N/A") ? "-" : csvArray[offset*i+1],
                             "quotePrice": (csvArray[offset*i+8]=="N/A") ? "-" : csvArray[offset*i+8],
                             "quoteChgColor": quoteChgColor,

                             "quoteChg":   (change=="N/A") ? "-" : change,
                             "quoteChgPtg":(changePtg[1]=="N/A") ? "-" : changePtg[1],
                             "quoteVol":   (csvArray[offset*i+11]=="N/A") ? "-" : csvArray[offset*i+11],
                             "quoteAvgVol":(csvArray[offset*i+10]=="N/A") ? "-" : csvArray[offset*i+10],
                             "quoteMktCap":(csvArray[offset*i+9]=="N/A") ? "-" : csvArray[offset*i+9],
                             "quoteDayHi": (csvArray[offset*i+3]=="N/A") ? "-" : csvArray[offset*i+3],
                             "quoteDayLo": (csvArray[offset*i+2]=="N/A") ? "-" : csvArray[offset*i+2],
                             "quote52wHi": (csvArray[offset*i+5]=="N/A") ? "-" : csvArray[offset*i+5],
                             "quote52wLo": (csvArray[offset*i+4]=="N/A") ? "-" : csvArray[offset*i+4],
                             "quoteEps":   (csvArray[offset*i+13]=="N/A") ? "-" : csvArray[offset*i+13],
                             "quoteBeta":   "-",
                             "quotePe":    (csvArray[offset*i+12]=="N/A") ? "-" : csvArray[offset*i+12],
                             "quoteType":   "-",
                             "quoteDiv":   (csvArray[offset*i+16]=="N/A") ? "-" : csvArray[2*i+16],
                             "quoteYld":   (csvArray[offset*i+17]=="N/A") ? "-" : csvArray[2*i+17],
                             "afterPrice":     "-",
                             "afterChg":       "-",
                             "afterChgPtg":    "-",
                             "afterChgColor":  n9Green
                        });
                 }
                 else {
                     pModel.set(i, {
                                "exchange":   (csvArray[offset*i+14]=="N/A") ? "-" : csvArray[offset*i+14],
                                "fullName":   (csvArray[offset*i+15]=="N/A") ? "-" : csvArray[offset*i+15],
                                "name":         fileHandler.localUniSymbol[i],
                                "share":        fileHandler.localUniShare[i],
                                "shareGain":    0,
                                "shareCost":    fileHandler.localPosCost[i],
                                "shareDayGain": 0,
                                "shareValue":   0,
                                "shareGainPercent": 0,

                                "quoteAsk":   (csvArray[offset*i+0]=="N/A") ? "-" : csvArray[offset*i+0],
                                "quoteBid":   (csvArray[offset*i+1]=="N/A") ? "-" : csvArray[offset*i+1],
                                "quotePrice": (csvArray[offset*i+8]=="N/A") ? "-" : csvArray[offset*i+8],
                                "quoteChgColor": quoteChgColor,

                                "quoteChg":   (change=="N/A") ? "-" : change,
                                "quoteChgPtg":(changePtg[1]=="N/A") ? "-" : changePtg[1],
                                "quoteVol":   (csvArray[offset*i+11]=="N/A") ? "-" : csvArray[offset*i+11],
                                "quoteAvgVol":(csvArray[offset*i+10]=="N/A") ? "-" : csvArray[offset*i+10],
                                "quoteMktCap":(csvArray[offset*i+9]=="N/A") ? "-" : csvArray[offset*i+9],
                                "quoteDayHi": (csvArray[offset*i+3]=="N/A") ? "-" : csvArray[offset*i+3],
                                "quoteDayLo": (csvArray[offset*i+2]=="N/A") ? "-" : csvArray[offset*i+2],
                                "quote52wHi": (csvArray[offset*i+5]=="N/A") ? "-" : csvArray[offset*i+5],
                                "quote52wLo": (csvArray[offset*i+4]=="N/A") ? "-" : csvArray[offset*i+4],
                                "quoteEps":   (csvArray[offset*i+13]=="N/A") ? "-" : csvArray[offset*i+13],
                                "quoteBeta":   "-",
                                "quotePe":    (csvArray[offset*i+12]=="N/A") ? "-" : csvArray[offset*i+12],
                                "quoteType":   "-",
                                "quoteDiv": (csvArray[2*i+16]=="N/A") ? "-" : csvArray[2*i+16],
                                "quoteYld": (csvArray[2*i+17]=="N/A") ? "-" : csvArray[2*i+17],
                                "afterPrice":     "-",
                                "afterChg":       "-",
                                "afterChgPtg":    "-",
                                "afterChgColor":  n9Green
                     });
                 }
             }
        }
        */

//    }
        waiting.state = "hidden";
}

function parseJSON(data, idx) {
    // Remove comment // at the beginning
    //data = data.replace(/\/\//, "");
    data = removeComment(data);
    //console.log(data);

    // eval is unsafe, but JSON.parse is prone to fail
    var jsonObj = eval("(" + data + ")");
    //var jsonObj = JSON.parse(data);

    if (jsonObj==null || typeof(jsonObj)==undefined) {
        waiting.state = "hidden";
        return;
    }

    var quoteChgColor;
    if (jsonObj[0].c.indexOf("-")==0) {
        quoteChgColor = (quoteChgColorMode) ? n9Green : "red";
    }
    else {
        quoteChgColor = (quoteChgColorMode) ? "red" : n9Green;
    }

    // aftermarket info might not present
    var afterprice       = (jsonObj[i].el  !=null && jsonObj[i].el  !== null) ? jsonObj[i].el  : "-";
    var afterpriceChg    = (jsonObj[i].ec  !=null && jsonObj[i].ec  !== null) ? jsonObj[i].ec  : "-";
    var afterpriceChgPtg = (jsonObj[i].ecp !=null && jsonObj[i].ecp !== null) ? jsonObj[i].ecp : "-";

    var afterChgColor = n9Green;
    if (jsonObj[i].el != null && jsonObj[i].el !== null) {
        if (afterpriceChg.indexOf("-")==0)
            afterChgColor = (quoteChgColorMode) ? n9Green : "red";
        else
            afterChgColor = (quoteChgColorMode) ? "red" : n9Green;
    }

    // Check if entry already exists, if not append, if yes set.
    // Use set method to avoid flickering when updating content by timer
    //if (idx<pModel.count) {

        pModel.set(idx, {
                     "exchange":       (jsonObj[0].e   =="") ? "-" : jsonObj[0].e   ,    //symObj.symExg,
                     "fullName":       (jsonObj[0].name=="") ? "-" : jsonObj[0].name, //symObj.symFullName,
                     "name":           (jsonObj[0].t   =="") ? "-" : jsonObj[0].t   ,    //symObj.symName,
                     "quotePrice":     (jsonObj[0].l   =="") ? "-" : jsonObj[0].l   ,
                     "quoteChgColor":  (quoteChgColor  =="") ? "-" : quoteChgColor  ,
                     "quoteChg":       (jsonObj[0].c   =="") ? "-" : jsonObj[0].c   ,
                     "quoteChgPtg":    (jsonObj[0].cp  =="") ? "-" : jsonObj[0].cp  ,
                     "quoteVol":       (jsonObj[0].vo  =="") ? "-" : jsonObj[0].vo  ,
                     "quoteAvgVol":    (jsonObj[0].avvo=="") ? "-" : jsonObj[0].avvo,
                     "quoteMktCap":    (jsonObj[0].mc  =="") ? "-" : jsonObj[0].mc  ,
                     "quoteDayHi":     (jsonObj[0].hi  =="") ? "-" : jsonObj[0].hi  ,
                     "quoteDayLo":     (jsonObj[0].lo  =="") ? "-" : jsonObj[0].lo  ,
                     "quote52wHi":     (jsonObj[0].hi52=="") ? "-" : jsonObj[0].hi52,
                     "quote52wLo":     (jsonObj[0].lo52=="") ? "-" : jsonObj[0].lo52,
                     "quoteEps":       (jsonObj[0].eps =="") ? "-" : jsonObj[0].eps ,
                     "quoteBeta":      (jsonObj[0].beta=="") ? "-" : jsonObj[0].beta,
                     "quotePe":        (jsonObj[0].pe  =="") ? "-" : jsonObj[0].pe  ,
                     "quoteType":      (jsonObj[0].type=="") ? "-" : jsonObj[0].type,
                     "afterPrice":     afterprice,
                     "afterChg":       afterpriceChg,
                     "afterChgPtg":    afterpriceChgPtg,
                     "afterChgColor":  afterChgColor

        });
    //}

    waiting.state = "hidden";
}

function parseJSONAll(data, pfoLocal) {
    // Remove comment // at the beginning
    data = removeComment(data);
    //console.log(data);

    // eval is unsafe, but JSON.parse is prone to fail
    var jsonObj = eval("(" + data + ")");
    //var jsonObj = JSON.parse(data);

    // Model is updated slower
    //console.log("m.cnt=" + model.count + " j.cnt=" + jsonObj.length);
    if (jsonObj==null || typeof(jsonObj)==undefined) {
        waiting.state = "hidden";
        return;
    }

    fileHandler.clearPfoPerf();

    for (var i=0; i<limitLength(jsonObj.length); i++) {
        /*
          avvo    * Average volume (float with multiplier, like '3.54M')
          beta    * Beta (float)
          c       * Amount of change while open (float)
          ccol    * (unknown) (chars)
          cl        Last perc. change
          cp      * Change perc. while open (float)
          e       * Exchange (text, like 'NASDAQ')
          ec      * After hours last change from close (float)
          eccol   * (unknown) (chars)
          ecp     * After hours last chage perc. from close (float)
          el      * After. hours last quote (float)
          el_cur  * (unknown) (float)
          elt       After hours last quote time (unknown)
          eo      * Exchange Open (0 or 1)
          eps     * Earnings per share (float)
          fwpe      Forward PE ratio (float)
          hi      * Price high (float)
          hi52    * 52 weeks high (float)
          id      * Company id (identifying number)
          l       * Last value while open (float)
          l_cur   * Last value at close (like 'l')
          lo      * Price low (float)
          lo52    * 52 weeks low (float)
          lt        Last value date/time
          ltt       Last trade time (Same as "lt" without the data)
          mc      * Market cap. (float with multiplier, like '123.45B')
          name    * Company name (text)
          op      * Open price (float)
          pe      * PE ratio (float)
          t       * Ticker (text)
          type    * Type (i.e. 'Company')
          vo      * Volume (float with multiplier, like '3.54M')
          div     * Dividend
          yld     * Yield
        */

        var listprice       = (jsonObj[i].l  == "") ? "-" : jsonObj[i].l;
        var listpriceChg    = (jsonObj[i].c  == "") ? "-" : jsonObj[i].c;
        var listpriceChgPtg = (jsonObj[i].cp == "") ? "-" : jsonObj[i].cp;

        var quoteChgColor;
        if (listpriceChg.indexOf("-")==0)
            quoteChgColor = (quoteChgColorMode) ? n9Green : "red";
        else
            quoteChgColor = (quoteChgColorMode) ? "red" : n9Green;

        // aftermarket info might not present
        var afterprice       = (jsonObj[i].el  !=null && jsonObj[i].el  !== null) ? jsonObj[i].el  : "-";
        var afterpriceChg    = (jsonObj[i].ec  !=null && jsonObj[i].ec  !== null) ? jsonObj[i].ec  : "-";
        var afterpriceChgPtg = (jsonObj[i].ecp !=null && jsonObj[i].ecp !== null) ? jsonObj[i].ecp : "-";

        var afterChgColor = n9Green;
        if (jsonObj[i].el != null && jsonObj[i].el !== null) {
            if (afterpriceChg.indexOf("-")==0)
                afterChgColor = (quoteChgColorMode) ? n9Green : "red";
            else
                afterChgColor = (quoteChgColorMode) ? "red" : n9Green;
        }

        // Javscript undeclared
        // Swap to after-hour's data if exists.
//        if (jsonObj[i].el != null && jsonObj[i].el !== null) {
//            listprice       = jsonObj[i].el  ;
//            listpriceChg    = jsonObj[i].ec  ;
//            listpriceChgPtg = jsonObj[i].ecp ;
//        }

        pModel.set(i, {
                     "exchange":       (jsonObj[i].e   =="") ? "-" : jsonObj[i].e   ,    //symObj.symExg,
                     "fullName":       (jsonObj[i].name=="") ? "-" : jsonObj[i].name,    //symObj.symFullName,
                     "name":           (jsonObj[i].t   =="") ? "-" : jsonObj[i].t   ,    //symObj.symName,
                     "quotePrice":     listprice,       //(jsonObj[i].l   =="") ? "-" : jsonObj[i].l   ,
                     "quoteChg":       listpriceChg,    //(jsonObj[i].c   =="") ? "-" : jsonObj[i].c   ,
                     "quoteChgPtg":    listpriceChgPtg, //(jsonObj[i].cp  =="") ? "-" : jsonObj[i].cp  ,
                     "quoteChgColor":  quoteChgColor,
                     "quoteVol":       (jsonObj[i].vo  =="") ? "-" : jsonObj[i].vo  ,
                     "quoteAvgVol":    (jsonObj[i].avvo=="") ? "-" : jsonObj[i].avvo,
                     "quoteMktCap":    (jsonObj[i].mc  =="") ? "-" : jsonObj[i].mc  ,
                     "quoteDayHi":     (jsonObj[i].hi  =="") ? "-" : jsonObj[i].hi  ,
                     "quoteDayLo":     (jsonObj[i].lo  =="") ? "-" : jsonObj[i].lo  ,
                     "quote52wHi":     (jsonObj[i].hi52=="") ? "-" : jsonObj[i].hi52,
                     "quote52wLo":     (jsonObj[i].lo52=="") ? "-" : jsonObj[i].lo52,
                     "quoteEps":       (jsonObj[i].eps =="") ? "-" : jsonObj[i].eps ,
                     "quoteBeta":      (jsonObj[i].beta=="") ? "-" : jsonObj[i].beta,
                     "quotePe":        (jsonObj[i].pe  =="") ? "-" : jsonObj[i].pe  ,
                     "quoteType":      (jsonObj[i].type=="") ? "-" : jsonObj[i].type,
                     "afterPrice":     afterprice,
                     "afterChg":       afterpriceChg,
                     "afterChgPtg":    afterpriceChgPtg,
                     "afterChgColor":  afterChgColor
        });

        // Update performance data for local Google Portfolio
        if (pfoLocal) {
            if (jsonObj[i].l != "") {
                var perfData = "";

                // Remove the comma in numbers
                var price = jsonObj[i].l;
                price = price.replace(",", "");

                // Calculate each position's data
                // js is horrible dealing with floating point, so don't do the accumulation in js.
                // perfData is QStringList
                perfData = fileHandler.calcUniSymPerf(i, 100*price)
//                console.log("i=" + i + " price=" + price + " perData:" + perfData[0] + " " + perfData[1] + " " + perfData[2]);

                var symObj = {
                    "symShare": jRound(fileHandler.localUniShare[i]),
                    "shareCost": perfData[1],
                    "shareDayGain": "-",
                    "shareGain": perfData[0],
                    "shareValue": perfData[2],
                    "shareGainPercent": perfData[3]
                };

                loadQuoteHeader(symObj, i);
            }
        }
    }

    // TODO: Does not work when google portfolio is enabled due to activePos pointing to local portfolio only.
    // When bypass Google login is enabled, pfoModel might be still loading when Google login is enabled.
    // Need user's input to determine the correct activePos due to network delay in loading Google portfolio.
    if (pfoLocal) {
//        console.log("fh.activePos=" + fileHandler.localPos + " mdl.count=" + model.count);
        if ((fileHandler.localPos>=0) && (fileHandler.localPos<model.count)) {
//            console.log(" DBG.(gain, cost, value)=" + fileHandler.localPfoGain + " " +
//                        fileHandler.localPfoCost + " " +
//                        fileHandler.localPfoValue);
            model.set(fileHandler.localPos, {
                         "gain" : fileHandler.localPfoGain,
                         "value": fileHandler.localPfoValue,
                         "cost":  fileHandler.localPfoCost
            });
        }
    }

//    waiting.state = "hidden";
    waiting.state = "posDone";
}

function parseJSONAllModel(data, mdl) {
    // Remove comment // at the beginning
    //data = data.replace(/\/\//, "");
    data = removeComment(data);
    //console.log(data);

    // eval is unsafe, but JSON.parse is prone to fail
    var jsonObj = eval("(" + data + ")");
    //var jsonObj = JSON.parse(data);

    // Model is updated slower
    //console.log("m.cnt=" + model.count + " j.cnt=" + jsonObj.length);
    if (jsonObj==null || typeof(jsonObj)==undefined) {
        waiting.state = "hidden";
        return;
    }

    for (var i=0; i<jsonObj.length; i++) {
        var quoteChgColor;
        //var chgSymbol = jsonObj[0].c.match(/^\-/);
        if (jsonObj[i].c.indexOf("-")==0) { //chgSymbol != null) {
            quoteChgColor = (quoteChgColorMode) ? n9Green : "red";
        }
        else {
            quoteChgColor = (quoteChgColorMode) ? "red" : n9Green;
        }

        if (i < mdl.model.count) {
            mdl.model.set(i, {
                     "name":           (jsonObj[i].t   =="") ? "-" :
                                        convertSymbolName(jsonObj[i].t, jsonObj[i].e, jsonObj[i].name),
                     "quotePrice":     (jsonObj[i].l   =="") ? "-" : jsonObj[i].l   ,
                     "quoteChgColor":  (quoteChgColor  =="") ? "-" : quoteChgColor  ,
                     "quoteChg":       (jsonObj[i].c   =="") ? "-" : jsonObj[i].c   ,
                     "quoteChgPtg":    (jsonObj[i].cp  =="") ? "-" : jsonObj[i].cp  ,
                     "type": "s"
            });
        }
        else {
            mdl.model.append({
                     "name":           (jsonObj[i].t   =="") ? "-" :
                                        convertSymbolName(jsonObj[i].t, jsonObj[i].e, jsonObj[i].name),
                     "quotePrice":     (jsonObj[i].l   =="") ? "-" : jsonObj[i].l   ,
                     "quoteChgColor":  (quoteChgColor  =="") ? "-" : quoteChgColor  ,
                     "quoteChg":       (jsonObj[i].c   =="") ? "-" : jsonObj[i].c   ,
                     "quoteChgPtg":    (jsonObj[i].cp  =="") ? "-" : jsonObj[i].cp  ,
                     "type": "s"
            });
        }
    }

    // Load Currencies and Bonds
    loadGoogleExtra(mdl);
}

function convertSymbolName(sym, exg, fullname) {
    if (exg=="INDEXDJX" && sym==".DJI")          { return "Dow Jones"; }
    else if (exg=="INDEXSP" && sym==".INX")      { return "S&P 500"; }
    else if (exg=="INDEXNASDAQ" && sym==".IXIC") { return "NASDAQ"; }
    else if (exg=="SHA" && sym=="000001")        { return "Shanghai"; }
    else if (exg=="INDEXNIKKEI" && sym=="NI225") { return "Nikkei 225"; }
    else if (exg=="INDEXHANGSENG" && sym=="HSI") { return "Hang Seng"; }
    else if (exg=="TPE" && sym=="TAIEX")         { return "TSEC"; }
    else if (exg=="INDEXFTSE" && sym=="UKX")     { return "FTSE 100"; }
    else if (exg=="INDEXSTOXX" && sym=="SX5E")   { return "EU STOXX 50"; }
    else if (exg=="INDEXEURO" && sym=="PX1")     { return "CAC 40"; }
    else if (exg=="TSE" && sym=="OSPTX")         { return "S&P TSX"; }
    else if (exg=="INDEXASX" && sym=="XJO")      { return "S&P/ASX 200"; }
    else if (exg=="INDEXBOM" && sym=="SENSEX")   { return "BSE Sensex"; }
    else if (exg=="INDEXDB" && sym=="DAX")       { return "DAX"; }
    else { return fullname; }
}

//////////////////////////////////////
// Misc
//////////////////////////////////////
function addPosEditModel(thisModel, name, exg, share, cost, comm, num, type, dirty) {
   thisModel.append({
         "name":         name,
         "exchange":     exg,
         "share":        share,
         "shareCost":    cost,
         "shareDayGain": comm,
         "shareGain":    num,        // Overloaded to store shareNum.
         "shareGainPercent": type,     // Overloaded to store shareType.
         "fullname":     dirty,      // Overloaded to store dirty flag.
         "shareValue":   "",           "quotePrice":     "",
         "quoteChg":       "",         "quoteChgPtg":    "",
         "quoteVol":       "",         "quoteAvgVol":    "",
         "quoteMktCap":    "",         "quoteDayHi":     "",
         "quoteDayLo":     "",         "quote52wHi":     "",
         "quote52wLo":     "",         "quoteEps":       "",
         "quoteBeta":      "",         "quotePe":        "",
         "quoteType":      "",         "quoteAsk":       "",
         "quoteBid":       "",         "quoteDiv":       "",
         "quoteYld":       "",         "afterPrice":     "",
         "afterChg":       "",         "afterChgPtg":    "",
         "quoteChgColor":  "black",
         "afterChgColor":  "black"
   });
}

function limitLength(cnt) {
    return cnt;
//    var pLength;
//    var limit = 18;

//    if (fileHandler.plus)
//        pLength = cnt;
//    else
//        pLength = (cnt>limit) ? limit : cnt;

//    return pLength;
}

// Yahoo return 0 for ask/bid for non-North American exchange
function convertExchangeForYahoo (name, exg) {
    if (name.indexOf(".")==0)
        return name.replace(".", "^");

    //console.log(name + exg);
    if (exg=="OTC")                   { return (name + "." + "OB"); }
    else if (exg=="TSXV")             { return (name + "." + "V");  }
    else if (exg=="TSX")              { return (name + "." + "TO"); }
    // Europe
    else if (exg=="LON")              { return (name + "." + "L"); }
    else if (exg=="FRA")              { return (name + "." + "F"); }  // Frankfurt
    else if (exg=="ETR")              { return (name + "." + "DE"); } // XETRA
    else if (exg=="BIT")              { return (name + "." + "MI"); } // Milan
    // Australia
    else if (exg=="ASX")              { return (name + "." + "AX"); }
    // Asian
    else if (exg=="TPE")              { return (name + "." + "TW"); }
    else if (exg=="HKG")              { return (name + "." + "HK"); }
    else if (exg=="SHA")              { return (name + "." + "SS"); }
    else if (exg=="SHE")              { return (name + "." + "SZ"); }
    else if (exg=="SEO")              { return (name + "." + "KS"); }
    else if (exg=="JAK")              { return (name + "." + "JK"); }
    // Misc
    else if (exg=="PINK")             { return (name + "." + "PK"); }
    else                              { return name; }
}

//function getNode(node, name) {
//    for(var i=0; i<node.childNodes.length; i++) {
//        var nodeName = node.childNodes[i].nodeName;
//        if(nodeName==name) {
//            return node.childNodes[i].firstChild;
//        }
//    }

//    return node;
//}

function removeComment(data) {
    data = data.replace(/\/\//, "");
    return data;
}

// function from http://forums.devshed.com/t39065/s84ded709f924610aa44fff827511aba3.html
// author appears to be Robert Pollard
function sprintf()
{
   if (!arguments || arguments.length < 1 || !RegExp)
   {
      return;
   }
   var str = arguments[0];
   var re = /([^%]*)%('.|0|\x20)?(-)?(\d+)?(\.\d+)?(%|b|c|d|u|f|o|s|x|X)(.*)/;
   var a = [];
   var b = [];
   var numSubstitutions = 0;
   var numMatches = 0;
   while (a = re.exec(str))
   {
      var leftpart = a[1], pPad = a[2], pJustify = a[3], pMinLength = a[4];
      var pPrecision = a[5], pType = a[6], rightPart = a[7];

      numMatches++;
      if (pType == '%')
      {
         subst = '%';
      }
      else
      {
         numSubstitutions++;
         if (numSubstitutions >= arguments.length)
         {
            alert('Error! Not enough function arguments (' + (arguments.length - 1)
               + ', excluding the string)\n'
               + 'for the number of substitution parameters in string ('
               + numSubstitutions + ' so far).');
         }
         var param = arguments[numSubstitutions];
         var pad = '';
                if (pPad && pPad.substr(0,1) == "'") pad = leftpart.substr(1,1);
           else if (pPad) pad = pPad;
         var justifyRight = true;
                if (pJustify && pJustify === "-") justifyRight = false;
         var minLength = -1;
                if (pMinLength) minLength = parseInt(pMinLength);
         var precision = -1;
                if (pPrecision && pType == 'f')
                   precision = parseInt(pPrecision.substring(1));
         var subst = param;
         switch (pType)
         {
         case 'b':
            subst = parseInt(param).toString(2);
            break;
         case 'c':
            subst = String.fromCharCode(parseInt(param));
            break;
         case 'd':
            subst = parseInt(param) ? parseInt(param) : 0;
            break;
         case 'u':
            subst = Math.abs(param);
            break;
         case 'f':
            subst = (precision > -1)
             ? Math.round(parseFloat(param) * Math.pow(10, precision))
              / Math.pow(10, precision)
             : parseFloat(param);
            break;
         case 'o':
            subst = parseInt(param).toString(8);
            break;
         case 's':
            subst = param;
            break;
         case 'x':
            subst = ('' + parseInt(param).toString(16)).toLowerCase();
            break;
         case 'X':
            subst = ('' + parseInt(param).toString(16)).toUpperCase();
            break;
         }
         var padLeft = minLength - subst.toString().length;
         if (padLeft > 0)
         {
            var arrTmp = new Array(padLeft+1);
            var padding = arrTmp.join(pad?pad:" ");
         }
         else
         {
            var padding = "";
         }
      }
      str = leftpart + padding + subst + rightPart;
   }
   return str;
}

function jRound(val) {
    return Math.round(val*100)/100;
}
