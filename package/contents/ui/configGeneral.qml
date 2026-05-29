import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_feedsJson: ""
    property int cfg_currentFeedIndex: 0
    property var cfg_feedsJsonDefault
    property var cfg_currentFeedIndexDefault

    ListModel {
        id: feedModel
    }

    property bool _syncing: false
    property int editingIndex: -1

    function loadFeeds() {
        _syncing = true;
        feedModel.clear();
        try {
            var feeds = JSON.parse(cfg_feedsJson);
            for (var i = 0; i < feeds.length; i++) {
                feedModel.append({
                    name: feeds[i].name || "",
                    type: feeds[i].type || "rss",
                    url: feeds[i].url || "",
                    symbols: feeds[i].symbols || "",
                    icon: feeds[i].icon || ""
                });
            }
        } catch (e) {}
        _syncing = false;
    }

    function saveFeeds() {
        if (_syncing)
            return;
        var arr = [];
        for (var i = 0; i < feedModel.count; i++) {
            var f = feedModel.get(i);
            var entry = {
                name: f.name,
                type: f.type,
                url: f.url,
                icon: f.icon || ""
            };
            if (f.type === "finance")
                entry.symbols = f.symbols;
            arr.push(entry);
        }
        cfg_feedsJson = JSON.stringify(arr);
        if (cfg_currentFeedIndex >= feedModel.count)
            cfg_currentFeedIndex = Math.max(0, feedModel.count - 1);
    }

    function typeIndex(typeStr) {
        if (typeStr === "json-tagesschau")
            return 1;
        if (typeStr === "finance")
            return 2;
        return 0;
    }

    function typeString(idx) {
        return ["rss", "json-tagesschau", "finance"][idx] || "rss";
    }

    Component.onCompleted: loadFeeds()

    Kirigami.FormLayout {
        Layout.fillWidth: true

        // ── Feed List ────────────────────────────────────────────────────
        ColumnLayout {
            Kirigami.FormData.label: i18n("Feeds & Tickers:")
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: feedModel

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // ── View row ─────────────────────────────────────────
                    RowLayout {
                        visible: root.editingIndex !== index
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            radius: 4
                            color: {
                                if (model.type === "finance")
                                    return "#1a4a1a";
                                if (model.type === "json-tagesschau")
                                    return "#00305e";
                                return "#3a2a00";
                            }
                            border.color: {
                                if (model.type === "finance")
                                    return "#44aa44";
                                if (model.type === "json-tagesschau")
                                    return "#005ca9";
                                return "#cc9900";
                            }
                            border.width: 1
                            implicitWidth: typeTag.implicitWidth + 10
                            implicitHeight: typeTag.implicitHeight + 6

                            QQC.Label {
                                id: typeTag
                                anchors.centerIn: parent
                                text: {
                                    if (model.type === "finance")
                                        return i18n("Finance");
                                    if (model.type === "json-tagesschau")
                                        return i18n("Tagesschau");
                                    return i18n("RSS");
                                }
                                font.pixelSize: 10
                                font.bold: true
                                color: Kirigami.Theme.textColor
                            }
                        }

                        Kirigami.Icon {
                            source: {
                                if (model.icon && model.icon.trim() !== "")
                                    return model.icon;
                                if (model.type === "json-tagesschau")
                                    return Qt.resolvedUrl("../icons/tagesschau-monochrome.svg");
                                if (model.type === "finance")
                                    return "view-financial-list";
                                return "feed-subscribe";
                            }
                            implicitWidth: 16
                            implicitHeight: 16
                            color: Kirigami.Theme.textColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        QQC.Label {
                            text: model.name
                            font.bold: true
                            Layout.minimumWidth: 90
                            elide: Text.ElideRight
                            color: Kirigami.Theme.textColor
                        }

                        QQC.Label {
                            text: model.type === "finance" ? model.symbols : model.url
                            opacity: 0.55
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: Kirigami.Theme.textColor
                        }

                        QQC.ToolButton {
                            icon.name: "document-edit"
                            onClicked: root.editingIndex = index
                        }

                        QQC.ToolButton {
                            icon.name: "edit-delete-remove"
                            enabled: feedModel.count > 1
                            onClicked: {
                                if (root.editingIndex === index)
                                    root.editingIndex = -1;
                                feedModel.remove(index);
                                saveFeeds();
                            }
                        }
                    }

                    // ── Edit row ─────────────────────────────────────────
                    ColumnLayout {
                        id: editRow
                        visible: root.editingIndex === index
                        Layout.fillWidth: true
                        spacing: 8

                        onVisibleChanged: {
                            if (visible) {
                                editTypeBar.currentIndex = root.typeIndex(model.type);
                                editName.text = model.name;
                                editUrl.text = model.type === "finance" ? model.symbols : model.url;
                                editIcon.text = model.icon || "";
                            }
                        }

                        QQC.TextField {
                            id: editName
                            placeholderText: i18n("Name")
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            QQC.TextField {
                                id: editIcon
                                placeholderText: i18n("Icon name or file URL (optional)")
                                Layout.fillWidth: true
                                selectByMouse: true
                            }
                            QQC.Button {
                                icon.name: "document-open"
                                text: i18n("Browse...")
                                onClicked: {
                                    iconFileDialog.targetTextField = editIcon;
                                    iconFileDialog.open();
                                }
                            }
                        }

                        QQC.TabBar {
                            id: editTypeBar
                            Layout.fillWidth: true
                            QQC.TabButton {
                                text: i18n("RSS  (BBC, NTV, ...)")
                            }
                            QQC.TabButton {
                                text: i18n("Tagesschau JSON")
                            }
                            QQC.TabButton {
                                text: i18n("Finance ticker")
                            }
                        }

                        QQC.TextField {
                            id: editUrl
                            placeholderText: editTypeBar.currentIndex === 2 ? "^GDAXI, BTC-USD, TSLA, EURUSD=X" : "https://example.com/feed.rss"
                            Layout.fillWidth: true
                            selectByMouse: true
                        }

                        QQC.Label {
                            visible: editTypeBar.currentIndex === 0
                            text: i18n("Any news site with an RSS feed works — BBC, NTV, Reuters, Spiegel, ...")
                            font.pixelSize: 10
                            opacity: 0.6
                            color: Kirigami.Theme.textColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 8

                            QQC.Button {
                                text: i18n("Save")
                                icon.name: "dialog-ok-apply"
                                enabled: editName.text.trim() !== "" && editUrl.text.trim() !== ""
                                onClicked: {
                                    var typeStr = root.typeString(editTypeBar.currentIndex);
                                    feedModel.set(index, {
                                        name: editName.text.trim(),
                                        type: typeStr,
                                        url: typeStr === "finance" ? "finance-board" : editUrl.text.trim(),
                                        symbols: typeStr === "finance" ? editUrl.text.trim() : "",
                                        icon: editIcon.text.trim()
                                    });
                                    saveFeeds();
                                    root.editingIndex = -1;
                                }
                            }

                            QQC.Button {
                                text: i18n("Cancel")
                                icon.name: "dialog-cancel"
                                onClicked: root.editingIndex = -1
                            }
                        }

                        Kirigami.Separator {
                            Layout.fillWidth: true
                            opacity: 0.4
                        }
                    }
                }
            }
        }

        // ── Add new feed ─────────────────────────────────────────────────
        Kirigami.Separator {
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Add feed")
        }

        QQC.TextField {
            id: newName
            Kirigami.FormData.label: i18n("Name:")
            placeholderText: i18n("e.g. BBC News, NTV, Reuters...")
            Layout.fillWidth: true
            selectByMouse: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Icon (optional):")
            Layout.fillWidth: true
            spacing: 8
            QQC.TextField {
                id: newIcon
                placeholderText: i18n("Icon name or file URL")
                Layout.fillWidth: true
                selectByMouse: true
            }
            QQC.Button {
                icon.name: "document-open"
                text: i18n("Browse...")
                onClicked: {
                    iconFileDialog.targetTextField = newIcon;
                    iconFileDialog.open();
                }
            }
        }

        QQC.TabBar {
            id: newTypeBar
            Kirigami.FormData.label: i18n("Type:")
            Layout.fillWidth: true
            QQC.TabButton {
                text: "RSS  (BBC, NTV, ...)"
            }
            QQC.TabButton {
                text: "Tagesschau JSON"
            }
            QQC.TabButton {
                text: "Finanz-Ticker"
            }
        }

        QQC.Label {
            visible: newTypeBar.currentIndex === 0
            text: "Any news site with an RSS feed works — BBC, NTV, Spiegel, Reuters, ..."
            font.pixelSize: 10
            opacity: 0.6
            color: Kirigami.Theme.textColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        QQC.TextField {
            id: newUrl
            Kirigami.FormData.label: newTypeBar.currentIndex === 2 ? i18n("Symbols:") : i18n("URL:")
            placeholderText: newTypeBar.currentIndex === 2 ? "^GDAXI, BTC-USD, TSLA, EURUSD=X" : "https://feeds.bbci.co.uk/news/rss.xml"
            Layout.fillWidth: true
            selectByMouse: true
        }

        QQC.Button {
            text: i18n("Add")
            icon.name: "list-add"
            enabled: newName.text.trim() !== "" && newUrl.text.trim() !== ""
            onClicked: {
                var typeStr = root.typeString(newTypeBar.currentIndex);
                feedModel.append({
                    name: newName.text.trim(),
                    type: typeStr,
                    url: typeStr === "finance" ? "finance-board" : newUrl.text.trim(),
                    symbols: typeStr === "finance" ? newUrl.text.trim() : "",
                    icon: newIcon.text.trim()
                });
                saveFeeds();
                newName.text = "";
                newUrl.text = "";
                newIcon.text = "";
                newTypeBar.currentIndex = 0;
            }
        }

        // ── Reset ────────────────────────────────────────────────────────
        Kirigami.Separator {
            Layout.fillWidth: true
        }

        QQC.Button {
            text: i18n("Reset to defaults")
            icon.name: "edit-reset"
            onClicked: {
                cfg_feedsJson = '[{"name":"Tagesschau","type":"json-tagesschau","url":"https://www.tagesschau.de/api2u/homepage","icon":""},{"name":"Märkte","type":"finance","url":"finance-board","symbols":"^GDAXI,^DJI,^IXIC,EURUSD=X,BTC-USD,ETH-USD,AIR.PA,RHM.DE,TSM,NVDA,ASML,AMD","icon":"view-financial-list"}]';
                cfg_currentFeedIndex = 0;
                loadFeeds();
            }
        }
    }

    FileDialog {
        id: iconFileDialog
        title: i18n("Select Icon File")
        nameFilters: ["Image Files (*.png *.jpg *.jpeg *.svg *.svgz)", "All Files (*)"]

        property var targetTextField: null

        onAccepted: {
            if (targetTextField) {
                targetTextField.text = selectedFile.toString();
            }
        }
    }
}
