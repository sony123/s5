.pragma library

function revTxt() {
    return "Rev 2.1"
}

function generalTxt() {
    var str;
    str  = qsTr("The app fetches portfolios you created on Google Finance, ");
    str += qsTr("so please set up your Google account info in the Settings menu. ");
    str += qsTr("Alternatively, it loads the portfolios you create on device. ");
//    str += qsTr("Please see the next section on the how-to for local portfolio creation.") + "\n";
//    str += qsTr("There are three types of views for position info:") + "\n";
//    str += qsTr("1) Standard: Price + range/bid info.") + "\n";
//    str += qsTr("2) Portfolio: Price + portfolio gain info.") + "\n";
//    str += qsTr("3) Widget: Price info only.") + "\n\n";
//    str += qsTr("The view can be toggled on the fly from the left-most button on the toolbar. ");
    str += qsTr("Press the 'stockona' text in the middle of toolbar to manually update quote data.") + "\n";
    str += qsTr("Clicking entries in 'Related Symbols' prompts you to save that particular symbol into local portfolio.") + "\n\n";

    return str;
}

function localPfoTxt() {
    var str;

    str  = qsTr("Stockona loads locally-created portfolio and your Google Finance portfolios (if 'Bypass Google Login' is not enabled). ");
    str += qsTr("To create/edit local portfolio, following these steps:") + "\n";
    str += qsTr("1) In portfolio view, click the edit button to activate edit mode. ");
    str += qsTr("Header becomes orange-colored to indicate you are in edit mode.") + "\n";
    str += qsTr("2) There are three views in editing mode, portfolio/position/transaction, ");
    str += qsTr("each is accessible by single-clicking an item in the list.") + "\n";
    str += qsTr("3) To create new portfolio/transactions, click '+' button on toolbar.") + "\n";
    str += qsTr("4) To delete a portfolio/position/transaction, click 'X' on the right side of each item. ");
    str += qsTr("To edit a transaction, single-click on it. ");
    str += qsTr("To edit a portfolio's name/description, press-and-hold on it to invoke the edit sheet.") + "\n\n";

    str += qsTr("You can add symbol to your Google portfolio directly within Stockona. ");
    str += qsTr("Performance data are not synced due to API issue. ");
    str += qsTr("Adding symbol to Google portfolio is done the same way as in local portfolio, by clicking the '+' button to invoke the edit sheet. ");
    str += qsTr("But in Google Finance portfolio, you need to click the 'v' button to sync the newly-added symbol to Google Finance.") + "\n\n";

    str += qsTr("Please note if you manually enter the symbol/exchange data you enter in the edit sheet, ");
    str += qsTr("the info must be exactly the same as they are on Google Finance, ");
    str += qsTr("e.g. for Google, its Google Finance symbol is (symbol, exchange)= (GOOG, NASDAQ). ");
    str += qsTr("In case you don't know the exact symbol, use the 'Search' button in the edit sheet for a list of suggestions. ") + "\n\n";

    str += qsTr("There is also a search button on the toolbar in the portfolio view. ");
    str += qsTr("It serves as a shortcut to quickly add a symbol to one of you local portfolio.") + "\n\n";;

    return str;
}

function syncTxt() {
    var str;

    str  = qsTr("* Please note that Google have shut down Finance API. ");
    str += qsTr("This means syncing (and Google login) can stop working anytime without notice.") + "\n\n";

    str += qsTr("Syncing can be done both-way, from Google Finance to local portfolio and vice versa. ");
    str += qsTr("Reliable internet connection is strongly recommended when syncing.") + " \n\n";

    str += qsTr("To sync your locally-created portfolio to Google Finance, ");
    str += qsTr("first make sure all symbols have exchange info. ");
    str += qsTr("Empty exchange field causes syncing to fail. ");
    str += qsTr("Also make sure you don't edit the portfolio at the same time on other devices. ");
    str += qsTr("After that click the extended menu option icon on the right of the toolbar in portfolio edit view ");
    str += qsTr("then select 'Sync to Google.'") + " \n\n";

    str += qsTr("To sync Google Finance portfolio to Stockona, ");
    str += qsTr("first select a Google portfolio then click it to enter position view. ");
    str += qsTr("Then, click the extended menu option icon on the right of the toolbar and ");
    str += qsTr("select 'Save to local'.") + " \n\n";

    str += qsTr("Syncing can take a little while depending on the number of symbols, so patient is advised.") + "\n\n";
    str += qsTr("If you experience any issue, please report any issue to stockona@ovi.com") + "\n\n";

    str += qsTr("Stockona can also import portfolio from Google portfolio exported csv files.");
    str += qsTr("Put the csv file under the E: for Symbian and /home/user/MyDocs for Harmattan , then in portfolio view click menu button and select 'Import Portfolio'.") + "\n\n";;

    return str;
}

function mktOverviewTxt() {
    var str;
    str =  qsTr("'Market Overview' gives users a quick glance about the market. ");
    str += qsTr("There are two views. One of them shows major indexes, and 'Market News' view displays news feed from Google News business section.");
    str += qsTr("For paid version, currencies and bond information are also displayed in the index view. ");
    str += qsTr("Click the view button on the right of the toolbar to switch between the two views.");
    str += qsTr("For the index view, you can customize the indexes shown in the Settings menu.");
    str += qsTr("For the news view, you can select the news feed region, e.g. US, Australia, etc, ");
    str += qsTr("by clicking the header bar where 'Market News' is displayed. ");
    str += qsTr("The choosen region is automatically saved as presetting. ");
    str += qsTr("Please note this setting is independent from the 'Related news' for a symbol. ");
    str += qsTr("'Related news' always fetches US news feed. ");

    return str;
}
