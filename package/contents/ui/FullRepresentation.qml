import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: fullRep

    property Item plasmoidRoot
    property ListModel newsListModel
    property ListModel financeListModel

    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 26
    Layout.preferredWidth: Kirigami.Units.gridUnit * 25
    Layout.preferredHeight: Kirigami.Units.gridUnit * 30

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: fullRep.plasmoidRoot.glassyBg
        border.color: fullRep.plasmoidRoot.borderWhite
        border.width: 1

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 1
            height: 1
            radius: 0.5
            color: Qt.rgba(1, 1, 1, 0.18)
        }
    }

    AddFeedDialog {
        id: addFeedDialog
        anchors.fill: parent
        plasmoidRoot: fullRep.plasmoidRoot
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Header ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: fullRep.plasmoidRoot.hasEilmeldung ? fullRep.plasmoidRoot.breakingRed : fullRep.plasmoidRoot.tagesschauBlue
                border.color: fullRep.plasmoidRoot.hasEilmeldung ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.1)
                border.width: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 300
                    }
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: fullRep.plasmoidRoot.getActiveFeedIcon()
                    isMask: {
                        var srcStr = source.toString();
                        if (srcStr.indexOf("tagesschau-monochrome.svg") >= 0)
                            return true;
                        return srcStr.indexOf("file://") !== 0;
                    }
                    color: isMask ? "#ffffff" : "transparent"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                PlasmaComponents.Label {
                    text: fullRep.plasmoidRoot.getActiveFeed().name.toLowerCase()
                    font.bold: true
                    font.pixelSize: 15
                    color: "#ffffff"
                }
                PlasmaComponents.Label {
                    text: {
                        var feed = fullRep.plasmoidRoot.getActiveFeed();
                        if (feed.type === "finance")
                            return i18n("Live market data");
                        return fullRep.plasmoidRoot.hasEilmeldung ? i18n("BREAKING NEWS") : i18n("News feed");
                    }
                    font.pixelSize: 9
                    font.bold: fullRep.plasmoidRoot.hasEilmeldung
                    color: fullRep.plasmoidRoot.hasEilmeldung ? fullRep.plasmoidRoot.breakingRed : Kirigami.Theme.highlightColor
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                display: PlasmaComponents.AbstractButton.IconOnly
                onClicked: fullRep.plasmoidRoot.fetchNews()
                opacity: fullRep.plasmoidRoot.isLoading ? 0.3 : (hovered ? 1.0 : 0.6)

                QQC2.BusyIndicator {
                    anchors.fill: parent
                    visible: fullRep.plasmoidRoot.isLoading
                    running: fullRep.plasmoidRoot.isLoading
                }
            }
        }

        // ── Tabs Bar ────────────────────────────────────────────────────
        QQC2.ScrollView {
            Layout.fillWidth: true
            height: 32
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: fullRep.plasmoidRoot.feedList

                    Rectangle {
                        width: tabLabelLayout.implicitWidth + 16
                        height: fullRep.plasmoidRoot.feedLastUpdates[index] ? 36 : 24
                        radius: 6
                        color: fullRep.plasmoidRoot.currentFeedIndex === index ? fullRep.plasmoidRoot.tagesschauBlue : Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: fullRep.plasmoidRoot.currentFeedIndex === index ? fullRep.plasmoidRoot.tagesschauLightBlue : Qt.rgba(1, 1, 1, 0.08)

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            RowLayout {
                                id: tabLabelLayout
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6

                                Kirigami.Icon {
                                    source: {
                                        if (modelData.icon && modelData.icon.trim() !== "")
                                            return modelData.icon;
                                        if (modelData.type === "json-tagesschau")
                                            return Qt.resolvedUrl("../icons/tagesschau-monochrome.svg");
                                        if (modelData.type === "finance")
                                            return "view-financial-list";
                                        return "feed-subscribe";
                                    }
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    isMask: {
                                        var srcStr = source.toString();
                                        if (srcStr.indexOf("tagesschau-monochrome.svg") >= 0)
                                            return true;
                                        return srcStr.indexOf("file://") !== 0;
                                    }
                                    color: isMask ? "#ffffff" : "transparent"
                                }

                                PlasmaComponents.Label {
                                    text: modelData.name
                                    font.pixelSize: 10
                                    font.bold: fullRep.plasmoidRoot.currentFeedIndex === index
                                    color: "#ffffff"
                                }

                                PlasmaComponents.ToolButton {
                                    visible: index > 1
                                    icon.name: "window-close"
                                    implicitWidth: 12
                                    implicitHeight: 12
                                    display: PlasmaComponents.AbstractButton.IconOnly
                                    onClicked: {
                                        var currentList = [];
                                        try {
                                            currentList = JSON.parse(plasmoid.configuration.feedsJson);
                                        } catch (e) {
                                            currentList = fullRep.plasmoidRoot.feedList;
                                        }
                                        currentList.splice(index, 1);

                                        var nextIndex = fullRep.plasmoidRoot.currentFeedIndex;
                                        if (nextIndex >= currentList.length) {
                                            nextIndex = currentList.length - 1;
                                        }
                                        if (nextIndex < 0)
                                            nextIndex = 0;

                                        plasmoid.configuration.feedsJson = JSON.stringify(currentList);
                                        plasmoid.configuration.currentFeedIndex = nextIndex;
                                    }
                                }
                            }

                            PlasmaComponents.Label {
                                visible: !!fullRep.plasmoidRoot.feedLastUpdates[index]
                                text: fullRep.plasmoidRoot.feedLastUpdates[index] || ""
                                font.pixelSize: 8
                                opacity: 0.5
                                color: "#ffffff"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                plasmoid.configuration.currentFeedIndex = index;
                            }
                        }
                    }
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "list-add"
                        width: 12
                        height: 12
                        color: "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addFeedDialog.visible = true
                    }
                }
            }
        }

        // ── Filter Ressort Bar (only for Tagesschau API) ────────────────
        QQC2.ScrollView {
            visible: fullRep.plasmoidRoot.getActiveFeed().type === "json-tagesschau"
            Layout.fillWidth: true
            height: visible ? 28 : 0
            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AlwaysOff

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: [
                        {
                            name: i18n("All"),
                            id: "alle"
                        },
                        {
                            name: i18n("Domestic"),
                            id: "inland"
                        },
                        {
                            name: i18n("International"),
                            id: "ausland"
                        },
                        {
                            name: i18n("Business"),
                            id: "wirtschaft"
                        },
                        {
                            name: i18n("Sports"),
                            id: "sport"
                        },
                        {
                            name: i18n("Science"),
                            id: "wissen"
                        },
                        {
                            name: i18n("Investigative"),
                            id: "investigativ"
                        }
                    ]

                    Rectangle {
                        width: filterLabel.implicitWidth + 16
                        height: 22
                        radius: 11
                        color: fullRep.plasmoidRoot.activeRessort === modelData.id ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: fullRep.plasmoidRoot.activeRessort === modelData.id ? "transparent" : Qt.rgba(1, 1, 1, 0.1)

                        PlasmaComponents.Label {
                            id: filterLabel
                            anchors.centerIn: parent
                            text: modelData.name
                            font.pixelSize: 10
                            font.bold: fullRep.plasmoidRoot.activeRessort === modelData.id
                            color: fullRep.plasmoidRoot.activeRessort === modelData.id ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                fullRep.plasmoidRoot.activeRessort = modelData.id;
                                fullRep.plasmoidRoot.updateFilteredStories();
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // ── Content: News List OR Finance Grid ──────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            PlasmaComponents.Label {
                visible: fullRep.plasmoidRoot.errorMsg !== "" && fullRep.newsListModel.count === 0 && fullRep.plasmoidRoot.getActiveFeed().type !== "finance"
                text: fullRep.plasmoidRoot.errorMsg
                font.bold: true
                color: fullRep.plasmoidRoot.breakingRed
                anchors.centerIn: parent
                wrapMode: Text.WordWrap
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                visible: {
                    var feed = fullRep.plasmoidRoot.getActiveFeed();
                    if (feed.type === "finance") {
                        return fullRep.financeListModel.count === 0 && fullRep.plasmoidRoot.errorMsg === "";
                    } else {
                        return fullRep.newsListModel.count === 0 && fullRep.plasmoidRoot.errorMsg === "";
                    }
                }
                anchors.centerIn: parent
                spacing: 8

                QQC2.BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: fullRep.plasmoidRoot.isLoading
                }
                PlasmaComponents.Label {
                    text: fullRep.plasmoidRoot.isLoading ? i18n("Loading...") : i18n("No entries found.")
                    font.pixelSize: 11
                    opacity: 0.5
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ListView {
                id: listView
                visible: fullRep.plasmoidRoot.getActiveFeed().type !== "finance"
                anchors.fill: parent
                model: fullRep.newsListModel
                spacing: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: NewsCard {
                    plasmoidRoot: fullRep.plasmoidRoot
                    newsListModel: fullRep.newsListModel
                }
            }

            GridView {
                id: financeGrid
                visible: fullRep.plasmoidRoot.getActiveFeed().type === "finance"
                anchors.fill: parent
                model: fullRep.financeListModel
                cellWidth: width / 2
                cellHeight: 68
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: FinanceCard {
                    plasmoidRoot: fullRep.plasmoidRoot
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // ── Footer ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Label {
                text: fullRep.plasmoidRoot.feedLastUpdates[fullRep.plasmoidRoot.currentFeedIndex] ? i18n("Updated: ") + fullRep.plasmoidRoot.feedLastUpdates[fullRep.plasmoidRoot.currentFeedIndex] : ""
                font.pixelSize: 9
                opacity: 0.4
                color: Kirigami.Theme.textColor
            }

            Item {
                Layout.fillWidth: true
            }

            PlasmaComponents.Label {
                text: {
                    var feed = fullRep.plasmoidRoot.getActiveFeed();
                    if (feed.type === "finance")
                        return i18n("Live market data");
                    return feed.name;
                }
                font.pixelSize: 9
                opacity: 0.4
                font.bold: true
                color: Kirigami.Theme.textColor
            }
        }
    }
}
