import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.plasma.components as PlasmaComponents

Rectangle {
    id: dialogRoot

    property Item plasmoidRoot

    color: Qt.rgba(0, 0, 0, 0.8)
    visible: false
    radius: 12
    z: 99

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width - 32
        implicitHeight: formLayout.implicitHeight + 32
        radius: 8
        color: Qt.rgba(0.12, 0.12, 0.15, 0.95)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        ColumnLayout {
            id: formLayout
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 12

            PlasmaComponents.Label {
                text: i18n("Add new feed or ticker")
                font.bold: true
                font.pixelSize: 13
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    text: i18n("Name:")
                    font.pixelSize: 10
                    opacity: 0.7
                }
                QQC2.TextField {
                    id: newFeedName
                    placeholderText: i18n("e.g. Crypto & Stocks")
                    Layout.fillWidth: true
                    selectByMouse: true
                }
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    text: i18n("Type:")
                    font.pixelSize: 10
                    opacity: 0.7
                }
                QQC2.ComboBox {
                    id: newFeedType
                    Layout.fillWidth: true
                    model: [i18n("RSS Feed"), i18n("Tagesschau JSON"), i18n("Finance ticker")]
                }
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    text: newFeedType.currentIndex === 2 ? i18n("Symbols (comma-separated):") : i18n("Feed URL:")
                    font.pixelSize: 10
                    opacity: 0.7
                }
                QQC2.TextField {
                    id: newFeedUrl
                    placeholderText: newFeedType.currentIndex === 2 ? "e.g. ^GDAXI, BTC-USD, TSLA, EURUSD=X" : "https://..."
                    Layout.fillWidth: true
                    selectByMouse: true
                }
            }

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                PlasmaComponents.Label {
                    text: i18n("Icon (optional):")
                    font.pixelSize: 10
                    opacity: 0.7
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    QQC2.TextField {
                        id: newFeedIcon
                        placeholderText: "e.g. brand-bbc, chart-line, file:///..."
                        Layout.fillWidth: true
                        selectByMouse: true
                    }
                    QQC2.Button {
                        text: i18n("Browse...")
                        onClicked: iconFileDialog.open()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                QQC2.Button {
                    text: i18n("Cancel")
                    Layout.fillWidth: true
                    onClicked: {
                        newFeedName.text = "";
                        newFeedUrl.text = "";
                        newFeedIcon.text = "";
                        dialogRoot.visible = false;
                    }
                }

                QQC2.Button {
                    text: i18n("Add")
                    Layout.fillWidth: true
                    onClicked: {
                        if (newFeedName.text.trim() === "" || newFeedUrl.text.trim() === "")
                            return;

                        var currentList = [];
                        try {
                            currentList = JSON.parse(plasmoid.configuration.feedsJson);
                        } catch (e) {
                            currentList = dialogRoot.plasmoidRoot.feedList;
                        }

                        var typeStr = "rss";
                        var urlVal = newFeedUrl.text.trim();
                        var symsVal = "";

                        if (newFeedType.currentIndex === 0) {
                            typeStr = "rss";
                        } else if (newFeedType.currentIndex === 1) {
                            typeStr = "json-tagesschau";
                        } else {
                            typeStr = "finance";
                            symsVal = urlVal;
                            urlVal = "finance-board";
                        }

                        currentList.push({
                            "name": newFeedName.text.trim(),
                            "type": typeStr,
                            "url": urlVal,
                            "symbols": symsVal,
                            "icon": newFeedIcon.text.trim()
                        });

                        plasmoid.configuration.feedsJson = JSON.stringify(currentList);
                        plasmoid.configuration.currentFeedIndex = currentList.length - 1;

                        newFeedName.text = "";
                        newFeedUrl.text = "";
                        newFeedIcon.text = "";
                        dialogRoot.visible = false;
                    }
                }
            }
        }
    }

    FileDialog {
        id: iconFileDialog
        title: i18n("Select Icon File")
        nameFilters: ["Image Files (*.png *.jpg *.jpeg *.svg *.svgz)", "All Files (*)"]
        onAccepted: {
            newFeedIcon.text = selectedFile.toString();
        }
    }
}
