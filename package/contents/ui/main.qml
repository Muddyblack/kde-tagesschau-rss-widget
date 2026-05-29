import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    // Tooltip information
    toolTipMainText: {
        var feed = getActiveFeed();
        return feed.name + (feed.type === "finance" ? " Board" : " Ticker");
    }
    toolTipSubText: {
        var lines = [];
        var feed = getActiveFeed();
        if (feed.type === "finance") {
            lines.push(i18n("Real-time stock & crypto prices."));
        } else if (root.hasEilmeldung) {
            lines.push(i18n("🚨 BREAKING NEWS!"));
            if (root.latestEilmeldungTitle) {
                lines.push(root.latestEilmeldungTitle);
            }
        } else {
            lines.push(i18n("Latest news from the feed."));
        }
        if (root.errorMsg) {
            lines.push("⚠ " + root.errorMsg);
        } else if (root.feedLastUpdates[root.currentFeedIndex]) {
            lines.push(i18n("Last updated: ") + root.feedLastUpdates[root.currentFeedIndex]);
        }
        return lines.join("\n");
    }

    // State
    property var newsStories: []
    property string activeRessort: "alle"
    property bool hasEilmeldung: false
    property string latestEilmeldungTitle: ""
    property string errorMsg: ""
    property var feedLastUpdates: ({})
    property bool isLoading: false

    // Config bindings
    property var feedList: {
        try {
            return JSON.parse(plasmoid.configuration.feedsJson);
        } catch (e) {
            return [
                {
                    "name": "Tagesschau",
                    "type": "json-tagesschau",
                    "url": "https://www.tagesschau.de/api2u/homepage"
                },
                {
                    "name": "Märkte",
                    "type": "finance",
                    "url": "finance-board",
                    "symbols": "^GDAXI,^DJI,^IXIC,EURUSD=X,BTC-USD,ETH-USD,AIR.PA,RHM.DE,TSM,NVDA,ASML,AMD"
                }
            ];
        }
    }
    property int currentFeedIndex: {
        var idx = plasmoid.configuration.currentFeedIndex;
        if (idx < 0 || idx >= feedList.length)
            return 0;
        return idx;
    }

    // Colors
    readonly property color tagesschauBlue: "#00305e"
    readonly property color tagesschauLightBlue: "#005ca9"
    readonly property color breakingRed: "#ff3333"
    readonly property color glassyBg: Qt.rgba(0.08, 0.08, 0.1, 0.82)
    readonly property color borderWhite: Qt.rgba(1, 1, 1, 0.12)

    // Companies to watch for IPO / market-listing news
    readonly property var ipoWatchList: ["Anthropic", "SpaceX", "OpenAI", "Stripe", "Klarna", "Starlink"]

    function checkIpoAlert(title, description) {
        var text = (title + " " + description).toLowerCase();
        var ipoKeywords = ["ipo", "börsengang", "going public", "geht an die börse", "initial public offering", "listing", "börsennotierung", "börsenstart"];
        var hasIpoKeyword = false;
        for (var k = 0; k < ipoKeywords.length; k++) {
            if (text.indexOf(ipoKeywords[k]) >= 0) {
                hasIpoKeyword = true;
                break;
            }
        }
        if (!hasIpoKeyword)
            return;
        for (var c = 0; c < root.ipoWatchList.length; c++) {
            var company = root.ipoWatchList[c];
            if (text.indexOf(company.toLowerCase()) >= 0) {
                var cmd = 'notify-send -u critical -a "Tagesschau Widget" "📈 IPO Watch: ' + company + '" "' + title.replace(/"/g, '\\"') + '"';
                notificationSource.connectSource(cmd);
                return;
            }
        }
    }

    P5Support.DataSource {
        id: notificationSource
        engine: "executable"
        connectedSources: []
        onNewData: function (src, data) {
            disconnectSource(src);
        }
    }

    function sendDesktopNotification(title) {
        if (!title)
            return;
        var cleanTitle = title.replace(/"/g, '\\"');
        var cmd = 'notify-send -u critical -a "Tagesschau" "🚨 TAGESCHAU EILMELDUNG" "' + cleanTitle + '"';
        notificationSource.connectSource(cmd);
    }

    function getActiveFeed() {
        if (root.feedList && root.feedList.length > 0) {
            var idx = root.currentFeedIndex;
            if (idx >= 0 && idx < root.feedList.length) {
                return root.feedList[idx];
            }
        }
        return {
            "name": "Tagesschau",
            "type": "json-tagesschau",
            "url": "https://www.tagesschau.de/api2u/homepage"
        };
    }

    function getActiveFeedIcon() {
        var feed = getActiveFeed();
        if (feed.icon && feed.icon.trim() !== "") {
            return feed.icon;
        }
        if (feed.type === "json-tagesschau") {
            return Qt.resolvedUrl("../icons/tagesschau-monochrome.svg");
        } else if (feed.type === "finance") {
            return "view-financial-list";
        } else {
            return "feed-subscribe";
        }
    }

    function fetchNews() {
        if (root.isLoading)
            return;
        var feed = getActiveFeed();
        root.isLoading = true;
        root.errorMsg = "";

        if (feed.type === "finance") {
            fetchFinanceData();
            return;
        }

        var xhr = new XMLHttpRequest();
        xhr.open("GET", feed.url + (feed.url.indexOf('?') >= 0 ? '&' : '?') + "_nocache=" + Date.now());
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.isLoading = false;
            if (xhr.status === 200) {
                try {
                    if (feed.type === "json-tagesschau") {
                        parseTagesschauJson(xhr.responseText);
                    } else {
                        parseRssXml(xhr.responseText);
                    }
                } catch (e) {
                    root.errorMsg = i18n("Parse error");
                    console.log("Feed API parse error: " + e);
                }
            } else {
                root.errorMsg = i18n("Error: ") + xhr.status;
            }
        };
        xhr.send();
    }

    function fetchFinanceData() {
        var feed = getActiveFeed();
        var symbolString = feed.symbols || "^GDAXI,^DJI,^IXIC,EURUSD=X,BTC-USD,ETH-USD";
        var symbols = symbolString.split(",");

        var assets = [];
        for (var i = 0; i < symbols.length; i++) {
            var sym = symbols[i].trim();
            if (sym === "")
                continue;
            var name = sym;
            if (sym === "^GDAXI")
                name = "DAX Index";
            else if (sym === "^DJI")
                name = "Dow Jones";
            else if (sym === "^IXIC")
                name = "NASDAQ";
            else if (sym === "EURUSD=X")
                name = "EUR / USD";
            else if (sym === "BTC-USD")
                name = "Bitcoin";
            else if (sym === "ETH-USD")
                name = "Ethereum";
            else if (sym === "SOL-USD")
                name = "Solana";
            else if (sym === "AIR.PA")
                name = "Airbus";
            else if (sym === "RHM.DE")
                name = "Rheinmetall";
            else if (sym === "TSM")
                name = "TSMC";
            else if (sym === "NVDA")
                name = "NVIDIA";
            else if (sym === "ASML")
                name = "ASML";
            else if (sym === "AMD")
                name = "AMD";
            else if (sym === "INTC")
                name = "Intel";
            else if (sym === "LMT")
                name = "Lockheed Martin";
            else if (sym === "BA")
                name = "Boeing";
            else if (sym === "RTX")
                name = "RTX Corp.";

            assets.push({
                "name": name,
                "symbol": sym,
                "price": 0.0,
                "change": 0.0,
                "currency": sym.indexOf("-USD") >= 0 ? "USD" : ""
            });
        }

        if (assets.length === 0) {
            root.isLoading = false;
            financeModel.clear();
            return;
        }

        var completedCount = 0;

        function finishAsset() {
            completedCount++;
            if (completedCount === assets.length) {
                root.isLoading = false;
                financeModel.clear();
                for (var k = 0; k < assets.length; k++) {
                    financeModel.append(assets[k]);
                }
                var u1 = root.feedLastUpdates;
                u1[root.currentFeedIndex] = Qt.formatTime(new Date(), "hh:mm");
                root.feedLastUpdates = u1;
            }
        }

        function fetchAsset(index) {
            var asset = assets[index];

            if (asset.symbol.indexOf("-USD") >= 0) {
                var binanceSymbol = asset.symbol.replace("-USD", "USDT");
                var xhrBinance = new XMLHttpRequest();
                xhrBinance.open("GET", "https://api.binance.com/api/v3/ticker/24hr?symbol=" + binanceSymbol);
                xhrBinance.onreadystatechange = function () {
                    if (xhrBinance.readyState !== XMLHttpRequest.DONE)
                        return;
                    if (xhrBinance.status === 200) {
                        try {
                            var res = JSON.parse(xhrBinance.responseText);
                            asset.price = parseFloat(res.lastPrice);
                            asset.change = parseFloat(res.priceChangePercent);
                            finishAsset();
                            return;
                        } catch (e) {
                            console.log("Binance parse failed for " + asset.symbol + ": " + e);
                        }
                    }
                    fetchYahooAsset(index);
                };
                xhrBinance.send();
            } else {
                fetchYahooAsset(index);
            }
        }

        function fetchYahooAsset(index) {
            var asset = assets[index];
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "https://query1.finance.yahoo.com/v8/finance/chart/" + asset.symbol + "?interval=1d&range=1d&_nocache=" + Date.now());

            try {
                xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
            } catch (e) {
                console.log("Could not set Yahoo Finance User-Agent header: " + e);
            }

            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE)
                    return;
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var meta = response.chart.result[0].meta;
                        var currentPrice = meta.regularMarketPrice;
                        var prevClose = meta.chartPreviousClose;

                        if (currentPrice && prevClose) {
                            asset.price = currentPrice;
                            asset.change = ((currentPrice - prevClose) / prevClose) * 100;
                        } else if (currentPrice) {
                            asset.price = currentPrice;
                            asset.change = 0.0;
                        }
                    } catch (e) {
                        console.log("Yahoo parse failed for " + asset.symbol + ": " + e);
                    }
                } else {
                    console.log("Yahoo fetch error " + xhr.status + " for " + asset.symbol);
                }
                finishAsset();
            };
            xhr.send();
        }

        for (var j = 0; j < assets.length; j++) {
            fetchAsset(j);
        }
    }

    function parseTagesschauJson(responseText) {
        var d = JSON.parse(responseText);
        var rawNews = d.news || [];
        var processed = [];
        var foundEilmeldung = false;
        var topEilmeldungTitle = "";

        for (var i = 0; i < rawNews.length; i++) {
            var item = rawNews[i];
            if (item.type !== "story" && item.type !== "video")
                continue;

            var title = item.title || "";
            var topline = item.topline || "";
            var firstSentence = item.firstSentence || "";
            var dateStr = item.date || "";
            var shareURL = item.detailsweb || item.shareURL || "";
            var ressort = item.ressort || "";
            var isBreaking = !!item.breakingNews;

            var imageUrl = "";
            if (item.teaserImage && item.teaserImage.imageVariants) {
                var variants = item.teaserImage.imageVariants;
                imageUrl = variants["16x9-640"] || variants["16x9-512"] || variants["16x9-384"] || variants["1x1-256"] || "";
            }

            processed.push({
                "id": item.sophoraId || item.externalId || ("story_" + i),
                "title": title,
                "topline": topline,
                "firstSentence": firstSentence,
                "date": dateStr,
                "url": shareURL,
                "ressort": ressort,
                "imageUrl": imageUrl,
                "isBreaking": isBreaking,
                "expanded": false
            });

            if (isBreaking) {
                foundEilmeldung = true;
                if (!topEilmeldungTitle) {
                    topEilmeldungTitle = title;
                }
            }

            root.checkIpoAlert(title, firstSentence);
        }

        if (foundEilmeldung && topEilmeldungTitle !== root.latestEilmeldungTitle) {
            root.sendDesktopNotification(topEilmeldungTitle);
        }

        root.hasEilmeldung = foundEilmeldung;
        root.latestEilmeldungTitle = topEilmeldungTitle;
        root.newsStories = processed;
        var u2 = root.feedLastUpdates;
        u2[root.currentFeedIndex] = Qt.formatTime(new Date(), "hh:mm");
        root.feedLastUpdates = u2;
        root.updateFilteredStories();
    }

    function parseRssXml(responseText) {
        var processed = [];
        var foundEilmeldung = false;
        var topEilmeldungTitle = "";

        var xml = responseText.replace(/<[a-zA-Z0-9]+:/g, "<").replace(/<\/[a-zA-Z0-9]+:/g, "</");

        var itemRegex = /<item>([\s\S]*?)<\/item>/g;
        var match;
        var i = 0;

        while ((match = itemRegex.exec(xml)) !== null && i < 25) {
            var itemContent = match[1];

            var title = getXmlTagContent(itemContent, "title");
            var link = getXmlTagContent(itemContent, "link");
            var description = getXmlTagContent(itemContent, "description");
            var pubDate = getXmlTagContent(itemContent, "pubDate");

            title = title.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1").trim();
            description = description.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1").trim();

            var imageUrl = "";
            var encMatch = itemContent.match(/<enclosure[^>]+url=["']([^"']+)["']/);
            if (encMatch) {
                imageUrl = encMatch[1];
            } else {
                var contentMatch = itemContent.match(/<content[^>]+url=["']([^"']+)["']/);
                if (contentMatch) {
                    imageUrl = contentMatch[1];
                } else {
                    var thumbMatch = itemContent.match(/<thumbnail[^>]+url=["']([^"']+)["']/);
                    if (thumbMatch) {
                        imageUrl = thumbMatch[1];
                    } else {
                        var imgDesc = description.match(/<img[^>]+src=["']([^"']+)["']/);
                        if (imgDesc) {
                            imageUrl = imgDesc[1];
                        }
                    }
                }
            }

            description = description.replace(/<[^>]*>/g, "").trim();

            var isBreaking = /eilmeldung|breaking/i.test(title) || /eilmeldung/i.test(description);

            processed.push({
                "id": "rss_" + i + "_" + Date.now(),
                "title": title,
                "topline": "",
                "firstSentence": description,
                "date": pubDate,
                "url": link,
                "ressort": "",
                "imageUrl": imageUrl,
                "isBreaking": isBreaking,
                "expanded": false
            });

            if (isBreaking) {
                foundEilmeldung = true;
                if (!topEilmeldungTitle) {
                    topEilmeldungTitle = title;
                }
            }

            root.checkIpoAlert(title, description);
            i++;
        }

        if (foundEilmeldung && topEilmeldungTitle !== root.latestEilmeldungTitle) {
            root.sendDesktopNotification(topEilmeldungTitle);
        }

        root.hasEilmeldung = foundEilmeldung;
        root.latestEilmeldungTitle = topEilmeldungTitle;
        root.newsStories = processed;
        var u3 = root.feedLastUpdates;
        u3[root.currentFeedIndex] = Qt.formatTime(new Date(), "hh:mm");
        root.feedLastUpdates = u3;
        root.updateFilteredStories();
    }

    function getXmlTagContent(xml, tag) {
        var regex = new RegExp("<" + tag + "[^>]*>([\\s\\S]*?)<\/" + tag + ">");
        var m = xml.match(regex);
        return m ? m[1].trim() : "";
    }

    function updateFilteredStories() {
        newsModel.clear();
        var feed = getActiveFeed();
        for (var i = 0; i < root.newsStories.length; i++) {
            var item = root.newsStories[i];
            if (feed.type === "rss" || root.activeRessort === "alle" || item.ressort === root.activeRessort) {
                newsModel.append(item);
            }
        }
    }

    function formatTimeAgo(dateStr) {
        if (!dateStr)
            return "";
        var pubDate = new Date(dateStr);
        if (isNaN(pubDate))
            return "";
        var now = new Date();
        var diffMs = now.getTime() - pubDate.getTime();
        if (diffMs < 0)
            diffMs = 0;
        var diffMins = Math.floor(diffMs / 60000);
        if (diffMins < 1)
            return i18n("Just now");
        if (diffMins < 60)
            return i18np("%1 min ago", "%1 min ago", diffMins);
        var diffHours = Math.floor(diffMins / 60);
        if (diffHours < 24)
            return i18np("%1 hr ago", "%1 hrs ago", diffHours);
        var diffDays = Math.floor(diffHours / 24);
        return i18np("%1 day ago", "%1 days ago", diffDays);
    }

    function cleanHtml(text) {
        if (!text)
            return "";
        return text.replace(/&shy;/g, "").replace(/&quot;/g, '"').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&#039;/g, "'").replace(/&ndash;/g, "–").replace(/&nbsp;/g, " ");
    }

    function formatPrice(val, symbol) {
        if (!val || isNaN(val) || val === 0.0)
            return "---";

        if (symbol === "EURUSD=X") {
            return val.toFixed(4).replace(".", ",");
        }

        var prefix = "";
        var suffix = "";

        var eurSymbols = ["^GDAXI", "AIR.PA", "RHM.DE", "ASML"];
        var usdSymbols = ["TSM", "NVDA", "AMD", "INTC", "LMT", "BA", "RTX", "AAPL", "TSLA", "MSFT"];
        if (eurSymbols.indexOf(symbol) >= 0)
            suffix = " €";
        else if (symbol.indexOf("-USD") >= 0 || symbol.indexOf("^") >= 0 || usdSymbols.indexOf(symbol) >= 0) {
            prefix = "$ ";
        }

        var parts = val.toFixed(2).split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".");
        return prefix + parts.join(",") + suffix;
    }

    ListModel {
        id: newsModel
    }
    ListModel {
        id: financeModel
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchNews()
    }

    Connections {
        target: plasmoid.configuration
        function onFeedsJsonChanged() {
            root.fetchNews();
        }
        function onCurrentFeedIndexChanged() {
            root.fetchNews();
        }
    }

    preferredRepresentation: Plasmoid.location === 0 ? fullRepresentation : compactRepresentation

    // ── Compact Layout ───────────────────────────────────────────────────
    compactRepresentation: Item {
        id: compactRoot
        implicitWidth: compactRow.implicitWidth + 12
        implicitHeight: Kirigami.Units.iconSizes.medium

        Layout.preferredWidth: implicitWidth
        Layout.minimumWidth: implicitWidth
        Layout.maximumWidth: implicitWidth

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: compactMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: 6

            Item {
                width: 20
                height: 20

                Rectangle {
                    visible: root.hasEilmeldung
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    radius: 11
                    color: root.breakingRed
                    opacity: 0.2

                    SequentialAnimation on scale {
                        running: root.hasEilmeldung
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0.8
                            to: 1.35
                            duration: 1000
                            easing.type: Easing.OutSine
                        }
                        NumberAnimation {
                            from: 1.35
                            to: 0.8
                            duration: 1000
                            easing.type: Easing.InSine
                        }
                    }
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: root.getActiveFeedIcon()
                    isMask: {
                        var srcStr = root.getActiveFeedIcon().toString();
                        if (srcStr.indexOf("tagesschau-monochrome.svg") >= 0)
                            return true;
                        return srcStr.indexOf("file://") !== 0;
                    }
                    color: isMask ? (root.hasEilmeldung ? root.breakingRed : Kirigami.Theme.textColor) : "transparent"

                    SequentialAnimation on color {
                        running: root.hasEilmeldung
                        loops: Animation.Infinite
                        ColorAnimation {
                            to: "#ff8888"
                            duration: 1000
                        }
                        ColorAnimation {
                            to: root.breakingRed
                            duration: 1000
                        }
                    }
                }
            }

            Rectangle {
                visible: root.hasEilmeldung
                width: 6
                height: 6
                radius: 3
                color: root.breakingRed
                Layout.alignment: Qt.AlignVCenter

                SequentialAnimation on opacity {
                    running: root.hasEilmeldung
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.2
                        duration: 750
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 750
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // ── Full Layout ──────────────────────────────────────────────────────
    fullRepresentation: FullRepresentation {
        plasmoidRoot: root
        newsListModel: newsModel
        financeListModel: financeModel
    }
}
